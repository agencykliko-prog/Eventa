-- Profil choisi à l'inscription : organisateur ou prestataire.
-- Nullable : les inscriptions antérieures n'ont pas ce champ.
alter table public.early_access
  add column profil text check (profil in ('organisateur', 'prestataire'));

grant insert (profil) on public.early_access to anon;
