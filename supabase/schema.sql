-- Vivace : base de données des groupes famille
-- À coller une seule fois dans Supabase > SQL Editor > New query, puis "Run".
--
-- Principe de sécurité : les tables ne sont jamais accessibles directement.
-- L'application passe uniquement par les fonctions ci-dessous. Le code de groupe
-- (8 caractères, environ 850 milliards de combinaisons) sert de clé d'accès.

create extension if not exists pgcrypto;

create table if not exists public.families (
  code        text primary key,
  name        text not null check (char_length(name) between 1 and 40),
  created_at  timestamptz not null default now()
);

create table if not exists public.members (
  id           uuid primary key,
  family_code  text not null references public.families(code) on delete cascade,
  name         text not null check (char_length(name) between 1 and 40),
  created_at   timestamptz not null default now()
);

create table if not exists public.results (
  id          bigint generated always as identity primary key,
  member_id   uuid not null references public.members(id) on delete cascade,
  game        text not null check (game in ('ufov','corsi','switch','list')),
  score       integer not null check (score between 0 and 100000),
  day         date not null,
  created_at  timestamptz not null default now()
);

create index if not exists results_member_day on public.results(member_id, day);
create index if not exists members_family on public.members(family_code);

-- Aucun accès direct aux tables
alter table public.families enable row level security;
alter table public.members  enable row level security;
alter table public.results  enable row level security;
revoke all on public.families, public.members, public.results from anon, authenticated;

-- Créer un groupe : renvoie le code à partager
create or replace function public.vivace_create_family(p_name text)
returns text language plpgsql security definer set search_path = public, extensions as $$
declare
  alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  c text;
  i int;
begin
  p_name := trim(p_name);
  if char_length(p_name) not between 1 and 40 then raise exception 'nom de groupe invalide'; end if;
  loop
    c := '';
    for i in 1..8 loop
      c := c || substr(alphabet, 1 + (get_byte(gen_random_bytes(1), 0) % 31), 1);
    end loop;
    exit when not exists (select 1 from families where code = c);
  end loop;
  insert into families(code, name) values (c, p_name);
  return c;
end $$;

-- Rejoindre un groupe : renvoie le nom du groupe
create or replace function public.vivace_join(p_code text, p_member uuid, p_name text)
returns text language plpgsql security definer set search_path = public as $$
declare g text;
begin
  p_name := trim(p_name);
  if char_length(p_name) not between 1 and 40 then raise exception 'prenom invalide'; end if;
  select name into g from families where code = upper(p_code);
  if g is null then raise exception 'groupe introuvable'; end if;
  insert into members(id, family_code, name) values (p_member, upper(p_code), p_name)
  on conflict (id) do update set family_code = excluded.family_code, name = excluded.name;
  return g;
end $$;

-- Enregistrer un résultat
create or replace function public.vivace_add(p_code text, p_member uuid, p_game text, p_score int, p_day date)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from members where id = p_member and family_code = upper(p_code)) then
    raise exception 'membre introuvable';
  end if;
  if p_day > current_date + 1 or p_day < current_date - 400 then raise exception 'date invalide'; end if;
  insert into results(member_id, game, score, day) values (p_member, p_game, p_score, p_day);
end $$;

-- Lire les résultats du groupe (120 derniers jours).
-- Les identifiants des membres ne sont jamais renvoyés, seulement une empreinte.
create or replace function public.vivace_family(p_code text, p_member uuid)
returns table(mkey text, name text, is_me boolean, game text, score int, day date)
language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from members m where m.id = p_member and m.family_code = upper(p_code)) then
    raise exception 'membre introuvable';
  end if;
  return query
    select md5(m.id::text), m.name, m.id = p_member, r.game, r.score, r.day
    from members m
    left join results r on r.member_id = m.id and r.day >= current_date - 120
    where m.family_code = upper(p_code)
    order by m.name, r.day, r.created_at;
end $$;

-- Quitter un groupe : efface le membre et tous ses résultats
create or replace function public.vivace_leave(p_code text, p_member uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  delete from members where id = p_member and family_code = upper(p_code);
end $$;

revoke all on function public.vivace_create_family(text) from public;
revoke all on function public.vivace_join(text, uuid, text) from public;
revoke all on function public.vivace_add(text, uuid, text, int, date) from public;
revoke all on function public.vivace_family(text, uuid) from public;
revoke all on function public.vivace_leave(text, uuid) from public;
grant execute on function public.vivace_create_family(text) to anon, authenticated;
grant execute on function public.vivace_join(text, uuid, text) to anon, authenticated;
grant execute on function public.vivace_add(text, uuid, text, int, date) to anon, authenticated;
grant execute on function public.vivace_family(text, uuid) to anon, authenticated;
grant execute on function public.vivace_leave(text, uuid) to anon, authenticated;

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
-- Supabase > SQL Editor > New query > coller > Run
create or replace function public.vivace_backup_delete(p_code text)
returns void language plpgsql security definer set search_path = public as $$
begin
  delete from backups where code = upper(p_code);
end $$;
revoke all on function public.vivace_backup_delete(text) from public;
grant execute on function public.vivace_backup_delete(text) to anon, authenticated;

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
