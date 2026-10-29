-- ═══════════════════════════════════════════════════════════════════════
-- Eventa · réparation des déclencheurs (sans risque, peut être relancé)
-- Recrée les fonctions et les 15 déclencheurs du schéma initial. Ne touche
-- ni aux tables ni aux données.
-- SQL Editor → New query → coller tout le fichier → Run.
-- ═══════════════════════════════════════════════════════════════════════

-- ─── Fonctions ─────────────────────────────────────────────────────────

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.admin_members where user_id = auth.uid());
$$;

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

-- ─── Déclencheurs ──────────────────────────────────────────────────────

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

drop trigger if exists profiles_touch on public.profiles;
create trigger profiles_touch before update on public.profiles
  for each row execute function public.touch_updated_at();

drop trigger if exists creator_profiles_touch on public.creator_profiles;
create trigger creator_profiles_touch before update on public.creator_profiles
  for each row execute function public.touch_updated_at();

drop trigger if exists profiles_protect on public.profiles;
create trigger profiles_protect before update on public.profiles
  for each row execute function public.protect_profile_fields();

drop trigger if exists creator_profiles_protect on public.creator_profiles;
create trigger creator_profiles_protect before update on public.creator_profiles
  for each row execute function public.protect_verification();

drop trigger if exists events_touch on public.events;
create trigger events_touch before update on public.events
  for each row execute function public.touch_updated_at();

drop trigger if exists events_add_owner on public.events;
create trigger events_add_owner
  after insert on public.events
  for each row execute function public.add_event_owner();

drop trigger if exists bookings_touch on public.bookings;
create trigger bookings_touch before update on public.bookings
  for each row execute function public.touch_updated_at();

drop trigger if exists bookings_protect on public.bookings;
create trigger bookings_protect before update on public.bookings
  for each row execute function public.protect_booking_paid();

drop trigger if exists messages_protect on public.messages;
create trigger messages_protect before update on public.messages
  for each row execute function public.protect_message();

drop trigger if exists verification_apply on public.verification_checks;
create trigger verification_apply
  after insert or update of status on public.verification_checks
  for each row execute function public.apply_verification();

drop trigger if exists messages_notify on public.messages;
create trigger messages_notify
  after insert on public.messages
  for each row execute function public.notify_new_message();

drop trigger if exists quotes_notify on public.quotes;
create trigger quotes_notify
  after insert on public.quotes
  for each row execute function public.notify_new_quote();

drop trigger if exists bookings_notify on public.bookings;
create trigger bookings_notify
  after insert on public.bookings
  for each row execute function public.notify_new_request();

drop trigger if exists verification_notify on public.verification_checks;
create trigger verification_notify
  after update of status on public.verification_checks
  for each row execute function public.notify_verification();

-- ─── Contrôle : doit afficher 15 lignes ────────────────────────────────

select tgname as declencheur, tgrelid::regclass as sur_la_table
from pg_trigger
where not tgisinternal
  and tgname in ('on_auth_user_created', 'profiles_touch', 'creator_profiles_touch', 'profiles_protect', 'creator_profiles_protect', 'events_touch', 'events_add_owner', 'bookings_touch', 'bookings_protect', 'messages_protect', 'verification_apply', 'messages_notify', 'quotes_notify', 'bookings_notify', 'verification_notify')
order by 1;
