-- Supabase schema for Skincare App
-- Auth 1.1: Create profiles table

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  onboarding_completed_at timestamptz,
  time_zone text not null default 'UTC'
);

comment on table public.profiles is 'User profiles and app-specific attributes';
comment on column public.profiles.time_zone is 'IANA timezone identifier, e.g., America/Los_Angeles';

-- Auth 1.2: Enable RLS and per-user policies on profiles
alter table public.profiles enable row level security;

drop policy if exists "Profiles are viewable by owner" on public.profiles;
create policy "Profiles are viewable by owner"
  on public.profiles for select
  using (auth.uid() = user_id);

drop policy if exists "Profiles can be inserted by owner" on public.profiles;
create policy "Profiles can be inserted by owner"
  on public.profiles for insert
  with check (auth.uid() = user_id);

drop policy if exists "Profiles can be updated by owner" on public.profiles;
create policy "Profiles can be updated by owner"
  on public.profiles for update
  using (auth.uid() = user_id);

drop policy if exists "Profiles can be deleted by owner" on public.profiles;
create policy "Profiles can be deleted by owner"
  on public.profiles for delete
  using (auth.uid() = user_id);

-- Auth 1.4: Trigger to auto-insert profile on user signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (user_id)
  values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Onboarding 1.2: onboarding_answers table to store per-step payloads
create table if not exists public.onboarding_answers (
  user_id uuid not null references auth.users(id) on delete cascade,
  step_key text not null,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, step_key)
);

comment on table public.onboarding_answers is 'Per-user onboarding answers per step';
comment on column public.onboarding_answers.step_key is 'OnboardingStepKey string identifier';

alter table public.onboarding_answers enable row level security;

drop policy if exists "Onboarding answers viewable by owner" on public.onboarding_answers;
create policy "Onboarding answers viewable by owner"
  on public.onboarding_answers for select
  using (auth.uid() = user_id);

drop policy if exists "Onboarding answers insertable by owner" on public.onboarding_answers;
create policy "Onboarding answers insertable by owner"
  on public.onboarding_answers for insert
  with check (auth.uid() = user_id);

drop policy if exists "Onboarding answers updatable by owner" on public.onboarding_answers;
create policy "Onboarding answers updatable by owner"
  on public.onboarding_answers for update
  using (auth.uid() = user_id);

-- Photos: metadata table for uploaded user photos linked to diary entries
create table if not exists public.photos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  entry_id uuid,
  path text not null,
  width int,
  height int,
  bytes int,
  created_at timestamptz not null default now()
);

comment on table public.photos is 'Per-user photo metadata for storage objects in bucket user-photos';

alter table public.photos enable row level security;

drop policy if exists "Photos viewable by owner" on public.photos;
create policy "Photos viewable by owner"
  on public.photos for select
  using (auth.uid() = user_id);

drop policy if exists "Photos insertable by owner" on public.photos;
create policy "Photos insertable by owner"
  on public.photos for insert
  with check (auth.uid() = user_id);

drop policy if exists "Photos updatable by owner" on public.photos;
create policy "Photos updatable by owner"
  on public.photos for update
  using (auth.uid() = user_id);

drop policy if exists "Photos deletable by owner" on public.photos;
create policy "Photos deletable by owner"
  on public.photos for delete
  using (auth.uid() = user_id);

-- Diary Logging 1.1: Create diary entity tables

-- Skin Health Entries
create table if not exists public.skin_health_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  entry_date date not null,
  overall_rating int check (overall_rating >= 1 and overall_rating <= 10),
  hydration_rating int check (hydration_rating >= 1 and hydration_rating <= 10),
  oiliness_rating int check (oiliness_rating >= 1 and oiliness_rating <= 10),
  sensitivity_rating int check (sensitivity_rating >= 1 and sensitivity_rating <= 10),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on table public.skin_health_entries is 'Daily skin health assessments with rating sliders';

-- Symptom Entries
create table if not exists public.symptom_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  entry_date date not null,
  symptom_type text not null, -- e.g., 'acne', 'redness', 'dryness'
  locations text[] not null default '{}', -- array of location strings
  severity int check (severity >= 1 and severity <= 5),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on table public.symptom_entries is 'Symptom tracking with locations and severity';

