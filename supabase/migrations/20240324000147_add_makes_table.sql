-- Create makes table
create table makes (
  id uuid default gen_random_uuid() primary key,
  name text not null unique,
  logo_url text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Add foreign key to cars
alter table cars
drop column if exists make_logo_url,
add column if not exists make_id uuid references makes(id);

-- Add foreign key to private_listings
alter table private_listings
drop column if not exists make_logo_url,
add column if not exists make_id uuid references makes(id);

-- Insert default makes
insert into makes (name, logo_url) values
  ('BMW', 'https://tklblvxgprkvletfrsnn.supabase.co/storage/v1/object/public/make_logos/bmw.png'),
  ('Mercedes', 'https://tklblvxgprkvletfrsnn.supabase.co/storage/v1/object/public/make_logos/mercedes.png'),
  ('Audi', 'https://tklblvxgprkvletfrsnn.supabase.co/storage/v1/object/public/make_logos/audi.png'),
  ('Toyota', 'https://tklblvxgprkvletfrsnn.supabase.co/storage/v1/object/public/make_logos/toyota.png'),
  ('Honda', 'https://tklblvxgprkvletfrsnn.supabase.co/storage/v1/object/public/make_logos/honda.png'),
  ('Ford', 'https://tklblvxgprkvletfrsnn.supabase.co/storage/v1/object/public/make_logos/ford.png'),
  ('Volkswagen', 'https://tklblvxgprkvletfrsnn.supabase.co/storage/v1/object/public/make_logos/volkswagen.png');

-- Create function to get make_id from name
create or replace function get_make_id(p_make text)
returns uuid as $$
  select id from makes where name = p_make;
$$ language sql stable;

-- Create trigger to automatically set make_id
create or replace function set_make_id()
returns trigger as $$
begin
  new.make_id := get_make_id(new.make);
  return new;
end;
$$ language plpgsql;

create trigger set_car_make_id
  before insert or update of make on cars
  for each row
  execute function set_make_id();

create trigger set_private_listing_make_id
  before insert or update of make on private_listings
  for each row
  execute function set_make_id();

-- Update existing records
update cars c
set make_id = m.id
from makes m
where c.make = m.name;

update private_listings pl
set make_id = m.id
from makes m
where pl.make = m.name;

-- Create indexes
create index idx_cars_make_id on cars(make_id);
create index idx_private_listings_make_id on private_listings(make_id);

-- Refresh schema cache
notify pgrst, 'reload schema';