-- ═══════════════════════════════════════════════════════════════════════
-- Eventa · schéma initial Supabase
-- À exécuter UNE FOIS sur un projet neuf : SQL Editor → New query →
-- coller tout le fichier → Run.
--
-- Contenu : profils (organisateur / Creator), événements et leur équipe,
-- budget, dépenses, tâches, invités, prestataires et forfaits, demandes de
-- devis, devis, messagerie, notifications, paiements, avis, vérification
-- des prestataires, abonnements, équipe d'administration, mesure
-- d'audience, stockage des fichiers.
--
-- Sécurité : RLS activée sur toutes les tables. Chacun ne voit que ses
-- données ; les membres d'un événement voient cet événement ; l'équipe
-- Eventa (admin_members) voit ce dont elle a besoin. Les paiements et les
-- abonnements ne sont écrits que par le serveur (clé secrète, fonctions
-- Edge), jamais par l'app.
-- ═══════════════════════════════════════════════════════════════════════

-- ─── Équipe d'administration ───────────────────────────────────────────

create table public.admin_members (
  user_id uuid primary key references auth.users (id) on delete cascade,
  role text not null check (role in ('super_admin', 'operations', 'finance', 'marketing', 'support', 'moderation')),
  created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.admin_members where user_id = auth.uid());
$$;

