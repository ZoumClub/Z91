-- Drop existing views
drop view if exists cars_with_brand cascade;
drop view if exists private_listings_with_brand cascade;

-- Ensure features columns exist
alter table cars 
add column if not exists features jsonb default '[]'::jsonb;

alter table private_listings 
add column if not exists features jsonb default '[]'::jsonb;

-- Create cars_with_brand view
create view cars_with_brand as
select 
  c.*,
  b.name as brand_name,
  b.logo_url as brand_logo_url
from cars c
join brands b on b.id = c.brand_id;

-- Create private_listings_with_brand view
create view private_listings_with_brand as
select 
  pl.*,
  b.name as brand_name,
  b.logo_url as brand_logo_url
from private_listings pl
join brands b on b.id = pl.brand_id;

-- Create indexes for better performance
create index if not exists idx_cars_features on cars using gin(features);
create index if not exists idx_private_listings_features on private_listings using gin(features);

-- Grant necessary permissions
grant usage on schema public to authenticated;
grant all privileges on all tables in schema public to authenticated;
grant select on all tables in schema public to anon;

-- Grant access to views
grant select on cars_with_brand to anon, authenticated;
grant select on private_listings_with_brand to anon, authenticated;

-- Refresh schema cache
notify pgrst, 'reload schema';