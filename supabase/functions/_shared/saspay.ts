// Client SasPay côté serveur. La clé ne quitte jamais les Edge Functions.
// Spécification : https://docs.saspay.me/api-reference/openapi.json
import { createClient, type SupabaseClient } from 'npm:@supabase/supabase-js@2.49.4';

const BASE = 'https://api.saspay.me/api/v1';

export class SasPayError extends Error {
  constructor(readonly status: number, readonly code: string, message: string) {
    super(message);
  }
}

export async function saspay<T = Record<string, unknown>>(
  path: string,
  init: { method?: string; body?: unknown; idempotencyKey?: string } = {},
): Promise<T> {
  const key = Deno.env.get('SASPAY_API_KEY');
  if (!key) throw new SasPayError(500, 'config', 'SASPAY_API_KEY manquante');
  const headers: Record<string, string> = { Authorization: `Bearer ${key}`, Accept: 'application/json' };
  if (init.body !== undefined) headers['Content-Type'] = 'application/json';
  if (init.idempotencyKey) headers['Idempotency-Key'] = init.idempotencyKey;

  const res = await fetch(BASE + path, {
    method: init.method ?? 'GET',
    headers,
    body: init.body === undefined ? undefined : JSON.stringify(init.body),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok || json?.success === false) {
    console.error('saspay appel refusé', init.method ?? 'GET', path, res.status);
    const err = json?.error ?? json;
    const message = typeof err?.message === 'string' ? err.message : JSON.stringify(err).slice(0, 300);
    throw new SasPayError(res.status, err?.code ?? `http_${res.status}`, message);
  }
  // Enveloppe { success, data, code } ou objet direct selon la route.
  return (json?.data ?? json) as T;
}

// Montants : chaînes décimales, jamais de flottants. Le FCFA n'a pas de centimes.
export const decimal = (fcfa: number) => `${Math.round(fcfa)}.00`;
export const sameAmount = (a: string | undefined, fcfa: number) => a !== undefined && a === decimal(fcfa);

export const admin = (): SupabaseClient =>
  createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {
    auth: { persistSession: false },
  });

// Client au nom de l'utilisateur qui appelle (son jeton), pour lire ses droits.
export const asUser = (req: Request): SupabaseClient =>
  createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
    auth: { persistSession: false },
  });

export const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

export const reply = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, 'Content-Type': 'application/json' } });

// Erreur SasPay → réponse pour l'app, sans détail interne ni clé.
export function replyError(e: unknown) {
  if (e instanceof SasPayError) {
    console.error('saspay', e.status, e.code, e.message);
    const status = e.status === 429 ? 429 : e.status >= 500 || e.status === 401 ? 502 : e.status;
    const message = e.status === 429
      ? 'Trop de demandes, réessayez dans une minute.'
      : e.status === 401 || e.status >= 500
        ? 'Le service de paiement est indisponible pour le moment.'
        : e.message;
    return reply({ error: message, code: e.code }, status);
  }
  console.error(e);
  return reply({ error: 'Erreur inattendue.' }, 500);
}

type Payment = { id: string; amount: number; currency: string; status: string; provider_ref: string | null };

// Rapproche un paiement en attente de SasPay : seul un SUCCESS vérifié le règle.
export async function reconcile(db: SupabaseClient, p: Payment): Promise<string> {
  if (p.status !== 'pending' || !p.provider_ref) return p.status;
  const session = await saspay<{ status?: string; transaction_id?: string | null }>(
    `/checkout-sessions/${p.provider_ref}/status/`,
  );
  if (!session.transaction_id) {
    console.log('saspay rapprochement', p.id, { session: session.status, transaction: null });
    return 'pending';
  }
  const tx = await saspay<{
    status?: string; requested_amount?: string; debited_amount?: string; net_amount?: string; currency?: string;
  }>(`/payments/${session.transaction_id}/verify/`);
  console.log('saspay rapprochement', p.id, { session: session.status, transaction: tx.status });

  if (tx.status === 'SUCCESS') {
    if (tx.currency !== p.currency || !sameAmount(tx.requested_amount, p.amount)) {
      console.error('saspay montant inattendu', p.id, tx.requested_amount, tx.currency);
      return 'pending'; // à examiner à la main, on ne livre pas
    }
    const { error } = await db.rpc('saspay_settle_payment', {
      p_payment: p.id, p_transaction: session.transaction_id,
      p_charged: tx.debited_amount ?? null, p_net: tx.net_amount ?? null,
    });
    if (error) throw error;
    return 'succeeded';
  }
  // Échec de la transaction et session close : le paiement est perdu.
  // Session encore ouverte : le client peut réessayer sur la page SasPay.
  if (tx.status === 'FAILED' && session.status && session.status !== 'PENDING') {
    await db.from('payments').update({ status: 'failed', transaction_id: session.transaction_id })
      .eq('id', p.id).eq('status', 'pending');
    return 'failed';
  }
  return 'pending';
}