-- ─── Profils ───────────────────────────────────────────────────────────

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role text not null default 'organizer' check (role in ('organizer', 'creator')),
  full_name text not null default '',
  phone text,
  city text,
  avatar_url text,
  -- Formule organisateur : stockage du coffre-fort 100 Mo / 1 Go / 5 Go / 50 Go.
  plan text not null default 'free' check (plan in ('free', 'azur', 'signature', 'privilege')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Fiche professionnelle du Creator (prestataire), publiée dans la marketplace.
create table public.creator_profiles (
  id uuid primary key references public.profiles (id) on delete cascade,
  kind text not null default 'independent',
  business_name text not null,
  display_name text not null,
  category text not null,
  zone text not null,
  rccm text,
  description text not null default '',
  price_from bigint not null default 0 check (price_from >= 0),
  address text,
  website text,
  portfolio_url text,
  response_time text,
  verification text not null default 'draft' check (verification in ('draft', 'pending', 'info', 'verified', 'rejected')),
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.vendor_packages (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references public.creator_profiles (id) on delete cascade,
  name text not null,
  price bigint not null check (price >= 0),
  unit text not null default 'forfait',
  includes text[] not null default '{}',
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.vendor_photos (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references public.creator_profiles (id) on delete cascade,
  path text not null,
  position int not null default 0,
  created_at timestamptz not null default now()
);

-- Création automatique du profil à l'inscription. L'app envoie dans les
-- métadonnées : role, full_name, phone, city.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, role, full_name, phone, city)
  values (
    new.id,
    case when new.raw_user_meta_data ->> 'role' = 'creator' then 'creator' else 'organizer' end,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.raw_user_meta_data ->> 'phone',
    new.raw_user_meta_data ->> 'city'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Mise à jour automatique de updated_at.
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_touch before update on public.profiles
  for each row execute function public.touch_updated_at();
create trigger creator_profiles_touch before update on public.creator_profiles
  for each row execute function public.touch_updated_at();

-- Le rôle et la formule ne se modifient pas depuis l'app (formule : après
-- paiement, par le serveur).
create or replace function public.protect_profile_fields()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    new.role = old.role;
    new.plan = old.plan;
  end if;
  return new;
end;
$$;

create trigger profiles_protect before update on public.profiles
  for each row execute function public.protect_profile_fields();

-- Le statut de vérification n'est décidé que par l'équipe Eventa.
create or replace function public.protect_verification()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    new.verification = old.verification;
  end if;
  return new;
end;
$$;

create trigger creator_profiles_protect before update on public.creator_profiles
  for each row execute function public.protect_verification();

-- ─── Événements et équipe ──────────────────────────────────────────────

create table public.events (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  category text not null,
  subcategory text,
  starts_at timestamptz not null,
  place text,
  guests_expected int not null default 0 check (guests_expected >= 0),
  budget_target bigint not null default 0 check (budget_target >= 0),
  cover_url text,
  archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger events_touch before update on public.events
  for each row execute function public.touch_updated_at();

create table public.event_members (
  event_id uuid not null references public.events (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role text not null default 'editor' check (role in ('admin', 'editor', 'viewer')),
  created_at timestamptz not null default now(),
  primary key (event_id, user_id)
);

-- Le créateur de l'événement en devient administrateur.
create or replace function public.add_event_owner()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.event_members (event_id, user_id, role)
  values (new.id, new.owner_id, 'admin');
  return new;
end;
$$;

create trigger events_add_owner
  after insert on public.events
  for each row execute function public.add_event_owner();

-- Accès à un événement : lecteur, éditeur ou administrateur.
create or replace function public.can_read_event(e uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.event_members m
    where m.event_id = e and m.user_id = auth.uid()
  );
$$;

create or replace function public.can_edit_event(e uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.event_members m
    where m.event_id = e and m.user_id = auth.uid() and m.role in ('admin', 'editor')
  );
$$;

create or replace function public.is_event_admin(e uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.event_members m
    where m.event_id = e and m.user_id = auth.uid() and m.role = 'admin'
  );
$$;

-- ─── Budget, dépenses, tâches, invités ─────────────────────────────────

create table public.budget_lines (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  category text not null,
  label text not null,
  planned bigint not null default 0 check (planned >= 0),
  committed bigint not null default 0 check (committed >= 0),
  created_at timestamptz not null default now()
);

create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  category text not null,
  label text not null,
  amount bigint not null check (amount > 0),
  paid_at timestamptz not null default now(),
  method text,
  receipt_ref text,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  title text not null,
  due_at timestamptz,
  done boolean not null default false,
  module text,
  assignee_id uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.guests (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  name text not null,
  phone text,
  group_name text,
  rsvp text not null default 'pending' check (rsvp in ('pending', 'yes', 'no')),
  companions int not null default 0 check (companions >= 0),
  diet text,
  created_at timestamptz not null default now()
);

-- ─── Demandes de devis, devis, avis ────────────────────────────────────

create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  organizer_id uuid not null references public.profiles (id) on delete cascade,
  creator_id uuid not null references public.creator_profiles (id) on delete cascade,
  step text not null default 'requested' check (step in ('requested', 'quoted', 'reserved', 'paid', 'executing', 'closed', 'declined')),
  event_date timestamptz not null,
  guests int not null default 0 check (guests >= 0),
  message text not null default '',
  options text[] not null default '{}',
  budget bigint,
  paid_amount bigint not null default 0 check (paid_amount >= 0),
  decline_reason text,
  archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger bookings_touch before update on public.bookings
  for each row execute function public.touch_updated_at();

-- Le montant payé ne change qu'après un paiement confirmé (serveur) ; les
-- parties, l'événement et la date de la demande ne changent pas.
create or replace function public.protect_booking_paid()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    new.paid_amount = old.paid_amount;
    new.organizer_id = old.organizer_id;
    new.creator_id = old.creator_id;
    new.event_id = old.event_id;
  end if;
  return new;
end;
$$;

create trigger bookings_protect before update on public.bookings
  for each row execute function public.protect_booking_paid();

create table public.quotes (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings (id) on delete cascade,
  -- Lignes : [{"label": "...", "amount": 450000, "optional": false}, ...]
  lines jsonb not null default '[]',
  fees bigint not null default 0 check (fees >= 0),
  total bigint not null check (total >= 0),
  deposit_rate numeric(4, 3) not null default 0.3 check (deposit_rate between 0 and 1),
  conditions text[] not null default '{}',
  valid_until timestamptz not null,
  created_at timestamptz not null default now()
);

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings (id) on delete cascade,
  author_id uuid not null references public.profiles (id) on delete cascade,
  creator_id uuid not null references public.creator_profiles (id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  body text not null default '',
  reply text,
  created_at timestamptz not null default now()
);

-- ─── Messagerie ────────────────────────────────────────────────────────

-- Une conversation entre un organisateur et un Creator, liée ou non à une
-- demande de devis (message envoyé depuis la fiche).
create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  organizer_id uuid not null references public.profiles (id) on delete cascade,
  creator_id uuid not null references public.creator_profiles (id) on delete cascade,
  booking_id uuid unique references public.bookings (id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  body text not null check (length(body) between 1 and 4000),
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index messages_conversation_idx on public.messages (conversation_id, created_at);

-- Un message envoyé ne se modifie plus : seul « lu » peut changer.
create or replace function public.protect_message()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.body = old.body;
  new.sender_id = old.sender_id;
  new.conversation_id = old.conversation_id;
  new.created_at = old.created_at;
  return new;
end;
$$;

create trigger messages_protect before update on public.messages
  for each row execute function public.protect_message();

create or replace function public.in_conversation(c uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.conversations x
    where x.id = c and (x.organizer_id = auth.uid() or x.creator_id = auth.uid())
  );
$$;

-- ─── Notifications ─────────────────────────────────────────────────────

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null,
  title text not null,
  body text not null default '',
  link text,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index notifications_user_idx on public.notifications (user_id, created_at desc);

-- ─── Paiements et abonnements (écrits par le serveur uniquement) ───────

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  payer_id uuid not null references public.profiles (id) on delete cascade,
  booking_id uuid references public.bookings (id) on delete set null,
  event_id uuid references public.events (id) on delete set null,
  purpose text not null check (purpose in ('deposit', 'balance', 'subscription', 'other')),
  amount bigint not null check (amount > 0),
  currency text not null default 'XOF',
  method text not null,
  status text not null default 'pending' check (status in ('pending', 'succeeded', 'failed', 'refunded')),
  provider text,
  provider_ref text,
  receipt_ref text unique,
  created_at timestamptz not null default now()
);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  product text not null check (product in ('premium', 'creator')),
  plan text not null,
  status text not null default 'active' check (status in ('active', 'cancelled', 'expired')),
  renews_on timestamptz not null,
  receipt_ref text,
  created_at timestamptz not null default now()
);

-- ─── Vérification des prestataires ─────────────────────────────────────

create table public.verification_checks (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references public.creator_profiles (id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'info', 'approved', 'rejected')),
  -- Pièces : [{"kind": "identity", "path": "<uid>/cni.pdf"}, ...]
  documents jsonb not null default '[]',
  comment text,
  submitted_at timestamptz not null default now(),
  decided_at timestamptz,
  decided_by uuid references public.profiles (id) on delete set null
);

-- La décision de l'équipe se reporte sur la fiche du Creator.
create or replace function public.apply_verification()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.creator_profiles
  set verification = case new.status
    when 'pending' then 'pending'
    when 'info' then 'info'
    when 'approved' then 'verified'
    when 'rejected' then 'rejected'
  end
  where id = new.creator_id;
  return new;
end;
$$;

create trigger verification_apply
  after insert or update of status on public.verification_checks
  for each row execute function public.apply_verification();

-- ─── Mesure d'audience (anonyme : modèle d'écran, sans identifiant) ────

create table public.audience_hits (
  id bigint generated always as identity primary key,
  metric text not null,
  screen text,
  at timestamptz not null default now()
);

-- ═══════════════════════════════════════════════════════════════════════
-- Sécurité par ligne (RLS)
-- ═══════════════════════════════════════════════════════════════════════

alter table public.admin_members enable row level security;
alter table public.profiles enable row level security;
alter table public.creator_profiles enable row level security;
alter table public.vendor_packages enable row level security;
alter table public.vendor_photos enable row level security;
alter table public.events enable row level security;
alter table public.event_members enable row level security;
alter table public.budget_lines enable row level security;
alter table public.expenses enable row level security;
alter table public.tasks enable row level security;
alter table public.guests enable row level security;
alter table public.bookings enable row level security;
alter table public.quotes enable row level security;
alter table public.reviews enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;
alter table public.payments enable row level security;
alter table public.subscriptions enable row level security;
alter table public.verification_checks enable row level security;
alter table public.audience_hits enable row level security;

-- Équipe d'administration : lecture par l'équipe ; ajouts faits à la main
-- (SQL Editor) par le propriétaire du projet.
create policy "admins lisent l'équipe" on public.admin_members
  for select to authenticated using (public.is_admin());

-- Profils : chacun lit et modifie le sien ; l'équipe lit tout.
create policy "lire son profil" on public.profiles
  for select to authenticated using (id = auth.uid() or public.is_admin());
create policy "modifier son profil" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- Fiches Creator : publiques une fois publiées ; le Creator gère la sienne.
create policy "lire les fiches publiées" on public.creator_profiles
  for select using (published or id = auth.uid() or public.is_admin());
create policy "créer sa fiche" on public.creator_profiles
  for insert to authenticated with check (
    id = auth.uid()
    and exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'creator')
  );
