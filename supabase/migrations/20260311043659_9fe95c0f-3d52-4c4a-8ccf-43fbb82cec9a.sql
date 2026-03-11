-- Create storage bucket for player images and site assets
insert into storage.buckets (id, name, public)
values ('site-assets', 'site-assets', true)
on conflict (id) do nothing;

-- Storage policies for site-assets bucket
create policy "Public can view site assets"
  on storage.objects
  for select
  using (bucket_id = 'site-assets');

create policy "Admins can upload site assets"
  on storage.objects
  for insert
  with check (bucket_id = 'site-assets' and public.is_admin());

create policy "Admins can update site assets"
  on storage.objects
  for update
  using (bucket_id = 'site-assets' and public.is_admin());

create policy "Admins can delete site assets"
  on storage.objects
  for delete
  using (bucket_id = 'site-assets' and public.is_admin());

-- Create site_content table for editable text content
create table public.site_content (
  id uuid primary key default uuid_generate_v4(),
  key text unique not null,
  content text not null,
  updated_at timestamptz default now() not null
);

alter table public.site_content enable row level security;

create policy "Anyone can view site content"
  on public.site_content
  for select
  using (true);

create policy "Admins can update site content"
  on public.site_content
  for update
  using (public.is_admin());

create policy "Admins can insert site content"
  on public.site_content
  for insert
  with check (public.is_admin());

-- Update player_stats to include all player information
alter table public.player_stats
  add column if not exists real_name text,
  add column if not exists role text,
  add column if not exists country text,
  add column if not exists age integer,
  add column if not exists bio text,
  add column if not exists image_url text;

-- Insert default site content
insert into public.site_content (key, content) values
  ('hero_title', 'VELOCITY VORTEX X'),
  ('hero_tagline', 'Precision. Speed. Dominance.'),
  ('team_description', 'Elite esports performance powered by data and discipline.')
on conflict (key) do nothing;

-- Add trigger for site_content updated_at
create trigger set_site_content_updated_at
  before update on public.site_content
  for each row
  execute function public.handle_updated_at();