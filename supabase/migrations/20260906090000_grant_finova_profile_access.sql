-- Allow signed-in users to read and edit their own profile row.
-- Row Level Security policies still restrict access to auth.uid() = id.
grant select, update on table public.finova_profiles to authenticated;
