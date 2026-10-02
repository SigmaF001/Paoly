-- Profile name/email are maintained by Supabase Auth (auth.users).
create table public.finance_states (
  user_id uuid primary key references auth.users(id) on delete cascade,
  snapshot jsonb not null check (jsonb_typeof(snapshot) = 'object'),
  revision bigint not null default 1,
  updated_at timestamptz not null default now()
);
alter table public.finance_states enable row level security;
create policy "Read own finance" on public.finance_states
  for select to authenticated using ((select auth.uid()) = user_id);
revoke all on public.finance_states from anon, authenticated;
grant select on public.finance_states to authenticated;

-- Atomic snapshot commit with optimistic concurrency; clients cannot bypass CAS.
create function public.save_finance_state(expected_revision bigint, new_snapshot jsonb)
returns bigint language plpgsql security definer set search_path = '' as $$
declare owner_id uuid := auth.uid(); current_row public.finance_states; next_revision bigint;
begin
  if owner_id is null then raise exception 'Authentication required'; end if;
  if new_snapshot->>'version' is distinct from '1'
    or jsonb_typeof(new_snapshot->'accounts') is distinct from 'array'
    or jsonb_typeof(new_snapshot->'transactions') is distinct from 'array'
    or jsonb_typeof(new_snapshot->'categories') is distinct from 'array'
  then raise exception 'Invalid snapshot'; end if;
  -- Serialize even the first insert for a user.
  perform pg_advisory_xact_lock(hashtextextended(owner_id::text, 0));
  select * into current_row from public.finance_states where user_id = owner_id;
  -- A lost response can safely retry the exact same content.
  if current_row.snapshot = new_snapshot then return current_row.revision; end if;
  if coalesce(current_row.revision, 0) <> expected_revision then
    raise exception 'Finance conflict: reload before saving' using errcode = '40001';
  end if;
  next_revision := expected_revision + 1;
  insert into public.finance_states(user_id, snapshot, revision)
    values(owner_id, new_snapshot, next_revision)
    on conflict(user_id) do update set snapshot = excluded.snapshot,
      revision = excluded.revision, updated_at = now();
  return next_revision;
end;
$$;
revoke all on function public.save_finance_state(bigint, jsonb) from public, anon;
grant execute on function public.save_finance_state(bigint, jsonb) to authenticated;
