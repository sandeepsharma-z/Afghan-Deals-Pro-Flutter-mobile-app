-- Favorites table for Afghan Deals Pro (Supabase)
-- Run this once in Supabase SQL Editor.

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

create table if not exists public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  listing_id text not null,
  created_at timestamptz not null default now(),
  constraint favorites_unique_user_listing unique (user_id, listing_id)
);

alter table if exists public.favorites
  drop constraint if exists favorites_user_id_fkey;

alter table if exists public.favorites
  add constraint favorites_user_id_fkey
    foreign key (user_id) references public.profiles(id) on delete cascade;

create index if not exists favorites_user_id_idx on public.favorites (user_id);
create index if not exists favorites_listing_id_idx on public.favorites (listing_id);

alter table public.favorites enable row level security;

drop policy if exists favorites_select_own on public.favorites;
create policy favorites_select_own
on public.favorites
for select
to authenticated
using (public.current_profile_id() = user_id);

drop policy if exists favorites_insert_own on public.favorites;
create policy favorites_insert_own
on public.favorites
for insert
to authenticated
with check (public.current_profile_id() = user_id);

drop policy if exists favorites_delete_own on public.favorites;
create policy favorites_delete_own
on public.favorites
for delete
to authenticated
using (public.current_profile_id() = user_id);
