import crypto from 'node:crypto';

export const runtime = 'nodejs';

type LemonWebhook = {
  meta?: {
    event_name?: string;
    custom_data?: { user_id?: string };
  };
  data?: {
    id?: string;
    attributes?: {
      total?: number;
      currency?: string;
      status?: string;
    };
  };
};

export async function POST(request: Request) {
  const webhookSecret = process.env.LEMON_SQUEEZY_WEBHOOK_SECRET;
  const supabaseUrl = process.env.SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const missing = [
    !webhookSecret && 'LEMON_SQUEEZY_WEBHOOK_SECRET',
    !supabaseUrl && 'SUPABASE_URL',
    !serviceRoleKey && 'SUPABASE_SERVICE_ROLE_KEY',
  ].filter(Boolean);
  if (missing.length > 0) {
    return Response.json(
      { status: 'configuration_error', missing },
      { status: 500 },
    );
  }
  const configuredWebhookSecret = webhookSecret!;
  const configuredSupabaseUrl = supabaseUrl!;
  const configuredServiceRoleKey = serviceRoleKey!;

  const rawBody = await request.text();
  const suppliedHex = request.headers.get('x-signature') ?? '';
  const expectedHex = crypto
    .createHmac('sha256', configuredWebhookSecret)
    .update(rawBody)
    .digest('hex');
  const supplied = Buffer.from(suppliedHex, 'utf8');
  const expected = Buffer.from(expectedHex, 'utf8');
  if (
    supplied.length !== expected.length ||
    !crypto.timingSafeEqual(supplied, expected)
  ) {
    return Response.json({ status: 'invalid_signature' }, { status: 401 });
  }

  let event: LemonWebhook;
  try {
    event = JSON.parse(rawBody) as LemonWebhook;
  } catch {
    return Response.json({ status: 'invalid_json' }, { status: 400 });
  }
  if (event.meta?.event_name !== 'order_created') {
    return Response.json({ status: 'ignored' });
  }

  const userId = event.meta.custom_data?.user_id;
  const orderId = event.data?.id;
  if (!userId || !orderId) {
    return Response.json({ status: 'missing_order_data' }, { status: 400 });
  }

  const databaseResponse = await fetch(
    `${configuredSupabaseUrl}/rest/v1/rpc/finova_grant_premium`,
    {
      method: 'POST',
      headers: {
        apikey: configuredServiceRoleKey,
        Authorization: `Bearer ${configuredServiceRoleKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        target_user_id: userId,
        target_order_id: orderId,
        target_event_name: 'order_created',
        target_amount: event.data?.attributes?.total ?? null,
        target_currency: event.data?.attributes?.currency ?? '',
        target_payload: event,
      }),
    },
  );
  if (!databaseResponse.ok) {
    return Response.json({ status: 'database_error' }, { status: 500 });
  }
  return Response.json({ status: 'success' });
}
