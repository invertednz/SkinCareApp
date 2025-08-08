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