create policy "modifier sa fiche" on public.creator_profiles
  for update to authenticated using (id = auth.uid() or public.is_admin())
  with check (id = auth.uid() or public.is_admin());

create policy "lire les forfaits" on public.vendor_packages
  for select using (
    exists (select 1 from public.creator_profiles c where c.id = creator_id and (c.published or c.id = auth.uid()))
  );
create policy "gérer ses forfaits" on public.vendor_packages
  for all to authenticated using (creator_id = auth.uid()) with check (creator_id = auth.uid());

create policy "lire les photos" on public.vendor_photos
  for select using (
    exists (select 1 from public.creator_profiles c where c.id = creator_id and (c.published or c.id = auth.uid()))
  );
create policy "gérer ses photos" on public.vendor_photos
  for all to authenticated using (creator_id = auth.uid()) with check (creator_id = auth.uid());

-- Événements : membres en lecture, éditeurs en écriture, admin de
-- l'événement pour supprimer.
create policy "lire ses événements" on public.events
  for select to authenticated using (public.can_read_event(id) or owner_id = auth.uid());
create policy "créer un événement" on public.events
  for insert to authenticated with check (owner_id = auth.uid());
create policy "modifier un événement" on public.events
  for update to authenticated using (public.can_edit_event(id)) with check (public.can_edit_event(id));
