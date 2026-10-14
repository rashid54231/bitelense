import { corsHeaders } from './cors.ts';

export function jsonResponse(
  body: { ok: boolean; data?: unknown; error?: { code: string; message: string } },
  status = 200
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

export function errorResponse(code: string, message: string, status = 400): Response {
  return jsonResponse(
    {
      ok: false,
      error: { code, message },
    },
    status
  );
}
