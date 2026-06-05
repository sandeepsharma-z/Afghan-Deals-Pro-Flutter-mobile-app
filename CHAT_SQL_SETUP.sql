-- Chat tables for Afghan Deals Pro (Supabase)
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

create table if not exists public.chats (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings(id) on delete cascade,
  buyer_id uuid not null references public.profiles(id) on delete cascade,
  seller_id uuid not null references public.profiles(id) on delete cascade,
  last_message text not null default '',
  last_message_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint chats_unique_listing_pair unique (listing_id, buyer_id, seller_id)
);

-- Keep existing projects compatible when table already exists with older schema.
alter table if exists public.chats
  add column if not exists last_message text not null default '',
  add column if not exists last_message_at timestamptz not null default now(),
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

alter table if exists public.chats
  drop constraint if exists chats_buyer_id_fkey,
  drop constraint if exists chats_seller_id_fkey;

alter table if exists public.chats
  add constraint chats_buyer_id_fkey
    foreign key (buyer_id) references public.profiles(id) on delete cascade,
  add constraint chats_seller_id_fkey
    foreign key (seller_id) references public.profiles(id) on delete cascade;

create index if not exists chats_buyer_idx on public.chats (buyer_id);
create index if not exists chats_seller_idx on public.chats (seller_id);
create index if not exists chats_last_message_at_idx on public.chats (last_message_at desc);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  text text not null check (char_length(trim(text)) > 0),
  created_at timestamptz not null default now()
);

alter table if exists public.chat_messages
  add column if not exists created_at timestamptz not null default now();

alter table if exists public.chat_messages
  drop constraint if exists chat_messages_sender_id_fkey;

alter table if exists public.chat_messages
  add constraint chat_messages_sender_id_fkey
    foreign key (sender_id) references public.profiles(id) on delete cascade;

create index if not exists chat_messages_chat_id_idx on public.chat_messages (chat_id, created_at asc);

create or replace function public.touch_chats_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_touch_chats_updated_at on public.chats;
create trigger trg_touch_chats_updated_at
before update on public.chats
for each row execute function public.touch_chats_updated_at();

alter table public.chats enable row level security;
alter table public.chat_messages enable row level security;

drop policy if exists chats_select_participants on public.chats;
create policy chats_select_participants
on public.chats
for select
to authenticated
using (
  public.current_profile_id() = buyer_id
  or public.current_profile_id() = seller_id
);

drop policy if exists chats_insert_buyer_only on public.chats;
create policy chats_insert_buyer_only
on public.chats
for insert
to authenticated
with check (public.current_profile_id() = buyer_id);

drop policy if exists chats_update_participants on public.chats;
create policy chats_update_participants
on public.chats
for update
to authenticated
using (
  public.current_profile_id() = buyer_id
  or public.current_profile_id() = seller_id
)
with check (
  public.current_profile_id() = buyer_id
  or public.current_profile_id() = seller_id
);

drop policy if exists chat_messages_select_participants on public.chat_messages;
create policy chat_messages_select_participants
on public.chat_messages
for select
to authenticated
using (
  exists (
    select 1
    from public.chats c
    where c.id = chat_messages.chat_id
      and (
        c.buyer_id = public.current_profile_id()
        or c.seller_id = public.current_profile_id()
      )
  )
);

drop policy if exists chat_messages_insert_sender_participant on public.chat_messages;
create policy chat_messages_insert_sender_participant
on public.chat_messages
for insert
to authenticated
with check (
  public.current_profile_id() = sender_id
  and exists (
    select 1
    from public.chats c
    where c.id = chat_messages.chat_id
      and (
        c.buyer_id = public.current_profile_id()
        or c.seller_id = public.current_profile_id()
      )
  )
);
