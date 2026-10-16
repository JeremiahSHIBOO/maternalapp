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
  bp_systolic_mmhg integer,
  bp_diastolic_mmhg integer,
  heart_rate_bpm integer,
  hrv_ms numeric(6,1),
  spo2_percent numeric(4,1),
  respiratory_rate_per_min integer,
  skin_temperature_c numeric(4,1),
  weight_kg numeric(5,1),
  steps_count integer,
  measurement_source text not null default 'manual',
  notes text,
  created_at timestamptz not null default now()
);

-- Add nullable manual-measurement columns to existing installations without
-- removing or rewriting prior check-in records.
alter table public.daily_check_ins
  add column if not exists bp_systolic_mmhg integer,
  add column if not exists bp_diastolic_mmhg integer,
  add column if not exists heart_rate_bpm integer,
  add column if not exists hrv_ms numeric(6,1),
  add column if not exists spo2_percent numeric(4,1),
  add column if not exists respiratory_rate_per_min integer,
  add column if not exists skin_temperature_c numeric(4,1),
  add column if not exists weight_kg numeric(5,1),
  add column if not exists steps_count integer,
  add column if not exists measurement_source text not null default 'manual';

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'daily_check_ins_bp_systolic_range' and conrelid = 'public.daily_check_ins'::regclass) then
    alter table public.daily_check_ins add constraint daily_check_ins_bp_systolic_range
      check (bp_systolic_mmhg between 1 and 300);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'daily_check_ins_bp_diastolic_range' and conrelid = 'public.daily_check_ins'::regclass) then
    alter table public.daily_check_ins add constraint daily_check_ins_bp_diastolic_range
      check (bp_diastolic_mmhg between 1 and 200);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'daily_check_ins_bp_pair' and conrelid = 'public.daily_check_ins'::regclass) then
    alter table public.daily_check_ins add constraint daily_check_ins_bp_pair
      check ((bp_systolic_mmhg is null and bp_diastolic_mmhg is null) or
        (bp_systolic_mmhg is not null and bp_diastolic_mmhg is not null and
         bp_systolic_mmhg > bp_diastolic_mmhg));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'daily_check_ins_heart_rate_range' and conrelid = 'public.daily_check_ins'::regclass) then
    alter table public.daily_check_ins add constraint daily_check_ins_heart_rate_range
      check (heart_rate_bpm between 20 and 240);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'daily_check_ins_hrv_range' and conrelid = 'public.daily_check_ins'::regclass) then
    alter table public.daily_check_ins add constraint daily_check_ins_hrv_range
      check (hrv_ms between 0 and 500);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'daily_check_ins_spo2_range' and conrelid = 'public.daily_check_ins'::regclass) then
    alter table public.daily_check_ins add constraint daily_check_ins_spo2_range
      check (spo2_percent between 50 and 100);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'daily_check_ins_respiratory_rate_range' and conrelid = 'public.daily_check_ins'::regclass) then
    alter table public.daily_check_ins add constraint daily_check_ins_respiratory_rate_range
      check (respiratory_rate_per_min between 4 and 80);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'daily_check_ins_skin_temperature_range' and conrelid = 'public.daily_check_ins'::regclass) then
    alter table public.daily_check_ins add constraint daily_check_ins_skin_temperature_range
      check (skin_temperature_c between 20 and 45);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'daily_check_ins_weight_range' and conrelid = 'public.daily_check_ins'::regclass) then
    alter table public.daily_check_ins add constraint daily_check_ins_weight_range
      check (weight_kg between 20 and 300);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'daily_check_ins_steps_range' and conrelid = 'public.daily_check_ins'::regclass) then
    alter table public.daily_check_ins add constraint daily_check_ins_steps_range
      check (steps_count between 0 and 200000);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'daily_check_ins_measurement_source' and conrelid = 'public.daily_check_ins'::regclass) then
    alter table public.daily_check_ins add constraint daily_check_ins_measurement_source
      check (measurement_source in ('manual', 'wearable', 'blood_pressure_cuff', 'home_device', 'clinic', 'multiple', 'other'));
  end if;
end $$;

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

-- Mother-controlled partner connection, selective sharing, and private chat.
begin;

