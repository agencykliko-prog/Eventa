// Statut réel d'un paiement, vérifié auprès de SasPay (retour de la page de
// paiement, bouton « J'ai payé »). Le retour seul ne prouve rien.
//
// Corps : { payment_id } → { status: 'pending' | 'succeeded' | 'failed' | 'refunded' }
import { admin, asUser, cors, reconcile, replyError, reply } from '../_shared/saspay.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: cors });
  if (req.method !== 'POST') return reply({ error: 'Méthode non autorisée.' }, 405);
  try {
    const { data: { user } } = await asUser(req).auth.getUser();
    if (!user) return reply({ error: 'Connexion requise.' }, 401);
    const { payment_id } = await req.json().catch(() => ({}));
    const db = admin();
    const { data: p } = await db.from('payments')
      .select('id, payer_id, amount, currency, status, provider_ref').eq('id', payment_id).single();
    if (!p || p.payer_id !== user.id) return reply({ error: 'Paiement introuvable.' }, 404);
    return reply({ status: await reconcile(db, p) });
  } catch (e) {
    return replyError(e);
  }
});
