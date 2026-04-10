-- Chat tables for Afghan Deals Pro (Supabase)
-- Run this once in Supabase SQL Editor.

create table if not exists public.chats (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings(id) on delete cascade,
  buyer_id uuid not null references auth.users(id) on delete cascade,
  seller_id uuid not null references auth.users(id) on delete cascade,
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

create index if not exists chats_buyer_idx on public.chats (buyer_id);
create index if not exists chats_seller_idx on public.chats (seller_id);
create index if not exists chats_last_message_at_idx on public.chats (last_message_at desc);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  text text not null check (char_length(trim(text)) > 0),
  created_at timestamptz not null default now()
);

alter table if exists public.chat_messages
  add column if not exists created_at timestamptz not null default now();

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
using (auth.uid() = buyer_id or auth.uid() = seller_id);

drop policy if exists chats_insert_buyer_only on public.chats;
create policy chats_insert_buyer_only
on public.chats
for insert
to authenticated
with check (auth.uid() = buyer_id);

drop policy if exists chats_update_participants on public.chats;
create policy chats_update_participants
on public.chats
for update
to authenticated
using (auth.uid() = buyer_id or auth.uid() = seller_id)
with check (auth.uid() = buyer_id or auth.uid() = seller_id);

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
      and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())
  )
);

drop policy if exists chat_messages_insert_sender_participant on public.chat_messages;
create policy chat_messages_insert_sender_participant
on public.chat_messages
for insert
to authenticated
with check (
  auth.uid() = sender_id
  and exists (
    select 1
    from public.chats c
    where c.id = chat_messages.chat_id
      and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())
  )
);
