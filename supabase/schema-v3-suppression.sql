-- Hibi : droit à l'effacement de la sauvegarde personnelle (à exécuter une fois)
-- Supabase > SQL Editor > New query > coller > Run
create or replace function public.vivace_backup_delete(p_code text)
returns void language plpgsql security definer set search_path = public as $$
begin
  delete from backups where code = upper(p_code);
end $$;
revoke all on function public.vivace_backup_delete(text) from public;
grant execute on function public.vivace_backup_delete(text) to anon, authenticated;
