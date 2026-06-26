-- UGC moderation for App Store Guideline 1.2 (run after the other schemas).
-- Reports + auto-hide: content reported by enough distinct users is hidden
-- from everyone, pending manual review/removal.

alter table posts add column if not exists hidden boolean not null default false;
alter table posts add column if not exists report_count int not null default 0;
alter table contributions add column if not exists hidden boolean not null default false;
alter table contributions add column if not exists report_count int not null default 0;

create table if not exists reports (
    id              uuid primary key default gen_random_uuid(),
    content_type    text not null,            -- 'post' | 'contribution'
    content_id      uuid not null,
    reason          text,
    reporter_device text,
    created_at      timestamptz not null default now(),
    unique (content_type, content_id, reporter_device)
);

alter table reports enable row level security;
create policy reports_insert on reports for insert with check (true);
