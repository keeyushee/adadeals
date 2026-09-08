-- AdaDeals: lock down direct writes to `deals` from the public anon key.
-- Run this once in the Supabase SQL Editor (Dashboard -> SQL Editor -> New query -> Run).
--
-- Before this, the anon key (shipped in index.html, unavoidably public) could
-- INSERT/UPDATE/DELETE any row directly. The curator password in the app was
-- only a UI gate, not enforced by the database. After this, only the
-- `manage-deal` Edge Function (using the service_role key, never exposed to
-- the browser) can add/edit/delete deals. Visitors keep the ability to
-- save/share/claim through the narrow RPCs below.

alter table public.deals enable row level security;

-- Clean slate: drop any existing policies so we know exactly what's active.
do $$
declare pol record;
begin
  for pol in select policyname from pg_policies where schemaname = 'public' and tablename = 'deals'
  loop
    execute format('drop policy %I on public.deals', pol.policyname);
  end loop;
end $$;

-- The feed needs to read all deals publicly.
create policy "public can read deals"
  on public.deals for select
  to anon
  using (true);

-- Belt-and-suspenders: even if a policy is ever added back by mistake,
-- the anon role should have no write privilege at the grant level at all.
revoke insert, update, delete on public.deals from anon;
revoke insert, update, delete on public.deals from authenticated;

-- ── Narrow, validated RPCs for visitor-triggered actions ────────────────
-- These run with the table owner's privileges (SECURITY DEFINER) but each
-- does exactly one bounded thing, so granting them to anon is safe even
-- though anon can no longer touch the table directly.

create or replace function public.increment_deal_save(p_deal_id text, p_delta int)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_delta not in (-1, 1) then
    raise exception 'invalid delta';
  end if;
  update public.deals
  set saves = greatest(0, coalesce(saves, 0) + p_delta)
  where id::text = p_deal_id;
end;
$$;

create or replace function public.increment_deal_share(p_deal_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.deals
  set shares = coalesce(shares, 0) + 1
  where id::text = p_deal_id;
end;
$$;

create or replace function public.claim_deal(p_deal_id text)
returns table(new_claims_count int, deal_max_claims int)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_max int;
  v_count int;
begin
  select max_claims, claims_count into v_max, v_count
  from public.deals
  where id::text = p_deal_id
  for update;

  if v_max is null then
    raise exception 'deal not found';
  end if;

  if v_count >= v_max then
    raise exception 'claims exhausted';
  end if;

  update public.deals
  set claims_count = claims_count + 1
  where id::text = p_deal_id
  returning claims_count, max_claims into v_count, v_max;

  return query select v_count, v_max;
end;
$$;

grant execute on function public.increment_deal_save(text, int) to anon;
grant execute on function public.increment_deal_share(text) to anon;
grant execute on function public.claim_deal(text) to anon;
