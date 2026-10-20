-- MyOrders Dahab: initial schema.
-- Tables, row level security, and the RPCs the apps call.

create extension if not exists pgcrypto;

-- ------------------------------------------------------------------ Tables

create table public.stores (
  id text primary key default gen_random_uuid()::text,
  name_en text not null,
  name_ar text not null,
  tags_en text not null default '',
  tags_ar text not null default '',
  section text not null check (section in ('food', 'drinks', 'supermarket', 'pharmacy')),
  category text not null default 'all',
  rating numeric(2, 1) not null default 0,
  reviews int not null default 0,
  eta_min int not null default 20,
  eta_max int not null default 40,
  delivery_fee numeric(10, 2) not null default 20,
  min_order numeric(10, 2) not null default 0,
  emoji text not null default '🏪',
  image_url text not null default '',
  phone text not null default '',
  is_open boolean not null default true,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.products (
  id text primary key default gen_random_uuid()::text,
  store_id text not null references public.stores (id) on delete cascade,
  name_en text not null,
  name_ar text not null,
  description_en text not null default '',
  description_ar text not null default '',
  price numeric(10, 2) not null check (price >= 0),
  emoji text not null default '🍽️',
  available boolean not null default true,
  created_at timestamptz not null default now()
);
create index products_store_idx on public.products (store_id);

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null default '',
  phone text,
  email text,
  role text not null default 'customer' check (role in ('customer', 'partner', 'rider', 'admin')),
  store_id text references public.stores (id) on delete set null,
  is_online boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  code bigint generated always as identity (start with 1001) unique,
  kind text not null default 'store' check (kind in ('store', 'courier')),
  customer_id uuid not null references public.profiles (id),
  customer_name text not null,
  customer_phone text not null,
  address text not null,
  lat double precision,
  lng double precision,
  pickup_address text,
  store_id text references public.stores (id),
  store_name_en text,
  store_name_ar text,
  items jsonb not null default '[]',
  subtotal numeric(10, 2) not null default 0,
  delivery_fee numeric(10, 2) not null default 0,
  total numeric(10, 2) not null default 0,
  commission numeric(10, 2) not null default 0,
  payment text not null default 'cash' check (payment in ('cash', 'card')),
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'preparing', 'ready', 'picked_up', 'delivered', 'cancelled')),
  rider_id uuid references public.profiles (id),
  rider_name text,
  rider_phone text,
  rider_lat double precision,
  rider_lng double precision,
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index orders_customer_idx on public.orders (customer_id, created_at desc);
create index orders_store_idx on public.orders (store_id, created_at desc);
create index orders_rider_idx on public.orders (rider_id);
create index orders_status_idx on public.orders (status);

create table public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  label text not null default '',
  details text not null,
  lat double precision,
  lng double precision,
  created_at timestamptz not null default now()
);

create table public.favorites (
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  store_id text not null references public.stores (id) on delete cascade,
  primary key (user_id, store_id)
);

create table public.partner_applications (
  id uuid primary key default gen_random_uuid(),
  business_name text not null,
  contact_name text not null,
  phone text not null,
  section text not null check (section in ('food', 'drinks', 'supermarket', 'pharmacy')),
  notes text not null default '',
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

-- ----------------------------------------------------------------- Helpers

create function public.my_role() returns text
language sql stable security definer set search_path = public as $$
  select coalesce((select role from profiles where id = auth.uid()), 'anon');
$$;

create function public.my_store_id() returns text
language sql stable security definer set search_path = public as $$
  select store_id from profiles where id = auth.uid();
$$;

create function public.is_admin() returns boolean
language sql stable as $$ select public.my_role() = 'admin'; $$;

-- New sign-ups get a customer profile. Staff roles are set by an admin.
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, full_name, phone, email)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', ''), new.phone, new.email);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Only admins may change role or store_id on a profile. Requests without a
-- signed-in user (SQL editor, service role) are trusted.
create function public.protect_profile_fields() returns trigger
language plpgsql as $$
begin
  if auth.uid() is not null and not public.is_admin()
     and (new.role is distinct from old.role or new.store_id is distinct from old.store_id) then
    raise exception 'Only admins can change roles';
  end if;
  return new;
end;
$$;

create trigger protect_profile_fields
  before update on public.profiles
  for each row execute function public.protect_profile_fields();

create function public.touch_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger orders_touch
  before update on public.orders
  for each row execute function public.touch_updated_at();

-- -------------------------------------------------------------------- RLS

alter table public.stores enable row level security;
alter table public.products enable row level security;
alter table public.profiles enable row level security;
alter table public.orders enable row level security;
alter table public.addresses enable row level security;
alter table public.favorites enable row level security;
alter table public.partner_applications enable row level security;