-- Diet Entries
create table if not exists public.diet_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  entry_date date not null,
  dairy_consumed boolean not null default false,
  sugar_consumed boolean not null default false,
  processed_food_consumed boolean not null default false,
  alcohol_consumed boolean not null default false,
  water_intake_glasses int check (water_intake_glasses >= 0),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on table public.diet_entries is 'Daily diet tracking with flags and water intake';

-- Supplement Entries
create table if not exists public.supplement_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  entry_date date not null,
  supplement_name text not null,
  dosage text,
  taken boolean not null default false,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on table public.supplement_entries is 'Daily supplement tracking with dosage and adherence';

-- Routine Entries
create table if not exists public.routine_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  entry_date date not null,
  routine_type text not null, -- 'morning' or 'evening'
  step_name text not null,
  completed boolean not null default false,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on table public.routine_entries is 'Daily routine adherence tracking';

-- Diary Logging 1.3: Add RLS policies for all diary tables

-- Skin Health Entries RLS
alter table public.skin_health_entries enable row level security;

drop policy if exists "Skin health entries viewable by owner" on public.skin_health_entries;
create policy "Skin health entries viewable by owner"
  on public.skin_health_entries for select
  using (auth.uid() = user_id);

drop policy if exists "Skin health entries insertable by owner" on public.skin_health_entries;
create policy "Skin health entries insertable by owner"
  on public.skin_health_entries for insert
  with check (auth.uid() = user_id);

drop policy if exists "Skin health entries updatable by owner" on public.skin_health_entries;
create policy "Skin health entries updatable by owner"
  on public.skin_health_entries for update
  using (auth.uid() = user_id);

drop policy if exists "Skin health entries deletable by owner" on public.skin_health_entries;
create policy "Skin health entries deletable by owner"
  on public.skin_health_entries for delete
  using (auth.uid() = user_id);

-- Symptom Entries RLS
alter table public.symptom_entries enable row level security;

drop policy if exists "Symptom entries viewable by owner" on public.symptom_entries;
create policy "Symptom entries viewable by owner"
  on public.symptom_entries for select
  using (auth.uid() = user_id);

drop policy if exists "Symptom entries insertable by owner" on public.symptom_entries;
create policy "Symptom entries insertable by owner"
  on public.symptom_entries for insert
  with check (auth.uid() = user_id);

drop policy if exists "Symptom entries updatable by owner" on public.symptom_entries;
create policy "Symptom entries updatable by owner"
  on public.symptom_entries for update
  using (auth.uid() = user_id);

drop policy if exists "Symptom entries deletable by owner" on public.symptom_entries;
create policy "Symptom entries deletable by owner"
  on public.symptom_entries for delete
  using (auth.uid() = user_id);

-- Diet Entries RLS
alter table public.diet_entries enable row level security;

drop policy if exists "Diet entries viewable by owner" on public.diet_entries;
create policy "Diet entries viewable by owner"
  on public.diet_entries for select
  using (auth.uid() = user_id);

drop policy if exists "Diet entries insertable by owner" on public.diet_entries;
create policy "Diet entries insertable by owner"
  on public.diet_entries for insert
  with check (auth.uid() = user_id);

drop policy if exists "Diet entries updatable by owner" on public.diet_entries;
create policy "Diet entries updatable by owner"
  on public.diet_entries for update
  using (auth.uid() = user_id);

drop policy if exists "Diet entries deletable by owner" on public.diet_entries;
create policy "Diet entries deletable by owner"
  on public.diet_entries for delete
  using (auth.uid() = user_id);

-- Supplement Entries RLS
alter table public.supplement_entries enable row level security;

drop policy if exists "Supplement entries viewable by owner" on public.supplement_entries;
create policy "Supplement entries viewable by owner"
  on public.supplement_entries for select
  using (auth.uid() = user_id);

drop policy if exists "Supplement entries insertable by owner" on public.supplement_entries;
create policy "Supplement entries insertable by owner"
  on public.supplement_entries for insert
  with check (auth.uid() = user_id);

