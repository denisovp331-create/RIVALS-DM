-- RIVALS DM community leaderboard schema (Supabase/Postgres)
-- Run ONLY in a NEW Supabase project created for RIVALS-DM.
-- Do not run this in the STAR MARKET project.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  roblox_username text not null unique check (char_length(roblox_username) between 3 and 24),
  gold_weapon_count integer not null default 0 check (gold_weapon_count >= 0 and gold_weapon_count <= 100),
  created_at timestamptz not null default now()
);

create table if not exists public.score_submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  screenshot_path text not null,
  score integer not null check (score >= 0 and score <= 100000),
  kd numeric(7,2) not null check (kd >= 0 and kd <= 999),
  place integer not null check (place between 1 and 100),
  kills integer check (kills is null or kills >= 0),
  ocr_text text,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  moderator_note text,
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);

create index if not exists score_submissions_approved_score_idx
  on public.score_submissions (score desc) where status = 'approved';
create index if not exists score_submissions_user_created_idx
  on public.score_submissions (user_id, created_at desc);

alter table public.profiles enable row level security;
alter table public.score_submissions enable row level security;

-- Profiles: anyone may see the public player card; only the owner can edit their own record.
drop policy if exists "Public profiles are readable" on public.profiles;
create policy "Public profiles are readable" on public.profiles
  for select using (true);

drop policy if exists "Users can create their own profile" on public.profiles;
create policy "Users can create their own profile" on public.profiles
  for insert to authenticated with check (auth.uid() = id);

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile" on public.profiles
  for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- Public can only see approved scores; the player can see their own pending/rejected submissions too.
drop policy if exists "Approved scores are public" on public.score_submissions;
create policy "Approved scores are public" on public.score_submissions
  for select using (status = 'approved' or auth.uid() = user_id);

drop policy if exists "Users can submit their own records" on public.score_submissions;
create policy "Users can submit their own records" on public.score_submissions
  for insert to authenticated with check (auth.uid() = user_id and status = 'pending');

-- Private bucket: screenshots must be uploaded under <auth.uid>/<filename>.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('rivalsdm-records', 'rivalsdm-records', false, 8388608, array['image/png','image/jpeg','image/webp'])
on conflict (id) do nothing;

drop policy if exists "Players upload their own screenshots" on storage.objects;
create policy "Players upload their own screenshots" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'rivalsdm-records' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "Players view their own screenshots" on storage.objects;
create policy "Players view their own screenshots" on storage.objects
  for select to authenticated
  using (bucket_id = 'rivalsdm-records' and (storage.foldername(name))[1] = auth.uid()::text);

-- Important: review actions must be performed by a trusted moderator/server using the service role.
-- Never put the Supabase service_role key in index.html or any public repository.
-- Do not treat OCR or a user-entered gold weapon count as proof; approve them only after review.