create policy "supprimer un événement" on public.events
  for delete to authenticated using (public.is_event_admin(id));

create policy "lire l'équipe de l'événement" on public.event_members
  for select to authenticated using (public.can_read_event(event_id));
create policy "inviter dans l'équipe" on public.event_members
  for insert to authenticated with check (public.is_event_admin(event_id));
create policy "changer un rôle" on public.event_members
  for update to authenticated using (public.is_event_admin(event_id)) with check (public.is_event_admin(event_id));
create policy "retirer un membre ou partir" on public.event_members
  for delete to authenticated using (public.is_event_admin(event_id) or user_id = auth.uid());

-- Budget, dépenses, tâches, invités : même règle que l'événement.
create policy "lire" on public.budget_lines for select to authenticated using (public.can_read_event(event_id));
create policy "écrire" on public.budget_lines for all to authenticated
  using (public.can_edit_event(event_id)) with check (public.can_edit_event(event_id));

create policy "lire" on public.expenses for select to authenticated using (public.can_read_event(event_id));
create policy "écrire" on public.expenses for all to authenticated
  using (public.can_edit_event(event_id)) with check (public.can_edit_event(event_id));

create policy "lire" on public.tasks for select to authenticated using (public.can_read_event(event_id));
create policy "écrire" on public.tasks for all to authenticated
  using (public.can_edit_event(event_id)) with check (public.can_edit_event(event_id));

create policy "lire" on public.guests for select to authenticated using (public.can_read_event(event_id));
create policy "écrire" on public.guests for all to authenticated
  using (public.can_edit_event(event_id)) with check (public.can_edit_event(event_id));

