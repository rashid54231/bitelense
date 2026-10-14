import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { handleCors } from '../_shared/cors.ts';
import { jsonResponse, errorResponse } from '../_shared/responses.ts';
import { verifyAuth } from '../_shared/auth.ts';

serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    // 1. Verify User
    let authContext;
    try {
      authContext = await verifyAuth(req);
    } catch {
      return errorResponse('UNAUTHORIZED', 'Missing or invalid token.', 401);
    }
    const { user, adminClient } = authContext;

    // 2. Delete all photos from meal-photos storage bucket in folder {user_id}
    try {
      const { data: files } = await adminClient.storage
        .from('meal-photos')
        .list(user.id);

      if (files && files.length > 0) {
        const filePaths = files.map((f) => `${user.id}/${f.name}`);
        await adminClient.storage.from('meal-photos').remove(filePaths);
      }
    } catch (storageErr) {
      console.warn('Storage cleanup warning:', storageErr);
    }

    // 3. Delete the auth user using Supabase Admin API
    // Foreign key cascade constraints automatically delete profiles, meals, daily_usage, subscriptions
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(user.id);

    if (deleteError) {
      console.error('Error deleting user account:', deleteError);
      return errorResponse('DELETE_FAILED', 'Could not delete user account.', 500);
    }

    return jsonResponse({
      ok: true,
      message: 'Account and associated data deleted successfully.',
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Server error';
    return errorResponse('INTERNAL_ERROR', msg, 500);
  }
});
