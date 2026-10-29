-- ═══════════════════════════════════════════════════════════════════════
-- Eventa · champs utilisés par l'app pour les événements, le budget et les
-- tâches. Sans risque, peut être relancé.
-- SQL Editor → New query → coller tout le fichier → Run.
-- ═══════════════════════════════════════════════════════════════════════

alter table public.events add column if not exists city text not null default '';
alter table public.events add column if not exists subtitle text;
alter table public.events add column if not exists subcategories text[] not null default '{}';

-- Un poste de budget par catégorie et par événement.
alter table public.budget_lines add column if not exists paid bigint not null default 0;
alter table public.budget_lines add column if not exists note text;
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'budget_lines_event_category_key'
  ) then
    alter table public.budget_lines
      add constraint budget_lines_event_category_key unique (event_id, category);
  end if;
end;
$$;

alter table public.tasks add column if not exists urgent boolean not null default false;
alter table public.tasks add column if not exists duration_min int not null default 30;

-- Contrôle : doit afficher 7 lignes.
select table_name, column_name
from information_schema.columns
where table_schema = 'public'
  and (table_name, column_name) in (
    ('events', 'city'), ('events', 'subtitle'), ('events', 'subcategories'),
    ('budget_lines', 'paid'), ('budget_lines', 'note'),
    ('tasks', 'urgent'), ('tasks', 'duration_min')
  )
order by 1, 2;
