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

-- Firebase-authenticated users have a Firebase UID in the JWT subject and a
-- separate UUID primary key in public.profiles. The caller may only delete the
-- profile mapped to their own verified JWT subject.
create or replace function public.delete_my_account_firebase()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_firebase_uid text := nullif(auth.jwt() ->> 'sub', '');
  profile_uid uuid;
begin
  if v_firebase_uid is null then
    raise exception 'Not authenticated';
  end if;

  select id into profile_uid
  from public.profiles
  where profiles.firebase_uid = v_firebase_uid
  limit 1;

  if profile_uid is null then
    raise exception 'Profile not found';
  end if;

  delete from public.favorites where user_id = profile_uid;
  delete from public.blocked_users
    where blocker_id = profile_uid or blocked_id = profile_uid;
  delete from public.chat_messages where sender_id = profile_uid;
  delete from public.chat_participants where user_id = profile_uid;
  delete from public.reports
    where reported_by = profile_uid or target_id = profile_uid;
  delete from public.notifications where user_id = profile_uid;
  delete from public.listings where seller_id = profile_uid;
  delete from public.profiles
    where id = profile_uid and profiles.firebase_uid = v_firebase_uid;
end;
$$;

revoke all on function public.delete_my_account_firebase() from public;
grant execute on function public.delete_my_account_firebase() to authenticated;