-- Demandes de devis : l'organisateur (et l'équipe de l'événement) et le
-- Creator concerné.
create policy "lire ses demandes" on public.bookings
  for select to authenticated using (
    organizer_id = auth.uid() or creator_id = auth.uid()
    or public.can_read_event(event_id) or public.is_admin()
  );
create policy "demander un devis" on public.bookings
  for insert to authenticated with check (organizer_id = auth.uid() and public.can_edit_event(event_id));
create policy "faire avancer une demande" on public.bookings
  for update to authenticated using (organizer_id = auth.uid() or creator_id = auth.uid())
  with check (organizer_id = auth.uid() or creator_id = auth.uid());

-- Devis : rédigés par le Creator, lus par les deux parties.
create policy "lire les devis" on public.quotes
  for select to authenticated using (
    exists (
      select 1 from public.bookings b where b.id = booking_id
      and (b.organizer_id = auth.uid() or b.creator_id = auth.uid() or public.can_read_event(b.event_id))
    )
  );
create policy "envoyer un devis" on public.quotes
  for insert to authenticated with check (
    exists (select 1 from public.bookings b where b.id = booking_id and b.creator_id = auth.uid())
  );
create policy "modifier son devis" on public.quotes
  for update to authenticated using (
    exists (select 1 from public.bookings b where b.id = booking_id and b.creator_id = auth.uid())
  );

-- Avis : publics ; laissés par l'organisateur d'une prestation clôturée ;
-- le Creator peut répondre.
create policy "lire les avis" on public.reviews for select using (true);
create policy "laisser un avis" on public.reviews
  for insert to authenticated with check (
    author_id = auth.uid()
    and exists (
      select 1 from public.bookings b
      where b.id = booking_id and b.organizer_id = auth.uid()
      and b.creator_id = reviews.creator_id and b.step = 'closed'
    )
  );
create policy "répondre à un avis" on public.reviews
  for update to authenticated using (creator_id = auth.uid()) with check (creator_id = auth.uid());

-- Messagerie : seuls les deux participants.
create policy "lire ses conversations" on public.conversations
  for select to authenticated using (organizer_id = auth.uid() or creator_id = auth.uid());
create policy "ouvrir une conversation" on public.conversations
  for insert to authenticated with check (organizer_id = auth.uid() or creator_id = auth.uid());

create policy "lire les messages" on public.messages
  for select to authenticated using (public.in_conversation(conversation_id));
create policy "envoyer un message" on public.messages
  for insert to authenticated with check (sender_id = auth.uid() and public.in_conversation(conversation_id));
create policy "marquer comme lu" on public.messages
  for update to authenticated using (public.in_conversation(conversation_id) and sender_id <> auth.uid());

-- Notifications : chacun les siennes (créées par le serveur ou les
-- déclencheurs).
create policy "lire ses notifications" on public.notifications
  for select to authenticated using (user_id = auth.uid());
create policy "marquer ses notifications" on public.notifications
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Paiements et abonnements : lecture seule pour l'intéressé (et le Creator
-- payé) ; écriture réservée au serveur.
create policy "lire ses paiements" on public.payments
  for select to authenticated using (
    payer_id = auth.uid() or public.is_admin()
    or exists (select 1 from public.bookings b where b.id = booking_id and b.creator_id = auth.uid())
  );
create policy "lire ses abonnements" on public.subscriptions
  for select to authenticated using (user_id = auth.uid() or public.is_admin());

-- Vérification : le Creator dépose et suit son dossier ; l'équipe décide.
create policy "lire son dossier" on public.verification_checks
  for select to authenticated using (creator_id = auth.uid() or public.is_admin());
create policy "déposer un dossier" on public.verification_checks
  for insert to authenticated with check (creator_id = auth.uid() and status = 'pending');
create policy "décider" on public.verification_checks
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- Audience : tout le monde peut envoyer un événement anonyme ; seule
-- l'équipe lit.
create policy "envoyer une mesure" on public.audience_hits
  for insert to anon, authenticated with check (true);
create policy "lire la mesure" on public.audience_hits
  for select to authenticated using (public.is_admin());

-- ═══════════════════════════════════════════════════════════════════════
-- Notifications automatiques
-- ═══════════════════════════════════════════════════════════════════════

