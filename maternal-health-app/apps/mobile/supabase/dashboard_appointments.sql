-- Run this file in the Supabase SQL Editor to enable appointment tracking.
create extension if not exists pgcrypto;

create table if not exists public.care_appointments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  starts_at timestamptz not null,
  clinician text,
  location text,
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists care_appointments_user_starts_at_idx
  on public.care_appointments (user_id, starts_at);

alter table public.care_appointments enable row level security;

drop policy if exists "Users manage own care appointments" on public.care_appointments;
create policy "Users manage own care appointments"
  on public.care_appointments
  for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

grant select, insert, update, delete on public.care_appointments to authenticated;
