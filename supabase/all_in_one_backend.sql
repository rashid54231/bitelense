-- ==============================================================================
-- BITELENS: COMPLETE ALL-IN-ONE SUPABASE BACKEND SCRIPT
-- RUN THIS ENTIRE SCRIPT IN YOUR SUPABASE PROJECT -> SQL EDITOR
-- It creates all tables, constraints, functions, triggers, RLS policies,
-- and the private storage bucket with security rules.
-- ==============================================================================

-- 0. Enable pgcrypto for UUIDs
create extension if not exists "pgcrypto";

-- ==============================================================================
-- 1. PROFILES TABLE
-- ==============================================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  sex text check (sex in ('male', 'female', 'other')),
  birth_year int,
  height_cm numeric,
  weight_kg numeric,
  activity_level text check (activity_level in ('sedentary', 'light', 'moderate', 'active', 'very_active')),
  goal text check (goal in ('lose', 'maintain', 'gain')) default 'maintain',
  daily_calorie_goal int default 2000,
  units text default 'metric',
  onboarding_done boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Enable RLS on profiles
alter table public.profiles enable row level security;

-- Profiles Policies
drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- Trigger to automatically create profile row on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, new.raw_user_meta_data->>'display_name')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ==============================================================================
-- 2. MEALS TABLE
-- ==============================================================================
create table if not exists public.meals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  image_path text,
  meal_type text check (meal_type in ('breakfast', 'lunch', 'dinner', 'snack')),
  items jsonb not null default '[]'::jsonb,
  total_calories numeric,
  total_protein_g numeric,
  total_carbs_g numeric,
  total_fat_g numeric,
  total_fiber_g numeric,
  confidence text check (confidence in ('high', 'medium', 'low')),
  user_edited boolean default false,
  eaten_at timestamptz not null default now(),
  created_at timestamptz default now()
);

-- Index for fast user meal lookups and history sorting
create index if not exists idx_meals_user_eaten
  on public.meals (user_id, eaten_at desc);

-- Enable RLS on meals
alter table public.meals enable row level security;

-- Meals Policies
drop policy if exists "Users can view own meals" on public.meals;
create policy "Users can view own meals"
  on public.meals for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own meals" on public.meals;
create policy "Users can insert own meals"
  on public.meals for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own meals" on public.meals;
create policy "Users can update own meals"
  on public.meals for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own meals" on public.meals;
create policy "Users can delete own meals"
  on public.meals for delete
  using (auth.uid() = user_id);

-- ==============================================================================
-- 3. DAILY USAGE TABLE (Scan Limits)
-- ==============================================================================
create table if not exists public.daily_usage (
  user_id uuid not null references auth.users(id) on delete cascade,
  usage_date date not null,
  scan_count int not null default 0,
  primary key (user_id, usage_date)
);

-- Enable RLS on daily_usage
alter table public.daily_usage enable row level security;

-- Users can only select their own usage. Client cannot update/insert scan_count.
drop policy if exists "Users can view own scan usage" on public.daily_usage;
create policy "Users can view own scan usage"
  on public.daily_usage for select
  using (auth.uid() = user_id);

-- Atomic scan increment function (Executed ONLY by service_role)
create or replace function public.increment_scan_usage(p_user uuid, p_date date)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  new_count int;
begin
  insert into public.daily_usage (user_id, usage_date, scan_count)
  values (p_user, p_date, 1)
  on conflict (user_id, usage_date)
  do update set scan_count = public.daily_usage.scan_count + 1
  returning scan_count into new_count;

  return new_count;
end;
$$;

revoke execute on function public.increment_scan_usage(uuid, date) from public;
grant execute on function public.increment_scan_usage(uuid, date) to service_role;

-- ==============================================================================
-- 4. SUBSCRIPTIONS TABLE
-- ==============================================================================
create table if not exists public.subscriptions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  is_pro boolean default false,
  entitlement text,
  product_id text,
  store text,
  expires_at timestamptz,
  updated_at timestamptz default now()
);

-- Enable RLS on subscriptions
alter table public.subscriptions enable row level security;

-- Users can select own subscription only. Writes only by service_role.
drop policy if exists "Users can view own subscription" on public.subscriptions;
create policy "Users can view own subscription"
  on public.subscriptions for select
  using (auth.uid() = user_id);

-- ==============================================================================
-- 5. STORAGE BUCKET: meal-photos
-- ==============================================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'meal-photos',
  'meal-photos',
  false,
  5242880, -- 5 MB limit
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = false,
  file_size_limit = 5242880,
  allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'];

-- Storage RLS: Users can only upload, read, and delete within their own folder: {user_id}/...
drop policy if exists "Users can insert own meal photos" on storage.objects;
create policy "Users can insert own meal photos"
  on storage.objects for insert
  with check (
    bucket_id = 'meal-photos' and
    auth.role() = 'authenticated' and
    (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users can view own meal photos" on storage.objects;
create policy "Users can view own meal photos"
  on storage.objects for select
  using (
    bucket_id = 'meal-photos' and
    auth.role() = 'authenticated' and
    (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users can delete own meal photos" on storage.objects;
create policy "Users can delete own meal photos"
  on storage.objects for delete
  using (
    bucket_id = 'meal-photos' and
    auth.role() = 'authenticated' and
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- ==============================================================================
-- DONE! All tables, RLS rules, functions, triggers & storage are configured.
-- ==============================================================================