drop policy if exists "Supplement entries updatable by owner" on public.supplement_entries;
create policy "Supplement entries updatable by owner"
  on public.supplement_entries for update
  using (auth.uid() = user_id);

drop policy if exists "Supplement entries deletable by owner" on public.supplement_entries;
create policy "Supplement entries deletable by owner"
  on public.supplement_entries for delete
  using (auth.uid() = user_id);

-- Routine Entries RLS
alter table public.routine_entries enable row level security;

drop policy if exists "Routine entries viewable by owner" on public.routine_entries;
create policy "Routine entries viewable by owner"
  on public.routine_entries for select
  using (auth.uid() = user_id);

drop policy if exists "Routine entries insertable by owner" on public.routine_entries;
create policy "Routine entries insertable by owner"
  on public.routine_entries for insert
  with check (auth.uid() = user_id);

drop policy if exists "Routine entries updatable by owner" on public.routine_entries;
create policy "Routine entries updatable by owner"
  on public.routine_entries for update
  using (auth.uid() = user_id);

drop policy if exists "Routine entries deletable by owner" on public.routine_entries;
create policy "Routine entries deletable by owner"
  on public.routine_entries for delete
  using (auth.uid() = user_id);

-- Diary Logging 1.4: Add presets tables for symptom locations and acne subtypes

-- Symptom locations preset data
create table if not exists public.symptom_locations (
  id uuid primary key default gen_random_uuid(),
  location_name text not null unique,
  display_order int not null default 0,
  created_at timestamptz not null default now()
);

comment on table public.symptom_locations is 'Preset symptom location options for UI';

-- Insert default symptom locations
insert into public.symptom_locations (location_name, display_order) values
  ('Forehead', 1),
  ('T-Zone', 2),
  ('Cheeks', 3),
  ('Nose', 4),
  ('Chin', 5),
  ('Jawline', 6),
  ('Around Eyes', 7),
  ('Around Mouth', 8),
  ('Neck', 9),
  ('Back', 10),
  ('Chest', 11),
  ('Shoulders', 12)
on conflict (location_name) do nothing;

-- Acne subtypes preset data
create table if not exists public.acne_subtypes (
  id uuid primary key default gen_random_uuid(),
  subtype_name text not null unique,
  display_order int not null default 0,
  created_at timestamptz not null default now()
);

comment on table public.acne_subtypes is 'Preset acne subtype options for UI';

-- Insert default acne subtypes
insert into public.acne_subtypes (subtype_name, display_order) values
  ('Blackheads', 1),
  ('Whiteheads', 2),
  ('Papules', 3),
  ('Pustules', 4),
  ('Nodules', 5),
  ('Cysts', 6),
  ('Comedones', 7),
  ('Inflammatory', 8),
  ('Non-inflammatory', 9)
on conflict (subtype_name) do nothing;

-- Diary Logging 1.5: Add basic indexes for date range queries

-- Indexes for efficient date range queries
create index if not exists idx_skin_health_entries_user_date on public.skin_health_entries (user_id, entry_date desc);
create index if not exists idx_symptom_entries_user_date on public.symptom_entries (user_id, entry_date desc);
create index if not exists idx_diet_entries_user_date on public.diet_entries (user_id, entry_date desc);
create index if not exists idx_supplement_entries_user_date on public.supplement_entries (user_id, entry_date desc);
create index if not exists idx_routine_entries_user_date on public.routine_entries (user_id, entry_date desc);
create index if not exists idx_photos_user_entry on public.photos (user_id, entry_id);

-- Indexes for soft delete queries (excluding deleted records)
create index if not exists idx_skin_health_entries_active on public.skin_health_entries (user_id, entry_date desc) where deleted_at is null;
create index if not exists idx_symptom_entries_active on public.symptom_entries (user_id, entry_date desc) where deleted_at is null;
create index if not exists idx_diet_entries_active on public.diet_entries (user_id, entry_date desc) where deleted_at is null;
create index if not exists idx_supplement_entries_active on public.supplement_entries (user_id, entry_date desc) where deleted_at is null;
create index if not exists idx_routine_entries_active on public.routine_entries (user_id, entry_date desc) where deleted_at is null;

