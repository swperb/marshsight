-- MarshSight platform schema for Supabase (Postgres + PostGIS).
-- Run this in the Supabase SQL editor on a new project.
-- Crowdsourced contributions and the landing-page waitlist. Honey-hole privacy
-- is enforced: private contributions are never exposed to other users.

create extension if not exists postgis;

-- Crowdsourced field reports (hazards, blinds, ramps, harvest, etc.)
create table if not exists contributions (
    id          uuid primary key default gen_random_uuid(),
    kind        text not null check (kind in
                  ('hazard','waypoint','blind','ramp','harvest','catch','note')),
    name        text not null,
    note        text,
    lat         double precision not null,
    lon         double precision not null,
    geom        geography(Point, 4326),
    visibility  text not null default 'private'
                  check (visibility in ('private','group','public')),
    device_id   text,                       -- anonymous author until real accounts
    created_at  timestamptz not null default now()
);

create index if not exists contributions_geom_idx on contributions using gist (geom);
create index if not exists contributions_visibility_idx on contributions (visibility);

-- Keep geom in sync with lat/lon on write.
create or replace function contributions_set_geom() returns trigger as $$
begin
    new.geom := st_setsrid(st_makepoint(new.lon, new.lat), 4326)::geography;
    return new;
end;
$$ language plpgsql;

drop trigger if exists contributions_geom_trg on contributions;
create trigger contributions_geom_trg before insert or update on contributions
    for each row execute function contributions_set_geom();

-- Community review: vote tallies and status on contributions.
alter table contributions add column if not exists upvotes int not null default 0;
alter table contributions add column if not exists downvotes int not null default 0;
alter table contributions add column if not exists status text not null default 'pending';

-- One vote per device per contribution.
create table if not exists votes (
    id              uuid primary key default gen_random_uuid(),
    contribution_id uuid not null references contributions(id) on delete cascade,
    device_id       text not null,
    value           smallint not null check (value in (-1, 0, 1)),
    created_at      timestamptz not null default now(),
    unique (contribution_id, device_id)
);
alter table votes enable row level security;
drop policy if exists votes_all on votes;
create policy votes_all on votes for all using (true) with check (true);

-- Recompute a contribution's tallies and review status from its votes.
-- Verified at +3 net, rejected at -3 net, pending in between.
create or replace function recompute_votes(cid uuid) returns void as $$
declare ups int; downs int;
begin
    select coalesce(sum(case when value = 1 then 1 else 0 end), 0),
           coalesce(sum(case when value = -1 then 1 else 0 end), 0)
      into ups, downs from votes where contribution_id = cid;
    update contributions set upvotes = ups, downvotes = downs,
        status = case when ups - downs >= 3 then 'verified'
                      when ups - downs <= -3 then 'rejected'
                      else 'pending' end
    where id = cid;
end;
$$ language plpgsql;

-- Landing-page waitlist.
create table if not exists waitlist (
    id          uuid primary key default gen_random_uuid(),
    email       text not null unique,
    created_at  timestamptz not null default now()
);

-- Row Level Security. The MarshSight API talks to Postgres with the service-role
-- key, which bypasses RLS, and enforces privacy in its queries. These policies
-- protect the data if a client ever connects with the anon key directly.
alter table contributions enable row level security;
alter table waitlist enable row level security;

-- Anyone may read only PUBLIC contributions. Private and group stay hidden.
drop policy if exists contributions_public_read on contributions;
create policy contributions_public_read on contributions
    for select using (visibility = 'public');

-- Anyone may submit a contribution or join the waitlist.
drop policy if exists contributions_insert on contributions;
create policy contributions_insert on contributions
    for insert with check (true);

drop policy if exists waitlist_insert on waitlist;
create policy waitlist_insert on waitlist
    for insert with check (true);