create table if not exists public.caregiver_connections (
  id uuid primary key default gen_random_uuid(),
  mother_profile_id uuid not null unique references public.pregnancy_profiles(id) on delete cascade,
  mother_user_id uuid not null references public.profiles(id) on delete cascade,
  partner_user_id uuid not null unique references public.profiles(id) on delete cascade,
  partner_email text not null,
  share_preferences jsonb not null default '{
    "pregnancy_progress": false,
    "daily_wellbeing": false,
    "symptoms": false,
    "measurements": false
  }'::jsonb,
  created_at timestamptz not null default now(),
  check (mother_user_id <> partner_user_id),
  check (jsonb_typeof(share_preferences) = 'object')
);

create unique index if not exists caregiver_connections_partner_user_id_key
  on public.caregiver_connections (partner_user_id);

create table if not exists public.care_messages (
  id uuid primary key default gen_random_uuid(),
  connection_id uuid not null references public.caregiver_connections(id) on delete cascade,
  sender_user_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(trim(body)) between 1 and 2000),
  sent_at timestamptz not null default now()
);

alter table public.caregiver_connections enable row level security;
alter table public.care_messages enable row level security;

drop policy if exists "Participants read caregiver connection" on public.caregiver_connections;
create policy "Participants read caregiver connection" on public.caregiver_connections
for select to authenticated using (
  mother_user_id = auth.uid() or partner_user_id = auth.uid()
);
drop policy if exists "Mother updates sharing choices" on public.caregiver_connections;
create policy "Mother updates sharing choices" on public.caregiver_connections
for update to authenticated using (mother_user_id = auth.uid())
with check (mother_user_id = auth.uid());

drop policy if exists "Participants read care messages" on public.care_messages;
create policy "Participants read care messages" on public.care_messages
for select to authenticated using (exists (
  select 1 from public.caregiver_connections c
  where c.id = care_messages.connection_id
    and (c.mother_user_id = auth.uid() or c.partner_user_id = auth.uid())
));
drop policy if exists "Participants send care messages" on public.care_messages;
create policy "Participants send care messages" on public.care_messages
for insert to authenticated with check (
  sender_user_id = auth.uid() and exists (
    select 1 from public.caregiver_connections c
    where c.id = care_messages.connection_id
      and (c.mother_user_id = auth.uid() or c.partner_user_id = auth.uid())
  )
);

revoke all on public.caregiver_connections from public, anon;
revoke insert, delete, update on public.caregiver_connections from authenticated;
grant select on public.caregiver_connections to authenticated;
grant update (share_preferences) on public.caregiver_connections to authenticated;
revoke all on public.care_messages from public, anon;
revoke insert, update, delete on public.care_messages from authenticated;
grant select on public.care_messages to authenticated;
grant insert (connection_id, sender_user_id, body)
  on public.care_messages to authenticated;

