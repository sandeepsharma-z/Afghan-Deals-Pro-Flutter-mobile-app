-- Account settings support for Afghan Deals Pro.
-- Run this in Supabase SQL Editor.

alter table public.profiles
add column if not exists is_active boolean not null default true,
add column if not exists deactivated_at timestamptz null;

create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  delete from public.favorites where user_id = uid;
  delete from public.blocked_users where blocker_id = uid or blocked_id = uid;
  delete from public.chat_messages where sender_id = uid;
  delete from public.chat_participants where user_id = uid;
  delete from public.reports where reported_by = uid or target_id = uid;
  delete from public.notifications where user_id = uid;
  delete from public.listings where seller_id = uid;
  delete from public.profiles where id = uid;
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_my_account() from public;
grant execute on function public.delete_my_account() to authenticated;
