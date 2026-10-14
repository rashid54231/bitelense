import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.39.8';

export interface AuthContext {
  user: { id: string; email?: string };
  userClient: SupabaseClient;
  adminClient: SupabaseClient;
}

export async function verifyAuth(req: Request): Promise<AuthContext> {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    throw new Error('MISSING_AUTH_HEADER');
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') || '';
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const adminClient = createClient(supabaseUrl, supabaseServiceKey);

  const { data: { user }, error } = await userClient.auth.getUser();
  if (error || !user) {
    throw new Error('INVALID_TOKEN');
  }

  return {
    user: { id: user.id, email: user.email },
    userClient,
    adminClient,
  };
}
