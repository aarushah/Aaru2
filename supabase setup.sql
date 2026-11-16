-- Hamro Kura: Supabase setup. Run this ONCE in Supabase -> SQL Editor -> New query -> Run.

-- 1) One table that holds chat, links, album, songs, clips and view history.
create table if not exists public.docs (
  id uuid primary key default gen_random_uuid(),
  col text not null,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists docs_col_created on public.docs (col, created_at);

-- Lets live updates also tell us which collection a deleted row belonged to.
alter table public.docs replica identity full;

-- 2) Only logged-in users can read or change anything.
alter table public.docs enable row level security;

create policy "docs read"   on public.docs for select to authenticated using (true);
create policy "docs insert" on public.docs for insert to authenticated with check (true);
create policy "docs update" on public.docs for update to authenticated using (true) with check (true);
create policy "docs delete" on public.docs for delete to authenticated using (true);

-- 3) Live updates (new messages appear on the other phone without refreshing).
alter publication supabase_realtime add table public.docs;

-- 4) Storage bucket for photos, videos, songs and voice messages.
--    Files get random names, but the bucket is public: anyone who has an exact file link can open it.
insert into storage.buckets (id, name, public, file_size_limit)
values ('media', 'media', true, 26214400)
on conflict (id) do nothing;

create policy "media read"   on storage.objects for select using (bucket_id = 'media');
create policy "media insert" on storage.objects for insert to authenticated with check (bucket_id = 'media');
create policy "media delete" on storage.objects for delete to authenticated using (bucket_id = 'media');