create policy "stores readable" on public.stores for select
  using (is_active or public.is_admin() or id = public.my_store_id());
create policy "admins manage stores" on public.stores for all
  using (public.is_admin()) with check (public.is_admin());

create policy "products readable" on public.products for select
  using (available or public.is_admin() or store_id = public.my_store_id());
create policy "partners manage own products" on public.products for all
  using (public.is_admin() or (public.my_role() = 'partner' and store_id = public.my_store_id()))
  with check (public.is_admin() or (public.my_role() = 'partner' and store_id = public.my_store_id()));

create policy "own profile" on public.profiles for select
  using (id = auth.uid() or public.is_admin());
create policy "update own profile" on public.profiles for update
  using (id = auth.uid() or public.is_admin());

-- Orders are written only through the RPCs below.
create policy "orders visible to involved people" on public.orders for select
  using (
    customer_id = auth.uid()
    or public.is_admin()
    or (public.my_role() = 'partner' and store_id = public.my_store_id())
    or (public.my_role() = 'rider' and (
      rider_id = auth.uid()
      or (rider_id is null and (
        (kind = 'courier' and status = 'pending')
        or (kind = 'store' and status in ('preparing', 'ready'))
      ))
    ))
  );

create policy "own addresses" on public.addresses for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "own favorites" on public.favorites for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "anyone can apply" on public.partner_applications for insert
  with check (true);
create policy "admins read applications" on public.partner_applications for select
  using (public.is_admin());

-- -------------------------------------------------------------------- RPCs

-- Places an order. Prices come from the products table, never the client.
create function public.place_order(draft jsonb) returns public.orders
language plpgsql security definer set search_path = public as $$
declare
  v_store stores;
  v_items jsonb := '[]';
  v_subtotal numeric := 0;
  v_fee numeric;
  v_item jsonb;
  v_product products;
  v_qty int;
  v_order orders;
begin
  if auth.uid() is null then
    raise exception 'Sign in to place an order';
  end if;

  if coalesce(draft ->> 'kind', 'store') = 'store' then
    select * into v_store from stores where id = draft ->> 'store_id' and is_active;
    if not found then raise exception 'Store not found'; end if;
    if not v_store.is_open then raise exception 'This store is closed right now'; end if;

    for v_item in select * from jsonb_array_elements(draft -> 'items') loop
      v_qty := (v_item ->> 'quantity')::int;
      if v_qty is null or v_qty < 1 or v_qty > 50 then raise exception 'Invalid quantity'; end if;
      select * into v_product from products
        where id = v_item ->> 'product_id' and store_id = v_store.id and available;
      if not found then raise exception 'A product is no longer available'; end if;
      v_items := v_items || jsonb_build_object(
        'product_id', v_product.id, 'name_en', v_product.name_en, 'name_ar', v_product.name_ar,
        'price', v_product.price, 'quantity', v_qty);
      v_subtotal := v_subtotal + v_product.price * v_qty;
    end loop;

    if jsonb_array_length(v_items) = 0 then raise exception 'The cart is empty'; end if;
    if v_subtotal < v_store.min_order then
      raise exception 'Minimum order is % EGP', v_store.min_order;
    end if;
    v_fee := v_store.delivery_fee;
  else
    v_fee := 40; -- courier base fee, keep in sync with courierFee in the app
  end if;

  insert into orders (
    kind, customer_id, customer_name, customer_phone, address, lat, lng, pickup_address,
    store_id, store_name_en, store_name_ar, items, subtotal, delivery_fee, total, commission,
    payment, notes)
  values (
    coalesce(draft ->> 'kind', 'store'), auth.uid(),
    draft ->> 'customer_name', draft ->> 'customer_phone', draft ->> 'address',
    (draft ->> 'lat')::double precision, (draft ->> 'lng')::double precision,
    draft ->> 'pickup_address',
    v_store.id, v_store.name_en, v_store.name_ar, v_items,
    v_subtotal, v_fee, v_subtotal + v_fee, round(v_subtotal * 0.15, 2),
    coalesce(draft ->> 'payment', 'cash'), coalesce(draft ->> 'notes', ''))
  returning * into v_order;

  return v_order;
end;
$$;

-- Moves an order forward. Each role may only make its own transitions.
create function public.update_order_status(order_id uuid, new_status text) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_order orders;
  v_role text := public.my_role();
  v_ok boolean := false;
