-- Direct user blocking for Afghan Deals Pro chat.
-- Run this in Supabase SQL Editor.

create or replace function public.current_profile_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select p.id
  from public.profiles p
  where p.id::text = coalesce(auth.jwt()->>'sub', auth.uid()::text)
     or p.firebase_uid = coalesce(auth.jwt()->>'sub', auth.uid()::text)
     or (
       coalesce(auth.jwt()->>'email', '') <> ''
       and lower(coalesce(p.email, '')) = lower(auth.jwt()->>'email')
     )
     or (
       coalesce(auth.jwt()->>'phone_number', '') <> ''
       and regexp_replace(coalesce(p.phone, ''), '[^0-9]', '', 'g') =
           regexp_replace(auth.jwt()->>'phone_number', '[^0-9]', '', 'g')
     )
  order by case
    when p.id::text = coalesce(auth.jwt()->>'sub', auth.uid()::text) then 0
    when p.firebase_uid = coalesce(auth.jwt()->>'sub', auth.uid()::text) then 1
    when coalesce(auth.jwt()->>'email', '') <> ''
      and lower(coalesce(p.email, '')) = lower(auth.jwt()->>'email') then 2
    when coalesce(auth.jwt()->>'phone_number', '') <> ''
      and regexp_replace(coalesce(p.phone, ''), '[^0-9]', '', 'g') =
          regexp_replace(auth.jwt()->>'phone_number', '[^0-9]', '', 'g') then 3
    else 9
  end
  limit 1
$$;

revoke all on function public.current_profile_id() from public;
grant execute on function public.current_profile_id() to authenticated;

create table if not exists public.blocked_users (
  id uuid primary key default gen_random_uuid(),
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  chat_id uuid null,
  created_at timestamptz not null default now(),
  unique (blocker_id, blocked_id)
);

alter table if exists public.blocked_users
  drop constraint if exists blocked_users_blocker_id_fkey,
  drop constraint if exists blocked_users_blocked_id_fkey;

alter table if exists public.blocked_users
  add constraint blocked_users_blocker_id_fkey
    foreign key (blocker_id) references public.profiles(id) on delete cascade,
  add constraint blocked_users_blocked_id_fkey
    foreign key (blocked_id) references public.profiles(id) on delete cascade;

create index if not exists blocked_users_blocker_idx
  on public.blocked_users (blocker_id);

create index if not exists blocked_users_blocked_idx
  on public.blocked_users (blocked_id);

alter table public.blocked_users enable row level security;

drop policy if exists "blocked_users_select_own" on public.blocked_users;
create policy "blocked_users_select_own"
on public.blocked_users for select
using (
  public.current_profile_id() = blocker_id
  or public.current_profile_id() = blocked_id
);

drop policy if exists "blocked_users_insert_own" on public.blocked_users;
create policy "blocked_users_insert_own"
on public.blocked_users for insert
with check (public.current_profile_id() = blocker_id);

drop policy if exists "blocked_users_delete_own" on public.blocked_users;
create policy "blocked_users_delete_own"
on public.blocked_users for delete
using (public.current_profile_id() = blocker_id);
