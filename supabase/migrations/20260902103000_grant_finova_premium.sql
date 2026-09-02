create or replace function public.finova_grant_premium(
  target_user_id uuid,
  target_order_id text,
  target_event_name text,
  target_amount integer,
  target_currency text,
  target_payload jsonb
)
returns timestamptz
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_expiry timestamptz;
begin
  if (select auth.role()) is distinct from 'service_role' then
    raise exception 'service role required';
  end if;

  insert into public.finova_payments (
    user_id, provider, provider_order_id, event_name, status,
    amount, currency, payload
  ) values (
    target_user_id, 'lemon_squeezy', target_order_id,
    target_event_name, 'paid', target_amount, upper(target_currency),
    target_payload
  ) on conflict (provider, provider_order_id) do nothing;

  if not found then
    select premium_expires_at into new_expiry
      from public.finova_profiles where id = target_user_id;
    return new_expiry;
  end if;

  update public.finova_profiles
  set is_premium = true,
      premium_expires_at = greatest(now(), coalesce(premium_expires_at, now()))
        + interval '30 days',
      updated_at = now()
  where id = target_user_id
  returning premium_expires_at into new_expiry;

  if new_expiry is null then
    raise exception 'Finova profile not found';
  end if;
  return new_expiry;
end;
$$;

revoke all on function public.finova_grant_premium(
  uuid, text, text, integer, text, jsonb
) from public, anon, authenticated;
grant execute on function public.finova_grant_premium(
  uuid, text, text, integer, text, jsonb
) to service_role;

comment on function public.finova_grant_premium(
  uuid, text, text, integer, text, jsonb
) is 'Idempotently records a Lemon Squeezy order and grants 30 premium days.';