begin
  select * into v_order from orders where id = order_id for update;
  if not found then raise exception 'Order not found'; end if;

  if v_role = 'admin' then
    v_ok := true;
  elsif v_role = 'partner' and v_order.store_id = public.my_store_id() then
    v_ok := (v_order.status, new_status) in (
      ('pending', 'accepted'), ('pending', 'cancelled'),
      ('accepted', 'preparing'), ('preparing', 'ready'));
  elsif v_role = 'rider' and v_order.rider_id = auth.uid() then
    v_ok := (new_status = 'picked_up' and (
               (v_order.kind = 'store' and v_order.status = 'ready')
               or (v_order.kind = 'courier' and v_order.status = 'accepted')))
         or (new_status = 'delivered' and v_order.status = 'picked_up');
  elsif v_order.customer_id = auth.uid() then
    v_ok := v_order.status = 'pending' and new_status = 'cancelled';
  end if;

  if not v_ok then raise exception 'You cannot change this order to %', new_status; end if;
  update orders set status = new_status where id = order_id;
end;
$$;

create function public.take_delivery(order_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_me profiles;
begin
  select * into v_me from profiles where id = auth.uid() and role = 'rider';
  if not found then raise exception 'Only riders can take deliveries'; end if;

  update orders set
    rider_id = v_me.id, rider_name = v_me.full_name, rider_phone = v_me.phone,
    status = case when kind = 'courier' then 'accepted' else status end
  where id = order_id and rider_id is null
    and ((kind = 'courier' and status = 'pending')
      or (kind = 'store' and status in ('preparing', 'ready')));
  if not found then raise exception 'Another rider took this order'; end if;
end;
$$;

create function public.update_rider_location(order_id uuid, p_lat double precision, p_lng double precision)
returns void
language sql security definer set search_path = public as $$
  update orders set rider_lat = p_lat, rider_lng = p_lng
  where id = order_id and rider_id = auth.uid() and status in ('accepted', 'ready', 'picked_up', 'preparing');
$$;

create function public.set_rider_online(online boolean) returns void
language sql security definer set search_path = public as $$
  update profiles set is_online = online where id = auth.uid() and role = 'rider';
$$;

create function public.set_store_open(target_store text, open boolean) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not (public.is_admin() or (public.my_role() = 'partner' and public.my_store_id() = target_store)) then
    raise exception 'Not allowed';
  end if;
  update stores set is_open = open where id = target_store;
end;
$$;

create function public.list_riders() returns table (
  id uuid, full_name text, phone text, is_online boolean, active_deliveries bigint)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Admins only'; end if;
  return query
    select p.id, p.full_name, coalesce(p.phone, ''), p.is_online,
      (select count(*) from orders o where o.rider_id = p.id and o.status not in ('delivered', 'cancelled'))
    from profiles p where p.role = 'rider' order by p.full_name;
end;
$$;

create function public.admin_stats() returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v_today timestamptz := date_trunc('day', now() at time zone 'Africa/Cairo') at time zone 'Africa/Cairo';
begin
  if not public.is_admin() then raise exception 'Admins only'; end if;
  return jsonb_build_object(
    'total_orders', (select count(*) from orders where status <> 'cancelled'),
    'orders_today', (select count(*) from orders where status <> 'cancelled' and created_at >= v_today),
    'active_stores', (select count(*) from stores where is_active),
    'partners', (select count(*) from stores),
    'online_riders', (select count(*) from profiles where role = 'rider' and is_online),
    'revenue_today', (select coalesce(sum(total), 0) from orders
                      where status <> 'cancelled' and created_at >= v_today),
    'commission_today', (select coalesce(sum(commission), 0) from orders
                         where status <> 'cancelled' and created_at >= v_today),
    'revenue_last_7_days', (
      select jsonb_agg(coalesce(r.total, 0) order by d.day)
      from generate_series(v_today - interval '6 days', v_today, interval '1 day') as d(day)
      left join lateral (
        select sum(total) as total from orders
        where status <> 'cancelled' and created_at >= d.day and created_at < d.day + interval '1 day'
      ) r on true)
  );
end;
$$;

grant execute on function public.place_order(jsonb) to authenticated;
grant execute on function public.update_order_status(uuid, text) to authenticated;
grant execute on function public.take_delivery(uuid) to authenticated;
grant execute on function public.update_rider_location(uuid, double precision, double precision) to authenticated;
grant execute on function public.set_rider_online(boolean) to authenticated;
grant execute on function public.set_store_open(text, boolean) to authenticated;
grant execute on function public.list_riders() to authenticated;
grant execute on function public.admin_stats() to authenticated;

-- Live updates for order tracking, partner screens and the rider app.
alter publication supabase_realtime add table public.orders;
