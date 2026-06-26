-- MarshSight social layer: the trophy feed and trail-camera ingest.
-- Run this in the Supabase SQL editor (after schema.sql).

-- Shared harvests and catches (the "Strava for hunting" feed). Location is
-- optional: lat/lon are null when the user keeps the spot private but still
-- shares the story. Conditions are auto-stamped client-side.
create table if not exists posts (
    id          uuid primary key default gen_random_uuid(),
    kind        text not null,              -- deer/duck/turkey/fish/small/other
    note        text,
    lat         double precision,           -- null = location hidden
    lon         double precision,
    photo_url   text,
    temp_f      double precision,
    wind        text,
    moon        text,
    author      text,                       -- optional display name
    device_id   text,
    upvotes     int not null default 0,
    created_at  timestamptz not null default now()
);
create index if not exists posts_created_idx on posts (created_at desc);

alter table posts enable row level security;
create policy posts_read on posts for select using (true);
create policy posts_insert on posts for insert with check (true);

-- Trail-camera photos ingested by email. cam_code is the per-user inbox code
-- from cam-<code>@in.marshsight.com, so each user only sees their own cameras.
create table if not exists camera_photos (
    id          uuid primary key default gen_random_uuid(),
    cam_code    text not null,
    photo_url   text not null,
    camera_name text,
    taken_at    timestamptz,
    lat         double precision,
    lon         double precision,
    created_at  timestamptz not null default now()
);
create index if not exists camera_photos_code_idx on camera_photos (cam_code, created_at desc);

alter table camera_photos enable row level security;
create policy camera_photos_read on camera_photos for select using (true);
create policy camera_photos_insert on camera_photos for insert with check (true);
