-- Paiements SasPay : encaissements (acomptes, soldes, abonnements) et
-- reversements aux prestataires. Toutes les écritures passent par les
-- Edge Functions (rôle service) ; l'app ne fait que lire.

-- ─── Encaissements ──────────────────────────────────────────────────────

alter table public.payments
  add column checkout_url text,
  add column transaction_id text unique,
  -- Comptabilité : ce que le payeur a déboursé, ce qui revient à Eventa.
  add column charged numeric(14, 2),
  add column net_amount numeric(14, 2),
  -- Abonnements : formule achetée.
  add column product text check (product in ('premium', 'creator')),
  add column plan text,
  add column paid_at timestamptz;

create index payments_pending_idx on public.payments (created_at)
  where status = 'pending' and provider = 'saspay';

-- Règlement d'un paiement confirmé par SasPay (statut SUCCESS vérifié).
-- Idempotent : seul le passage pending → succeeded produit des effets.
create or replace function public.saspay_settle_payment(
  p_payment uuid, p_transaction text, p_charged numeric, p_net numeric
) returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  p public.payments;
  base timestamptz;
begin
  update public.payments
     set status = 'succeeded', transaction_id = p_transaction,
         charged = p_charged, net_amount = p_net, paid_at = now(),
         receipt_ref = coalesce(receipt_ref, 'EVT-' || upper(substr(replace(id::text, '-', ''), 1, 10)))
   where id = p_payment and status = 'pending'
  returning * into p;
  if not found then
    return false;
  end if;

  if p.purpose in ('deposit', 'balance') and p.booking_id is not null then
    update public.bookings
       set paid_amount = paid_amount + p.amount,
           step = case when step in ('quoted', 'reserved') then 'paid' else step end
     where id = p.booking_id;
  elsif p.purpose = 'subscription' then
    -- Un réabonnement prolonge la période en cours au lieu de l'écraser.
    select max(renews_on) into base from public.subscriptions
     where user_id = p.payer_id and product = p.product and status = 'active';
    insert into public.subscriptions (user_id, product, plan, status, renews_on, receipt_ref)
    values (p.payer_id, p.product, p.plan, 'active',
            greatest(coalesce(base, now()), now()) + interval '1 month', p.receipt_ref);
  end if;
  return true;
end;
$$;

revoke execute on function public.saspay_settle_payment(uuid, text, numeric, numeric)
  from public, anon, authenticated;

-- ─── Reversements aux prestataires ──────────────────────────────────────

-- Compte de réception mobile money du prestataire. Table à part : la fiche
-- creator_profiles est publique, le numéro ne doit pas l'être.
create table public.payout_accounts (
  creator_id uuid primary key references public.creator_profiles (id) on delete cascade,
  method text not null check (method ~ '^[a-z0-9_]{2,30}$'),   -- code réseau SasPay
  msisdn text not null check (msisdn ~ '^[0-9]{8,15}$'),
  updated_at timestamptz not null default now()
);

create trigger payout_accounts_touch before update on public.payout_accounts
  for each row execute function public.touch_updated_at();

alter table public.payout_accounts enable row level security;

create policy "lire son compte de reversement" on public.payout_accounts
  for select to authenticated using (creator_id = auth.uid() or public.is_admin());
create policy "créer son compte de reversement" on public.payout_accounts
  for insert to authenticated with check (creator_id = auth.uid());
create policy "modifier son compte de reversement" on public.payout_accounts
  for update to authenticated using (creator_id = auth.uid()) with check (creator_id = auth.uid());

create table public.payouts (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references public.creator_profiles (id) on delete restrict,
  booking_id uuid references public.bookings (id) on delete set null,
  amount bigint not null check (amount > 0),
  currency text not null default 'XOF',
  method text not null,
  msisdn text not null,
  status text not null default 'pending' check (status in ('pending', 'succeeded', 'failed')),
  -- Une clé par reversement, renvoyée telle quelle à chaque nouvel essai.
  idempotency_key uuid not null unique default gen_random_uuid(),
  provider_ref text unique,
  net_amount numeric(14, 2),
  error text,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger payouts_touch before update on public.payouts
  for each row execute function public.touch_updated_at();

alter table public.payouts enable row level security;

create policy "lire ses reversements" on public.payouts
  for select to authenticated using (creator_id = auth.uid() or public.is_admin());
