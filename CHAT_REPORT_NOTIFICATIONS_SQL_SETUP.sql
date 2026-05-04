-- Chat report/block + notifications setup for Afghan Deals Pro.
-- Safe to run multiple times in Supabase SQL Editor.

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  title text not null default 'Report',
  type text not null default 'listing',
  target_id text,
  target_title text,
  reason text not null,
  description text,
  reported_by text,
  priority text not null default 'medium',
  status text not null default 'open',
  created_at timestamptz not null default now()
);

alter table public.reports add column if not exists title text not null default 'Report';
alter table public.reports alter column title set default 'Report';
update public.reports set title = 'Report' where title is null;
alter table public.reports alter column title drop not null;
alter table public.reports add column if not exists type text not null default 'listing';
alter table public.reports add column if not exists target_id text;
alter table public.reports add column if not exists target_title text;
alter table public.reports add column if not exists reason text not null default 'Report';
alter table public.reports add column if not exists description text;
alter table public.reports add column if not exists reported_by text;
alter table public.reports add column if not exists priority text not null default 'medium';
alter table public.reports add column if not exists status text not null default 'open';
alter table public.reports add column if not exists created_at timestamptz not null default now();

create index if not exists reports_status_idx on public.reports (status);
create index if not exists reports_created_idx on public.reports (created_at desc);

alter table public.reports enable row level security;

drop policy if exists "reports_insert_authenticated" on public.reports;
create policy "reports_insert_authenticated"
on public.reports for insert
to authenticated
with check (true);

drop policy if exists "reports_read_authenticated" on public.reports;
create policy "reports_read_authenticated"
on public.reports for select
to authenticated
using (true);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null,
  title text not null,
  subtitle text not null,
  icon_type text not null default 'message',
  is_read boolean not null default false,
  action_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_notifications_user_id on public.notifications(user_id);
create index if not exists idx_notifications_user_created on public.notifications(user_id, created_at desc);
create index if not exists idx_notifications_is_read on public.notifications(user_id, is_read);

alter table public.notifications enable row level security;

drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own"
on public.notifications for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "notifications_insert_own" on public.notifications;
create policy "notifications_insert_own"
on public.notifications for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own"
on public.notifications for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create table if not exists public.blocked_users (
  id uuid primary key default gen_random_uuid(),
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  chat_id uuid null,
  created_at timestamptz not null default now(),
  unique (blocker_id, blocked_id)
);

create index if not exists blocked_users_blocker_idx on public.blocked_users (blocker_id);
create index if not exists blocked_users_blocked_idx on public.blocked_users (blocked_id);

alter table public.blocked_users enable row level security;

drop policy if exists "blocked_users_select_own" on public.blocked_users;
create policy "blocked_users_select_own"
on public.blocked_users for select
to authenticated
using (auth.uid() = blocker_id or auth.uid() = blocked_id);

drop policy if exists "blocked_users_insert_own" on public.blocked_users;
create policy "blocked_users_insert_own"
on public.blocked_users for insert
to authenticated
with check (auth.uid() = blocker_id);

drop policy if exists "blocked_users_delete_own" on public.blocked_users;
create policy "blocked_users_delete_own"
on public.blocked_users for delete
to authenticated
using (auth.uid() = blocker_id);