create or replace function public.notify_new_message()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  c public.conversations;
  recipient uuid;
begin
  select * into c from public.conversations where id = new.conversation_id;
  recipient := case when new.sender_id = c.organizer_id then c.creator_id else c.organizer_id end;
  insert into public.notifications (user_id, kind, title, body, link)
  values (recipient, 'message', 'Nouveau message', left(new.body, 140), '/messages/' || new.conversation_id);
  return new;
end;
$$;

create trigger messages_notify
  after insert on public.messages
  for each row execute function public.notify_new_message();

create or replace function public.notify_new_quote()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  b public.bookings;
begin
  select * into b from public.bookings where id = new.booking_id;
  update public.bookings set step = 'quoted' where id = b.id and step = 'requested';
  insert into public.notifications (user_id, kind, title, body, link)
  values (b.organizer_id, 'quote', 'Devis reçu', 'Valable jusqu’au ' || to_char(new.valid_until, 'DD/MM/YYYY'), '/reservation/' || b.id);
  return new;
end;
$$;

create trigger quotes_notify
  after insert on public.quotes
  for each row execute function public.notify_new_quote();

create or replace function public.notify_new_request()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.notifications (user_id, kind, title, body, link)
  values (new.creator_id, 'request', 'Nouvelle demande de devis', left(new.message, 140), '/pro/devis/' || new.id);
  return new;
end;
$$;

create trigger bookings_notify
  after insert on public.bookings
  for each row execute function public.notify_new_request();

create or replace function public.notify_verification()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status is distinct from old.status and new.status <> 'pending' then
    insert into public.notifications (user_id, kind, title, body, link)
    values (
      new.creator_id,
      'verification',
      case new.status
        when 'approved' then 'Profil vérifié'
        when 'info' then 'Informations demandées'
        else 'Vérification refusée'
      end,
      coalesce(new.comment, ''),
      '/pro/verification'
    );
  end if;
  return new;
end;
$$;

create trigger verification_notify
  after update of status on public.verification_checks
  for each row execute function public.notify_verification();

-- ═══════════════════════════════════════════════════════════════════════
-- Temps réel : messages, notifications et demandes arrivent sans recharger
-- ═══════════════════════════════════════════════════════════════════════

alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.notifications;
alter publication supabase_realtime add table public.bookings;

-- ═══════════════════════════════════════════════════════════════════════
-- Stockage des fichiers
-- Chemin des fichiers : <id de l'utilisateur>/<nom du fichier>
-- ═══════════════════════════════════════════════════════════════════════

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('portfolio', 'portfolio', true, 10485760, array['image/jpeg', 'image/png', 'image/webp']),
  ('vault', 'vault', false, 52428800, array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
  ('verification', 'verification', false, 10485760, array['image/jpeg', 'image/png', 'application/pdf'])
on conflict (id) do nothing;

-- Photos de profil et portfolio : lecture publique, écriture dans son dossier.
create policy "avatars : lecture publique" on storage.objects
  for select using (bucket_id = 'avatars');
create policy "avatars : son dossier" on storage.objects
  for all to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "portfolio : lecture publique" on storage.objects
  for select using (bucket_id = 'portfolio');
create policy "portfolio : son dossier" on storage.objects
  for all to authenticated
  using (bucket_id = 'portfolio' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'portfolio' and (storage.foldername(name))[1] = auth.uid()::text);

-- Coffre-fort : privé, uniquement son dossier.
create policy "coffre-fort : son dossier" on storage.objects
  for all to authenticated
  using (bucket_id = 'vault' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'vault' and (storage.foldername(name))[1] = auth.uid()::text);

-- Pièces de vérification : le Creator dépose et relit les siennes ;
-- l'équipe Eventa peut les consulter.
create policy "vérification : son dossier" on storage.objects
  for all to authenticated
  using (bucket_id = 'verification' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'verification' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "vérification : lecture par l'équipe" on storage.objects
  for select to authenticated
  using (bucket_id = 'verification' and public.is_admin());