create or replace function public.connect_partner_by_email(p_partner_email text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mother_user_id uuid := auth.uid();
  v_mother_profile_id uuid;
  v_partner_user_id uuid;
  v_existing_partner_user_id uuid;
  v_connection_id uuid;
begin
  if v_mother_user_id is null then
    raise exception 'Sign in before connecting a partner';
  end if;
  if not exists (
    select 1 from public.profiles
    where id = v_mother_user_id and role = 'mother'
  ) then
    raise exception 'Only a Mother account can connect a Partner from this screen';
  end if;
  if nullif(trim(p_partner_email), '') is null then
    raise exception 'Enter the partner email address';
  end if;
  if exists (
    select 1 from auth.users
    where id = v_mother_user_id
      and lower(email) = lower(trim(p_partner_email))
  ) then
    raise exception 'Use your Partner account email rather than your own';
  end if;

  select id into v_mother_profile_id
  from public.pregnancy_profiles where user_id = v_mother_user_id;
  if v_mother_profile_id is null then
    raise exception 'Set up your pregnancy profile before connecting a partner';
  end if;

  select u.id into v_partner_user_id
  from auth.users u
  join public.profiles p on p.id = u.id
  where lower(u.email) = lower(trim(p_partner_email))
    and p.role = 'partner'
  limit 1;
  if v_partner_user_id is null then
    raise exception 'No Partner account was found for this email. Ask them to create an account and choose Partner first.';
  end if;
  if v_partner_user_id = v_mother_user_id then
    raise exception 'Use a different email for your partner';
  end if;

  select id, partner_user_id
    into v_connection_id, v_existing_partner_user_id
  from public.caregiver_connections
  where mother_profile_id = v_mother_profile_id;
  if v_connection_id is not null then
    if v_existing_partner_user_id <> v_partner_user_id then
      raise exception 'A different partner is already connected. Disconnect them before changing access.';
    end if;
    return v_connection_id;
  end if;

  if exists (
    select 1 from public.caregiver_connections
    where partner_user_id = v_partner_user_id
  ) then
    raise exception 'That Partner account is already connected. Disconnect the existing connection before linking a different Mother.';
  end if;

  insert into public.caregiver_connections
    (mother_profile_id, mother_user_id, partner_user_id, partner_email)
  values
    (v_mother_profile_id, v_mother_user_id, v_partner_user_id,
     lower(trim(p_partner_email)))
  on conflict do nothing
  returning id into v_connection_id;

  -- A concurrent click may have created the link after the earlier read.
  -- Return the same link without resetting consent or replacing a partner.
  if v_connection_id is null then
    select id, partner_user_id
      into v_connection_id, v_existing_partner_user_id
    from public.caregiver_connections
    where mother_profile_id = v_mother_profile_id;
    if v_connection_id is null or v_existing_partner_user_id <> v_partner_user_id then
      raise exception 'One of these accounts already has a different connection. Refresh before changing access.';
    end if;
  end if;
  return v_connection_id;
end;
$$;

create or replace function public.get_partner_shared_data(p_connection_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_mother_profile_id uuid;
  v_preferences jsonb;
  v_data jsonb := '{}'::jsonb;
begin
  select mother_profile_id, share_preferences
    into v_mother_profile_id, v_preferences
  from public.caregiver_connections
  where id = p_connection_id
    and partner_user_id = auth.uid();
  if v_mother_profile_id is null then
    raise exception 'This partner connection is unavailable';
  end if;

  if coalesce((v_preferences ->> 'pregnancy_progress')::boolean, false) then
    select v_data || jsonb_build_object('pregnancy_progress', jsonb_build_object(
        'lmp_date', lmp_date,
        'edd_date', coalesce(edd_date, lmp_date + 280)
      )) into v_data
    from public.pregnancy_profiles where id = v_mother_profile_id;
  end if;

  if coalesce((v_preferences ->> 'daily_wellbeing')::boolean, false) then
    v_data := v_data || jsonb_build_object('daily_wellbeing', coalesce((
      select jsonb_agg(to_jsonb(entry)) from (
        select check_in_date, sleep_duration_hours, sleep_quality, mood,
               energy, stress, hydration_status
        from public.daily_check_ins
        where mother_profile_id = v_mother_profile_id
        order by check_in_date desc limit 7
      ) as entry
    ), '[]'::jsonb));
  end if;

  if coalesce((v_preferences ->> 'symptoms')::boolean, false) then
    v_data := v_data || jsonb_build_object('symptoms', coalesce((
      select jsonb_agg(to_jsonb(entry)) from (
        select symptom_name, severity, log_date
        from public.symptom_logs
        where mother_profile_id = v_mother_profile_id
        order by log_date desc limit 10
      ) as entry
    ), '[]'::jsonb));
  end if;

  if coalesce((v_preferences ->> 'measurements')::boolean, false) then
    v_data := v_data || jsonb_build_object('measurements', coalesce((
      select jsonb_agg(to_jsonb(entry)) from (
        select check_in_date, bp_systolic_mmhg, bp_diastolic_mmhg,
               heart_rate_bpm, hrv_ms, spo2_percent,
               respiratory_rate_per_min, skin_temperature_c, weight_kg,
               steps_count, measurement_source
        from public.daily_check_ins
        where mother_profile_id = v_mother_profile_id
          and (bp_systolic_mmhg is not null or bp_diastolic_mmhg is not null
            or heart_rate_bpm is not null or hrv_ms is not null
            or spo2_percent is not null or respiratory_rate_per_min is not null
            or skin_temperature_c is not null or weight_kg is not null
            or steps_count is not null)
        order by check_in_date desc limit 10
      ) as entry
    ), '[]'::jsonb));
  end if;

  return v_data;
end;
$$;

create or replace function public.disconnect_partner()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Sign in before disconnecting a partner';
  end if;
  delete from public.caregiver_connections
  where mother_user_id = auth.uid();
end;
$$;

revoke all on function public.connect_partner_by_email(text) from public;
revoke all on function public.get_partner_shared_data(uuid) from public;
revoke all on function public.disconnect_partner() from public;
grant execute on function public.connect_partner_by_email(text) to authenticated;
grant execute on function public.get_partner_shared_data(uuid) to authenticated;
grant execute on function public.disconnect_partner() to authenticated;

notify pgrst, 'reload schema';
commit;
