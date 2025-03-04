-- Drop existing views
drop view if exists cars_with_brand cascade;
drop view if exists private_listings_with_brand cascade;

-- Create cars table if not exists
create table if not exists cars (
  id uuid default gen_random_uuid() primary key,
  brand_id uuid not null references brands(id) on delete restrict,
  model text not null,
  year integer not null check (year >= 1900 and year <= extract(year from current_date) + 1),
  price numeric not null check (price > 0),
  savings numeric not null check (savings >= 0),
  image text not null,
  video_url text,
  condition text not null check (condition in ('new', 'used')),
  mileage text not null default 'Under 1,000 km',
  fuel_type text not null check (fuel_type in ('Petrol', 'Diesel', 'Electric', 'Hybrid')),
  transmission text not null check (transmission in ('Automatic', 'Manual')),
  body_type text not null check (body_type in ('Sedan', 'SUV', 'Coupe', 'Hatchback', 'Convertible', 'Van')),
  exterior_color text not null check (exterior_color in ('Black', 'White', 'Silver', 'Blue', 'Red', 'Grey', 'Green', 'Brown', 'Beige')),
  interior_color text not null check (interior_color in ('Black', 'White', 'Silver', 'Blue', 'Red', 'Grey', 'Green', 'Brown', 'Beige')),
  number_of_owners integer not null default 1 check (number_of_owners > 0),
  is_sold boolean not null default false,
  dealer_id uuid references dealers(id) on delete set null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create cars_with_brand view
create view cars_with_brand as
select 
  c.*,
  b.name as brand_name,
  b.logo_url as brand_logo_url,
  coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'name', cf.name,
          'available', cf.available
        )
        order by cf.name
      )
      filter (where cf.name is not null)
      from car_features cf
      where cf.car_id = c.id
    ),
    '[]'::jsonb
  ) as features
from cars c
join brands b on b.id = c.brand_id;

-- Create private_listings_with_brand view
create view private_listings_with_brand as
select 
  pl.*,
  b.name as brand_name,
  b.logo_url as brand_logo_url,
  coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'name', plf.name,
          'available', plf.available
        )
        order by plf.name
      )
      filter (where plf.name is not null)
      from private_listing_features plf
      where plf.listing_id = pl.id
    ),
    '[]'::jsonb
  ) as features,
  coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'id', db.id,
          'amount', db.amount,
          'dealer', jsonb_build_object(
            'id', d.id,
            'name', d.name,
            'phone', d.phone,
            'whatsapp', d.whatsapp
          )
        )
        order by db.amount desc
      )
      filter (where db.id is not null)
      from dealer_bids db
      join dealers d on d.id = db.dealer_id
      where db.listing_id = pl.id
    ),
    '[]'::jsonb
  ) as bids
from private_listings pl
join brands b on b.id = pl.brand_id;

-- Create indexes for better performance
create index if not exists idx_cars_brand_id on cars(brand_id);
create index if not exists idx_cars_condition on cars(condition);
create index if not exists idx_cars_is_sold on cars(is_sold);
create index if not exists idx_cars_dealer_id on cars(dealer_id);
create index if not exists idx_car_features_car_id on car_features(car_id);
create index if not exists idx_private_listings_brand_id on private_listings(brand_id);
create index if not exists idx_private_listings_status on private_listings(status);
create index if not exists idx_dealer_bids_dealer_id on dealer_bids(dealer_id);
create index if not exists idx_dealer_bids_listing_id on dealer_bids(listing_id);

-- Enable RLS
alter table cars enable row level security;
alter table car_features enable row level security;
alter table private_listings enable row level security;
alter table private_listing_features enable row level security;
alter table dealer_bids enable row level security;

-- Create RLS policies
create policy "Anyone can view cars"
  on cars for select
  using (true);

create policy "Anyone can view private listings"
  on private_listings for select
  using (true);

create policy "Anyone can view car features"
  on car_features for select
  using (true);

create policy "Anyone can view private listing features"
  on private_listing_features for select
  using (true);

create policy "Anyone can view dealer bids"
  on dealer_bids for select
  using (true);

-- Grant necessary permissions
grant usage on schema public to authenticated;
grant all privileges on all tables in schema public to authenticated;
grant select on all tables in schema public to anon;

-- Grant access to views
grant select on cars_with_brand to anon, authenticated;
grant select on private_listings_with_brand to anon, authenticated;

-- Refresh schema cache
notify pgrst, 'reload schema';