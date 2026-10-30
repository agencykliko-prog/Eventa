// Réception des webhooks SasPay. Signature et horodatage vérifiés sur le
// corps brut, réponse immédiate, rapprochement en tâche de fond.
// Une notification n'est qu'un signal : on revérifie toujours chez SasPay.
import { admin, reconcile } from '../_shared/saspay.ts';

const enc = new TextEncoder();

async function validSignature(raw: Uint8Array, header: string, timestamp: string, secret: string) {
  // Tolère un préfixe « sha256= » et l'hexadécimal en majuscules.
  const signature = header.trim().replace(/^sha256=/i, '').toLowerCase();
  const n = Number(timestamp);
  const ts = n > 1e12 ? n / 1000 : n; // secondes (ou millisecondes)
  if (!Number.isFinite(ts) || Math.abs(Date.now() / 1000 - ts) > 300) {
    console.warn('webhook refusé : horodatage', { timestamp, skew: Math.round(Date.now() / 1000 - ts) });
    return false;
  }
  const key = await crypto.subtle.importKey('raw', enc.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const msg = new Uint8Array([...enc.encode(`${timestamp}.`), ...raw]);
  const mac = new Uint8Array(await crypto.subtle.sign('HMAC', key, msg));
  const expected = [...mac].map((b) => b.toString(16).padStart(2, '0')).join('');
  // Comparaison en temps constant.
  let diff = expected.length ^ signature.length;
  for (let i = 0; i < expected.length; i++) diff |= expected.charCodeAt(i) ^ (signature.charCodeAt(i) || 0);
  if (diff !== 0) {
    // Diagnostic sans rien révéler : format reçu, jamais la signature ni le secret.
    console.warn('webhook refusé : signature', {
      length: signature.length, hex: /^[0-9a-f]+$/.test(signature), prefix: header.slice(0, 7).replace(/[0-9a-f]/gi, '#'),
      body_bytes: raw.length, secret_length: secret.length,
    });
  }
  return diff === 0;
}

async function handle(event: string, data: Record<string, unknown>) {
  if (!event.startsWith('transaction.')) return; // settlement.*, wallet_transfer.* : rien à faire ici
  const db = admin();
  const cols = 'id, amount, currency, status, provider_ref';
  const meta = (data?.metadata ?? {}) as Record<string, unknown>;
  const ref = typeof meta.eventa_payment_id === 'string' ? meta.eventa_payment_id : null;

  // Paiement désigné par nos métadonnées ou déjà lié à cette transaction ;
  // sinon, on repasse les paiements SasPay en attente des dernières 48 h.
  let { data: rows } = ref
    ? await db.from('payments').select(cols).eq('id', ref)
    : await db.from('payments').select(cols).eq('transaction_id', String(data?.id ?? ''));
  if (!rows?.length) {
    ({ data: rows } = await db.from('payments').select(cols)
      .eq('provider', 'saspay').eq('status', 'pending')
      .gte('created_at', new Date(Date.now() - 48 * 3600_000).toISOString()).limit(50));
  }
  for (const p of rows ?? []) {
    try { await reconcile(db, p); } catch (e) { console.error('webhook reconcile', p.id, e); }
  }
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 });
  // Espaces ou retour à la ligne collés avec le secret : ignorés.
  const secret = Deno.env.get('SASPAY_WEBHOOK_SECRET')?.trim();
  if (!secret) return new Response('Not configured', { status: 500 });
  if (!req.headers.get('X-Webhook-Signature') || !req.headers.get('X-Webhook-Timestamp')) {
    // Noms des en-têtes seulement, jamais leurs valeurs.
    console.warn('webhook refusé : en-têtes absents', [...req.headers.keys()].join(', '));
  }

  const raw = new Uint8Array(await req.arrayBuffer());
  const ok = await validSignature(
    raw, req.headers.get('X-Webhook-Signature') ?? '', req.headers.get('X-Webhook-Timestamp') ?? '', secret,
  );
  if (!ok) return new Response('Invalid signature', { status: 401 });

  let payload: { event?: string; data?: Record<string, unknown> } = {};
  try { payload = JSON.parse(new TextDecoder().decode(raw)); } catch { return new Response('Bad JSON', { status: 400 }); }
  const event = payload.event ?? req.headers.get('X-Webhook-Event') ?? '';

  // Traitement idempotent (règlement pending → succeeded une seule fois).
  // @ts-ignore EdgeRuntime existe dans l'environnement Supabase
  EdgeRuntime.waitUntil(handle(event, payload.data ?? {}).catch((e) => console.error('webhook', event, e)));
  return new Response('ok');
});
