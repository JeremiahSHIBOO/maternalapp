-- Run this in the Supabase SQL editor before starting the mobile app.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role text not null default 'mother' check (role in ('mother', 'partner', 'doctor')),
  created_at timestamptz not null default now()
);

create table if not exists public.pregnancy_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  lmp_date date,
  edd_date date,
  pregnancy_type text not null default 'single' check (pregnancy_type in ('single', 'twin', 'multiple')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.daily_check_ins (
  id uuid primary key default gen_random_uuid(),
  mother_profile_id uuid not null references public.pregnancy_profiles(id) on delete cascade,
  check_in_date timestamptz not null default now(),
  sleep_duration_hours numeric(4,1) check (sleep_duration_hours between 0 and 24),
  sleep_quality integer check (sleep_quality between 1 and 10),
  mood integer check (mood between 1 and 10),
  energy integer check (energy between 1 and 10),
  stress integer check (stress between 1 and 10),
  hydration_status text check (hydration_status in ('poor', 'fair', 'good', 'excellent')),
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.symptom_logs (
  id uuid primary key default gen_random_uuid(),
  mother_profile_id uuid not null references public.pregnancy_profiles(id) on delete cascade,
  symptom_name text not null,
  severity integer not null check (severity between 1 and 10),
  log_date timestamptz not null default now(),
  notes text,
  created_at timestamptz not null default now()
);

create or replace function public.create_user_profile()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.create_user_profile();

alter table public.profiles enable row level security;
alter table public.pregnancy_profiles enable row level security;
alter table public.daily_check_ins enable row level security;
alter table public.symptom_logs enable row level security;

drop policy if exists "Users read own profile" on public.profiles;
create policy "Users read own profile" on public.profiles for select using (id = auth.uid());
drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile" on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "Users manage own pregnancy profile" on public.pregnancy_profiles;
create policy "Users manage own pregnancy profile" on public.pregnancy_profiles for all
using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "Users manage own check-ins" on public.daily_check_ins;
create policy "Users manage own check-ins" on public.daily_check_ins for all
using (exists (select 1 from public.pregnancy_profiles p where p.id = mother_profile_id and p.user_id = auth.uid()))
with check (exists (select 1 from public.pregnancy_profiles p where p.id = mother_profile_id and p.user_id = auth.uid()));

drop policy if exists "Users manage own symptom logs" on public.symptom_logs;
create policy "Users manage own symptom logs" on public.symptom_logs for all
using (exists (select 1 from public.pregnancy_profiles p where p.id = mother_profile_id and p.user_id = auth.uid()))
with check (exists (select 1 from public.pregnancy_profiles p where p.id = mother_profile_id and p.user_id = auth.uid()));
