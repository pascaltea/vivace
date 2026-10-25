-- Hibi v4 : comptes (connexion par code reçu par e-mail)
-- Supabase > SQL Editor > New query > coller > Run. Peut être relancé sans risque.
--
-- Une ligne par compte, lisible et modifiable uniquement par son propriétaire
-- (Row Level Security sur auth.uid()). Supprimer le compte efface la ligne.

create table if not exists public.user_data (
  user_id     uuid primary key references auth.users(id) on delete cascade,
  data        jsonb not null,
  updated_at  timestamptz not null default now(),
  constraint user_data_size check (pg_column_size(data) < 500000)
);

alter table public.user_data enable row level security;
revoke all on public.user_data from anon;
grant select, insert, update, delete on public.user_data to authenticated;

drop policy if exists "lire ses donnees" on public.user_data;
drop policy if exists "creer ses donnees" on public.user_data;
drop policy if exists "modifier ses donnees" on public.user_data;
drop policy if exists "effacer ses donnees" on public.user_data;
create policy "lire ses donnees" on public.user_data for select to authenticated
  using (user_id = (select auth.uid()));
create policy "creer ses donnees" on public.user_data for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy "modifier ses donnees" on public.user_data for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "effacer ses donnees" on public.user_data for delete to authenticated
  using (user_id = (select auth.uid()));

-- Supprimer son compte (et donc ses données) depuis l'app
create or replace function public.vivace_account_delete()
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'non connecte'; end if;
  delete from auth.users where id = auth.uid();
end $$;
revoke all on function public.vivace_account_delete() from public, anon;
grant execute on function public.vivace_account_delete() to authenticated;
