// Reversement à un prestataire sur son mobile money. Réservé à l'équipe Eventa.
//
// Corps : { action: 'create', creator_id, amount, booking_id? }
//      ou { action: 'retry' | 'verify', payout_id }
// Un nouvel essai réutilise la même Idempotency-Key : jamais de double envoi.
// SasPay exige une IP whitelistée pour les payouts (sinon 403 ip_not_whitelisted).
import { admin, asUser, cors, decimal, replyError, reply, saspay, SasPayError } from '../_shared/saspay.ts';

type Payout = {
  id: string; creator_id: string; booking_id: string | null; amount: number; currency: string;
  method: string; msisdn: string; status: string; idempotency_key: string; provider_ref: string | null;
};

async function send(db: ReturnType<typeof admin>, p: Payout) {
  const { data: creator } = await db.from('profiles').select('full_name, phone').eq('id', p.creator_id).single();
  const [first, ...rest] = (creator?.full_name ?? '').trim().split(/\s+/);
  try {
    const res = await saspay<{ id: string }>('/payouts/initialize/', {
      method: 'POST',
      idempotencyKey: p.idempotency_key,
      body: {
        amount: decimal(p.amount),
        currency: p.currency,
        country: 'CI',
        method: p.method,
        recipient: { msisdn: p.msisdn },
        customer: { first_name: first || 'Prestataire', last_name: rest.join(' ') || 'Eventa', ...(creator?.phone ? { phone: creator.phone } : {}) },
        description: p.booking_id ? `Reversement réservation ${p.booking_id.slice(0, 8)}` : 'Reversement Eventa',
        metadata: { eventa_payout_id: p.id },
      },
    });
    await db.from('payouts').update({ provider_ref: res.id, error: null }).eq('id', p.id);
    return { ...p, provider_ref: res.id };
  } catch (e) {
    // 409 : même clé déjà traitée ou en cours, on ne renvoie rien.
    if (e instanceof SasPayError && e.status !== 409) {
      await db.from('payouts').update({ error: `${e.code}: ${e.message}`.slice(0, 300) }).eq('id', p.id);
    }
    throw e;
  }
}

async function verify(db: ReturnType<typeof admin>, p: Payout) {
  if (!p.provider_ref || p.status !== 'pending') return p.status;
  const tx = await saspay<{ status?: string; net_amount?: string }>(`/payouts/${p.provider_ref}/verify/`);
  const status = tx.status === 'SUCCESS' ? 'succeeded' : tx.status === 'FAILED' ? 'failed' : 'pending';
  if (status !== 'pending') {
    await db.from('payouts').update({ status, net_amount: tx.net_amount ?? null }).eq('id', p.id).eq('status', 'pending');
  }
  return status;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: cors });
  if (req.method !== 'POST') return reply({ error: 'Méthode non autorisée.' }, 405);
  try {
    const user = asUser(req);
    const { data: { user: me } } = await user.auth.getUser();
    const { data: isAdmin } = await user.rpc('is_admin');
    if (!me || !isAdmin) return reply({ error: 'Réservé à l’équipe Eventa.' }, 403);

    const body = await req.json().catch(() => ({}));
    const db = admin();
    const cols = 'id, creator_id, booking_id, amount, currency, method, msisdn, status, idempotency_key, provider_ref';

    if (body.action === 'create') {
      const amount = Number(body.amount);
      if (!Number.isInteger(amount) || amount <= 0) return reply({ error: 'Montant invalide (FCFA entiers).' }, 400);
      const { data: account } = await db.from('payout_accounts').select('method, msisdn').eq('creator_id', body.creator_id).single();
      if (!account) return reply({ error: 'Le prestataire n’a pas renseigné son compte mobile money.' }, 422);
      const { data: p, error } = await db.from('payouts').insert({
        creator_id: body.creator_id, booking_id: body.booking_id ?? null, amount,
        method: account.method, msisdn: account.msisdn, created_by: me.id,
      }).select(cols).single();
      if (error) throw error;
      const sent = await send(db, p);
      return reply({ payout_id: p.id, status: await verify(db, sent) });
    }

    const { data: p } = await db.from('payouts').select(cols).eq('id', body.payout_id).single();
    if (!p) return reply({ error: 'Reversement introuvable.' }, 404);
    if (body.action === 'retry') {
      if (p.provider_ref) return reply({ payout_id: p.id, status: await verify(db, p) });
      const sent = await send(db, p);
      return reply({ payout_id: p.id, status: await verify(db, sent) });
    }
    if (body.action === 'verify') return reply({ payout_id: p.id, status: await verify(db, p) });
    return reply({ error: 'Action inconnue.' }, 400);
  } catch (e) {
    return replyError(e);
  }
});
