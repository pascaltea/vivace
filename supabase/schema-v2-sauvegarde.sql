-- Hibi : sauvegarde personnelle des résultats (à exécuter une fois, après schema.sql)
-- Supabase > SQL Editor > New query > coller > Run

create table if not exists public.backups (
  code        text primary key check (code ~ '^[A-Z0-9]{12}$'),
  data        jsonb not null,
  updated_at  timestamptz not null default now()
);
alter table public.backups enable row level security;
revoke all on public.backups from anon, authenticated;

-- Enregistrer (ou remplacer) la sauvegarde liée à un code
create or replace function public.vivace_backup_save(p_code text, p_data jsonb)
returns timestamptz language plpgsql security definer set search_path = public as $$
begin
  if p_code !~ '^[A-Z0-9]{12}$' then raise exception 'code invalide'; end if;
  if pg_column_size(p_data) > 400000 then raise exception 'sauvegarde trop volumineuse'; end if;
  insert into backups(code, data, updated_at) values (p_code, p_data, now())
  on conflict (code) do update set data = excluded.data, updated_at = now();
  return now();
end $$;

-- Lire la sauvegarde liée à un code
create or replace function public.vivace_backup_load(p_code text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare d jsonb;
begin
  select data into d from backups where code = upper(p_code);
  if d is null then raise exception 'sauvegarde introuvable'; end if;
  return d;
end $$;

revoke all on function public.vivace_backup_save(text, jsonb) from public;
revoke all on function public.vivace_backup_load(text) from public;
grant execute on function public.vivace_backup_save(text, jsonb) to anon, authenticated;
grant execute on function public.vivace_backup_load(text) to anon, authenticated;
