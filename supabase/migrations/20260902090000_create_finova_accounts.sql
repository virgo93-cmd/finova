create table if not exists public.finova_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  avatar_url text,
  is_premium boolean not null default false,
  premium_expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint finova_profiles_premium_consistency check (
    is_premium = false or premium_expires_at is not null
  )
);

create table if not exists public.finova_payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.finova_profiles(id) on delete cascade,
  provider text not null default 'lemon_squeezy',
  provider_order_id text not null,
  event_name text not null,
  status text not null,
  amount integer,
  currency text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (provider, provider_order_id)
);

create index if not exists finova_payments_user_id_created_at_idx
  on public.finova_payments(user_id, created_at desc);

alter table public.finova_profiles enable row level security;
alter table public.finova_payments enable row level security;

drop policy if exists "finova_profiles_select_own" on public.finova_profiles;
create policy "finova_profiles_select_own"
  on public.finova_profiles
  for select
  to authenticated
  using ((select auth.uid()) = id);

drop policy if exists "finova_profiles_update_own" on public.finova_profiles;
create policy "finova_profiles_update_own"
  on public.finova_profiles
  for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

drop policy if exists "finova_payments_select_own" on public.finova_payments;
create policy "finova_payments_select_own"
  on public.finova_payments
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create or replace function public.finova_handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.finova_profiles (id, email, display_name, avatar_url)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do update set
    email = excluded.email,
    display_name = coalesce(excluded.display_name, public.finova_profiles.display_name),
    avatar_url = coalesce(excluded.avatar_url, public.finova_profiles.avatar_url),
    updated_at = now();
  return new;
end;
$$;

drop trigger if exists finova_on_auth_user_created on auth.users;
create trigger finova_on_auth_user_created
  after insert or update of email, raw_user_meta_data on auth.users
  for each row execute function public.finova_handle_new_user();

create or replace function public.finova_premium_active(profile public.finova_profiles)
returns boolean
language sql
stable
set search_path = ''
as $$
  select profile.is_premium
    and profile.premium_expires_at is not null
    and profile.premium_expires_at > now();
$$;

create or replace function public.finova_protect_premium_entitlement()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (select auth.role()) is distinct from 'service_role'
    and (
      new.is_premium is distinct from old.is_premium
      or new.premium_expires_at is distinct from old.premium_expires_at
    )
  then
    raise exception 'Premium entitlement can only be changed by the backend';
  end if;
  return new;
end;
$$;

drop trigger if exists finova_protect_premium_fields on public.finova_profiles;
create trigger finova_protect_premium_fields
  before update on public.finova_profiles
  for each row execute function public.finova_protect_premium_entitlement();

revoke all on function public.finova_handle_new_user() from public;
revoke all on function public.finova_protect_premium_entitlement() from public;
grant execute on function public.finova_premium_active(public.finova_profiles)
  to authenticated;

comment on table public.finova_profiles is
  'Finova user profile and server-authoritative premium entitlement.';
comment on table public.finova_payments is
  'Idempotent Lemon Squeezy payment event records for Finova.';