-- Insights 1.1: Add insights cache table for generated insights
create table if not exists public.insights (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  summary jsonb not null,
  recommendations jsonb not null,
  action_plan jsonb not null,
  data_period jsonb not null,
  generated_at timestamptz not null default now(),
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

comment on table public.insights is 'Cached AI-generated insights for users';

-- Insights table RLS
alter table public.insights enable row level security;

drop policy if exists "Insights viewable by owner" on public.insights;
create policy "Insights viewable by owner"
  on public.insights for select
  using (auth.uid() = user_id);

drop policy if exists "Insights insertable by owner" on public.insights;
create policy "Insights insertable by owner"
  on public.insights for insert
  with check (auth.uid() = user_id);

drop policy if exists "Insights updatable by owner" on public.insights;
create policy "Insights updatable by owner"
  on public.insights for update
  using (auth.uid() = user_id);

drop policy if exists "Insights deletable by owner" on public.insights;
create policy "Insights deletable by owner"
  on public.insights for delete
  using (auth.uid() = user_id);

-- Index for insights queries
create index if not exists idx_insights_user_generated on public.insights (user_id, generated_at desc);

-- Notifications 1.0: FCM token storage table
create table if not exists public.user_fcm_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('android', 'ios', 'web')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, platform)
);

comment on table public.user_fcm_tokens is 'FCM tokens for push notifications per user/platform';

-- FCM tokens RLS
alter table public.user_fcm_tokens enable row level security;

drop policy if exists "FCM tokens viewable by owner" on public.user_fcm_tokens;
create policy "FCM tokens viewable by owner"
  on public.user_fcm_tokens for select
  using (auth.uid() = user_id);

drop policy if exists "FCM tokens insertable by owner" on public.user_fcm_tokens;
create policy "FCM tokens insertable by owner"
  on public.user_fcm_tokens for insert
  with check (auth.uid() = user_id);

drop policy if exists "FCM tokens updatable by owner" on public.user_fcm_tokens;
create policy "FCM tokens updatable by owner"
  on public.user_fcm_tokens for update
  using (auth.uid() = user_id);

drop policy if exists "FCM tokens deletable by owner" on public.user_fcm_tokens;
create policy "FCM tokens deletable by owner"
  on public.user_fcm_tokens for delete
  using (auth.uid() = user_id);

-- Notifications 2.0: Notification settings table
create table if not exists public.notification_settings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category text not null check (category in ('routine_am', 'routine_pm', 'daily_log', 'weekly_insights')),
  enabled boolean not null default true,
  time time not null,
  quiet_from time not null default '22:00:00',
  quiet_to time not null default '07:00:00',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, category)
);

comment on table public.notification_settings is 'User notification preferences per category';

-- Notification settings RLS
alter table public.notification_settings enable row level security;

drop policy if exists "Notification settings viewable by owner" on public.notification_settings;
create policy "Notification settings viewable by owner"
  on public.notification_settings for select
  using (auth.uid() = user_id);

drop policy if exists "Notification settings insertable by owner" on public.notification_settings;
create policy "Notification settings insertable by owner"
  on public.notification_settings for insert
  with check (auth.uid() = user_id);

drop policy if exists "Notification settings updatable by owner" on public.notification_settings;
create policy "Notification settings updatable by owner"
  on public.notification_settings for update
  using (auth.uid() = user_id);

drop policy if exists "Notification settings deletable by owner" on public.notification_settings;
create policy "Notification settings deletable by owner"
  on public.notification_settings for delete
  using (auth.uid() = user_id);

-- Index for notification settings queries
create index if not exists idx_notification_settings_user_category on public.notification_settings (user_id, category);

-- Function to create default notification settings for new users
create or replace function public.create_default_notification_settings(user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notification_settings (user_id, category, time) values
    (user_id, 'routine_am', '08:00:00'),
    (user_id, 'routine_pm', '20:00:00'),
    (user_id, 'daily_log', '19:30:00'),
    (user_id, 'weekly_insights', '17:00:00')
  on conflict (user_id, category) do nothing;
end;
$$;
