-- Inscriptions « Accès anticipé » de la landing.
create table public.early_access (
  id uuid primary key default gen_random_uuid(),
  nom text not null check (char_length(nom) between 2 and 120),
  whatsapp text not null unique check (whatsapp ~ '^\+?[0-9]{8,15}$'),
  consent boolean not null check (consent),
  source text not null default 'landing' check (char_length(source) <= 40),
  -- Suivi des relances WhatsApp.
  status text not null default 'nouveau'
    check (status in ('nouveau', 'contacte', 'inscrit', 'desinscrit')),
  last_contacted_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.early_access enable row level security;

create policy "s'inscrire à l'accès anticipé" on public.early_access
  for insert to anon, authenticated
  with check (consent and status = 'nouveau' and last_contacted_at is null);

create policy "admins lisent l'accès anticipé" on public.early_access
  for select to authenticated using (public.is_admin());

create policy "admins suivent l'accès anticipé" on public.early_access
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- Les visiteurs n'ont que l'insertion.
revoke all on public.early_access from anon;
grant insert (nom, whatsapp, consent, source) on public.early_access to anon;
