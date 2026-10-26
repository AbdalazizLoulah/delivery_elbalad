
-- -- ============================================================================
-- -- Delivery Elbalad - Supabase Database Schema
-- -- Corrected version
-- -- ============================================================================

-- BEGIN;

-- -- ---------------------------------------------------------------------------
-- -- 0. Basic schema permissions
-- -- ---------------------------------------------------------------------------
-- GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- -- ---------------------------------------------------------------------------
-- -- 1. Profiles
-- -- ---------------------------------------------------------------------------
-- CREATE TABLE IF NOT EXISTS public.profiles (
--   id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
--   full_name text NOT NULL DEFAULT '',
--   email text NOT NULL DEFAULT '',
--   role text NOT NULL DEFAULT 'buyer'
--     CHECK (role IN ('buyer', 'seller', 'courier')),
--   phone text NOT NULL DEFAULT '',
--   avatar_url text,
--   rating numeric(3,2) NOT NULL DEFAULT 0,
--   ratings_count integer NOT NULL DEFAULT 0,
--   lat double precision,
--   lng double precision,
--   address_text text,
--   is_available boolean NOT NULL DEFAULT false,
--   created_at timestamptz NOT NULL DEFAULT now(),
--   updated_at timestamptz NOT NULL DEFAULT now()
-- );

-- -- Add missing profile columns safely.
-- ALTER TABLE public.profiles
--   ADD COLUMN IF NOT EXISTS full_name text NOT NULL DEFAULT '',
--   ADD COLUMN IF NOT EXISTS email text NOT NULL DEFAULT '',
--   ADD COLUMN IF NOT EXISTS role text NOT NULL DEFAULT 'buyer',
--   ADD COLUMN IF NOT EXISTS phone text NOT NULL DEFAULT '',
--   ADD COLUMN IF NOT EXISTS avatar_url text,
--   ADD COLUMN IF NOT EXISTS rating numeric(3,2) NOT NULL DEFAULT 0,
--   ADD COLUMN IF NOT EXISTS ratings_count integer NOT NULL DEFAULT 0,
--   ADD COLUMN IF NOT EXISTS lat double precision,
--   ADD COLUMN IF NOT EXISTS lng double precision,
--   ADD COLUMN IF NOT EXISTS address_text text,
--   ADD COLUMN IF NOT EXISTS is_available boolean DEFAULT false,
--   ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now(),
--   ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

-- -- FIX: repair existing NULL values before enforcing NOT NULL.
-- UPDATE public.profiles
-- SET is_available = false
-- WHERE is_available IS NULL;

-- ALTER TABLE public.profiles
--   ALTER COLUMN is_available SET DEFAULT false,
--   ALTER COLUMN is_available SET NOT NULL;

-- -- Normalize nullable values in other required profile columns.
-- UPDATE public.profiles SET full_name = '' WHERE full_name IS NULL;
-- UPDATE public.profiles SET email = '' WHERE email IS NULL;
-- UPDATE public.profiles SET phone = '' WHERE phone IS NULL;
-- UPDATE public.profiles SET role = 'buyer' WHERE role IS NULL;
-- UPDATE public.profiles SET rating = 0 WHERE rating IS NULL;
-- UPDATE public.profiles SET ratings_count = 0 WHERE ratings_count IS NULL;
-- UPDATE public.profiles SET created_at = now() WHERE created_at IS NULL;
-- UPDATE public.profiles SET updated_at = now() WHERE updated_at IS NULL;

-- ALTER TABLE public.profiles
--   ALTER COLUMN full_name SET DEFAULT '',
--   ALTER COLUMN full_name SET NOT NULL,
--   ALTER COLUMN email SET DEFAULT '',
--   ALTER COLUMN email SET NOT NULL,
--   ALTER COLUMN phone SET DEFAULT '',
--   ALTER COLUMN phone SET NOT NULL,
--   ALTER COLUMN role SET DEFAULT 'buyer',
--   ALTER COLUMN role SET NOT NULL,
--   ALTER COLUMN rating SET DEFAULT 0,
--   ALTER COLUMN rating SET NOT NULL,
--   ALTER COLUMN ratings_count SET DEFAULT 0,
--   ALTER COLUMN ratings_count SET NOT NULL,
--   ALTER COLUMN created_at SET DEFAULT now(),
--   ALTER COLUMN created_at SET NOT NULL,
--   ALTER COLUMN updated_at SET DEFAULT now(),
--   ALTER COLUMN updated_at SET NOT NULL;

-- ALTER TABLE public.profiles
--   DROP CONSTRAINT IF EXISTS profiles_role_check;

-- ALTER TABLE public.profiles
--   ADD CONSTRAINT profiles_role_check
--   CHECK (role IN ('buyer', 'seller', 'courier'));

-- CREATE INDEX IF NOT EXISTS profiles_role_idx
--   ON public.profiles(role);

-- -- ---------------------------------------------------------------------------
-- -- 2. Categories
-- -- ---------------------------------------------------------------------------
-- CREATE TABLE IF NOT EXISTS public.categories (
--   id text PRIMARY KEY,
--   name_ar text NOT NULL,
--   icon text NOT NULL DEFAULT '🛍️',
--   sort_order integer NOT NULL DEFAULT 0
-- );

-- -- ---------------------------------------------------------------------------
-- -- 3. Products
-- -- ---------------------------------------------------------------------------
-- CREATE TABLE IF NOT EXISTS public.products (
--   id text PRIMARY KEY,
--   seller_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
--   seller_name text NOT NULL DEFAULT '',
--   title text NOT NULL,
--   description text NOT NULL DEFAULT '',
--   price numeric(10,2) NOT NULL DEFAULT 0,
--   image_url text NOT NULL DEFAULT '',
--   category_id text REFERENCES public.categories(id) ON DELETE SET NULL,
--   stock integer NOT NULL DEFAULT 0,
--   rating numeric(3,2) NOT NULL DEFAULT 0,
--   reviews_count integer NOT NULL DEFAULT 0,
--   is_active boolean NOT NULL DEFAULT true,
--   created_at timestamptz NOT NULL DEFAULT now(),
--   updated_at timestamptz NOT NULL DEFAULT now()
-- );

-- CREATE INDEX IF NOT EXISTS products_seller_idx
--   ON public.products(seller_id);

-- CREATE INDEX IF NOT EXISTS products_category_idx
--   ON public.products(category_id);

-- -- ---------------------------------------------------------------------------
-- -- 4. Addresses
-- -- ---------------------------------------------------------------------------
-- CREATE TABLE IF NOT EXISTS public.addresses (
--   id text PRIMARY KEY,
--   user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
--   label text NOT NULL DEFAULT 'البيت',
--   details text NOT NULL DEFAULT '',
--   lat double precision NOT NULL,
--   lng double precision NOT NULL,
--   is_default boolean NOT NULL DEFAULT false,
--   created_at timestamptz NOT NULL DEFAULT now()
-- );

-- CREATE INDEX IF NOT EXISTS addresses_user_idx
--   ON public.addresses(user_id);

-- -- ---------------------------------------------------------------------------
-- -- 5. Orders
-- -- ---------------------------------------------------------------------------
-- CREATE TABLE IF NOT EXISTS public.orders (
--   id text PRIMARY KEY,
--   code text NOT NULL DEFAULT '',
--   buyer_id uuid NOT NULL REFERENCES public.profiles(id),
--   buyer_name text NOT NULL DEFAULT '',
--   buyer_phone text NOT NULL DEFAULT '',
--   seller_id uuid NOT NULL REFERENCES public.profiles(id),
--   seller_name text NOT NULL DEFAULT '',
--   store_name text NOT NULL DEFAULT '',
--   courier_id uuid REFERENCES public.profiles(id),
--   courier_name text NOT NULL DEFAULT '',
--   courier_phone text NOT NULL DEFAULT '',
--   offered_courier_id uuid REFERENCES public.profiles(id),
--   status text NOT NULL DEFAULT 'pendingSeller',
--   payment_method text NOT NULL DEFAULT 'cashOnDelivery',
--   payment_status text NOT NULL DEFAULT 'unpaid',
--   items_subtotal numeric(10,2) NOT NULL DEFAULT 0,
--   delivery_fee numeric(10,2) NOT NULL DEFAULT 0,
--   total numeric(10,2) NOT NULL DEFAULT 0,
--   address_label text NOT NULL DEFAULT '',
--   address_details text NOT NULL DEFAULT '',
--   address_lat double precision NOT NULL DEFAULT 0,
--   address_lng double precision NOT NULL DEFAULT 0,
--   store_lat double precision,
--   store_lng double precision,
--   note text NOT NULL DEFAULT '',
--   created_at timestamptz NOT NULL DEFAULT now(),
--   updated_at timestamptz NOT NULL DEFAULT now(),
--   delivered_at timestamptz,
--   delivery_rating integer,
--   delivery_review text
-- );

-- CREATE INDEX IF NOT EXISTS orders_buyer_idx
--   ON public.orders(buyer_id, created_at DESC);

-- CREATE INDEX IF NOT EXISTS orders_seller_idx
--   ON public.orders(seller_id, created_at DESC);

-- CREATE INDEX IF NOT EXISTS orders_courier_idx
--   ON public.orders(courier_id, created_at DESC);

-- CREATE INDEX IF NOT EXISTS orders_offered_idx
--   ON public.orders(offered_courier_id);

-- CREATE INDEX IF NOT EXISTS orders_status_idx
--   ON public.orders(status);

-- -- ---------------------------------------------------------------------------
-- -- 6. Order items
-- -- ---------------------------------------------------------------------------
-- CREATE TABLE IF NOT EXISTS public.order_items (
--   id text PRIMARY KEY,
--   order_id text NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
--   product_id text,
--   title text NOT NULL DEFAULT '',
--   unit_price numeric(10,2) NOT NULL DEFAULT 0,
--   quantity integer NOT NULL DEFAULT 1,
--   image_url text NOT NULL DEFAULT ''
-- );

-- CREATE INDEX IF NOT EXISTS order_items_order_idx
--   ON public.order_items(order_id);

-- -- ---------------------------------------------------------------------------
-- -- 7. Order events
-- -- ---------------------------------------------------------------------------
-- CREATE TABLE IF NOT EXISTS public.order_events (
--   id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
--   order_id text NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
--   status text NOT NULL DEFAULT 'pendingSeller',
--   note text NOT NULL DEFAULT '',
--   actor_name text NOT NULL DEFAULT '',
--   created_at timestamptz NOT NULL DEFAULT now()
-- );

-- CREATE INDEX IF NOT EXISTS order_events_order_idx
--   ON public.order_events(order_id, created_at);

-- -- ---------------------------------------------------------------------------
-- -- 8. Courier locations
-- -- ---------------------------------------------------------------------------
-- CREATE TABLE IF NOT EXISTS public.courier_locations (
--   courier_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
--   lat double precision NOT NULL DEFAULT 0,
--   lng double precision NOT NULL DEFAULT 0,
--   order_id text REFERENCES public.orders(id) ON DELETE SET NULL,
--   updated_at timestamptz NOT NULL DEFAULT now()
-- );

-- -- ---------------------------------------------------------------------------
-- -- 9. Create a profile for new Auth users
-- -- IMPORTANT: only replace our own trigger, not every trigger on auth.users.
-- -- ---------------------------------------------------------------------------
-- CREATE OR REPLACE FUNCTION public.handle_new_user()
-- RETURNS trigger
-- LANGUAGE plpgsql
-- SECURITY DEFINER
-- SET search_path = ''
-- AS $$
-- DECLARE
--   chosen_role text;
-- BEGIN
--   chosen_role := COALESCE(
--     NEW.raw_user_meta_data ->> 'role',
--     'buyer'
--   );

--   IF chosen_role NOT IN ('buyer', 'seller', 'courier') THEN
--     chosen_role := 'buyer';
--   END IF;

--   INSERT INTO public.profiles (
--     id,
--     full_name,
--     email,
--     phone,
--     role,
--     is_available
--   )
--   VALUES (
--     NEW.id,
--     COALESCE(NEW.raw_user_meta_data ->> 'full_name', ''),
--     COALESCE(NEW.email, ''),
--     COALESCE(NEW.raw_user_meta_data ->> 'phone', ''),
--     chosen_role,
--     COALESCE(chosen_role = 'courier', false)
--   )
--   ON CONFLICT (id) DO NOTHING;

--   RETURN NEW;
-- END;
-- $$;

-- DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- CREATE TRIGGER on_auth_user_created
--   AFTER INSERT ON auth.users
--   FOR EACH ROW
--   EXECUTE FUNCTION public.handle_new_user();

-- -- ---------------------------------------------------------------------------
-- -- 10. Repair missing profiles for existing Auth users
-- -- ---------------------------------------------------------------------------
-- INSERT INTO public.profiles (
--   id,
--   full_name,
--   email,
--   phone,
--   role,
--   is_available
-- )
-- SELECT
--   u.id,
--   COALESCE(u.raw_user_meta_data ->> 'full_name', ''),
--   COALESCE(u.email, ''),
--   COALESCE(u.raw_user_meta_data ->> 'phone', ''),
--   CASE
--     WHEN u.raw_user_meta_data ->> 'role'
--       IN ('buyer', 'seller', 'courier')
--     THEN u.raw_user_meta_data ->> 'role'
--     ELSE 'buyer'
--   END,
--   COALESCE(
--     (u.raw_user_meta_data ->> 'role') = 'courier',
--     false
--   )
-- FROM auth.users AS u
-- ON CONFLICT (id) DO NOTHING;

-- -- Correct legacy default buyer roles only when metadata explicitly
-- -- specifies seller or courier.
-- UPDATE public.profiles AS p
-- SET
--   role = u.raw_user_meta_data ->> 'role',
--   is_available = COALESCE(
--     (u.raw_user_meta_data ->> 'role') = 'courier',
--     false
--   ),
--   updated_at = now()
-- FROM auth.users AS u
-- WHERE p.id = u.id
--   AND p.role = 'buyer'
--   AND u.raw_user_meta_data ->> 'role' IN ('seller', 'courier');

-- -- ---------------------------------------------------------------------------
-- -- 11. RLS: clear existing policies on application tables only
-- -- ---------------------------------------------------------------------------
-- DO $$
-- DECLARE
--   r record;
-- BEGIN
--   FOR r IN
--     SELECT tablename, policyname
--     FROM pg_policies
--     WHERE schemaname = 'public'
--       AND tablename IN (
--         'profiles', 'categories', 'products', 'addresses',
--         'orders', 'order_items', 'order_events', 'courier_locations'
--       )
--   LOOP
--     EXECUTE format(
--       'DROP POLICY IF EXISTS %I ON public.%I',
--       r.policyname,
--       r.tablename
--     );
--   END LOOP;
-- END;
-- $$;

-- ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.addresses ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.order_events ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.courier_locations ENABLE ROW LEVEL SECURITY;

-- -- Profiles
-- CREATE POLICY profiles_read ON public.profiles
--   FOR SELECT TO authenticated
--   USING (true);

-- CREATE POLICY profiles_insert_self ON public.profiles
--   FOR INSERT TO authenticated
--   WITH CHECK (auth.uid() = id);

-- CREATE POLICY profiles_update_self ON public.profiles
--   FOR UPDATE TO authenticated
--   USING (auth.uid() = id)
--   WITH CHECK (auth.uid() = id);

-- -- Categories
-- CREATE POLICY categories_read ON public.categories
--   FOR SELECT TO anon, authenticated
--   USING (true);

-- -- Products
-- CREATE POLICY products_read ON public.products
--   FOR SELECT TO anon, authenticated
--   USING (true);

-- CREATE POLICY products_insert_own ON public.products
--   FOR INSERT TO authenticated
--   WITH CHECK (
--     auth.uid() = seller_id
--     AND EXISTS (
--       SELECT 1
--       FROM public.profiles
--       WHERE id = auth.uid()
--         AND role = 'seller'
--     )
--   );

-- CREATE POLICY products_update_own ON public.products
--   FOR UPDATE TO authenticated
--   USING (
--     auth.uid() = seller_id
--     AND EXISTS (
--       SELECT 1
--       FROM public.profiles
--       WHERE id = auth.uid()
--         AND role = 'seller'
--     )
--   )
--   WITH CHECK (
--     auth.uid() = seller_id
--     AND EXISTS (
--       SELECT 1
--       FROM public.profiles
--       WHERE id = auth.uid()
--         AND role = 'seller'
--     )
--   );

-- CREATE POLICY products_delete_own ON public.products
--   FOR DELETE TO authenticated
--   USING (
--     auth.uid() = seller_id
--     AND EXISTS (
--       SELECT 1
--       FROM public.profiles
--       WHERE id = auth.uid()
--         AND role = 'seller'
--     )
--   );

-- -- Addresses
-- CREATE POLICY addresses_own ON public.addresses
--   FOR ALL TO authenticated
--   USING (auth.uid() = user_id)
--   WITH CHECK (auth.uid() = user_id);

-- -- Orders: read
-- CREATE POLICY orders_read ON public.orders
--   FOR SELECT TO authenticated
--   USING (
--     auth.uid() = buyer_id
--     OR auth.uid() = seller_id
--     OR auth.uid() = courier_id
--     OR auth.uid() = offered_courier_id
--     OR (status = 'readyForPickup' AND courier_id IS NULL)
--   );

-- -- Orders: insert by buyers
-- CREATE POLICY orders_insert_buyer ON public.orders
--   FOR INSERT TO authenticated
--   WITH CHECK (
--     auth.uid() = buyer_id
--     AND EXISTS (
--       SELECT 1
--       FROM public.profiles
--       WHERE id = auth.uid()
--         AND role = 'buyer'
--     )
--   );

-- -- Orders: participant updates
-- CREATE POLICY orders_update_participants ON public.orders
--   FOR UPDATE TO authenticated
--   USING (
--     auth.uid() = buyer_id
--     OR auth.uid() = seller_id
--     OR auth.uid() = courier_id
--     OR auth.uid() = offered_courier_id
--     OR (status = 'readyForPickup' AND courier_id IS NULL)
--   )
--   WITH CHECK (
--     auth.uid() = buyer_id
--     OR auth.uid() = seller_id
--     OR auth.uid() = courier_id
--     OR auth.uid() = offered_courier_id
--     OR (status = 'readyForPickup' AND courier_id IS NULL)
--   );

-- -- Order items: read
-- CREATE POLICY order_items_read ON public.order_items
--   FOR SELECT TO authenticated
--   USING (
--     EXISTS (
--       SELECT 1
--       FROM public.orders AS o
--       WHERE o.id = order_items.order_id
--         AND (
--           auth.uid() = o.buyer_id
--           OR auth.uid() = o.seller_id
--           OR auth.uid() = o.courier_id
--           OR auth.uid() = o.offered_courier_id
--           OR (o.status = 'readyForPickup' AND o.courier_id IS NULL)
--         )
--     )
--   );

-- -- Order items: insert by the order's buyer
-- CREATE POLICY order_items_write ON public.order_items
--   FOR INSERT TO authenticated
--   WITH CHECK (
--     EXISTS (
--       SELECT 1
--       FROM public.orders AS o
--       WHERE o.id = order_items.order_id
--         AND auth.uid() = o.buyer_id
--     )
--   );

-- -- Order events: read
-- CREATE POLICY order_events_read ON public.order_events
--   FOR SELECT TO authenticated
--   USING (
--     EXISTS (
--       SELECT 1
--       FROM public.orders AS o
--       WHERE o.id = order_events.order_id
--         AND (
--           auth.uid() = o.buyer_id
--           OR auth.uid() = o.seller_id
--           OR auth.uid() = o.courier_id
--           OR auth.uid() = o.offered_courier_id
--           OR (o.status = 'readyForPickup' AND o.courier_id IS NULL)
--         )
--     )
--   );

-- -- Order events: insert by a participant
-- CREATE POLICY order_events_insert ON public.order_events
--   FOR INSERT TO authenticated
--   WITH CHECK (
--     EXISTS (
--       SELECT 1
--       FROM public.orders AS o
--       WHERE o.id = order_events.order_id
--         AND (
--           auth.uid() = o.buyer_id
--           OR auth.uid() = o.seller_id
--           OR auth.uid() = o.courier_id
--           OR auth.uid() = o.offered_courier_id
--         )
--     )
--   );

-- -- Courier locations
-- CREATE POLICY courier_locations_read ON public.courier_locations
--   FOR SELECT TO authenticated
--   USING (true);

-- CREATE POLICY courier_locations_insert_own ON public.courier_locations
--   FOR INSERT TO authenticated
--   WITH CHECK (
--     auth.uid() = courier_id
--     AND EXISTS (
--       SELECT 1
--       FROM public.profiles
--       WHERE id = auth.uid()
--         AND role = 'courier'
--     )
--   );

-- CREATE POLICY courier_locations_update_own ON public.courier_locations
--   FOR UPDATE TO authenticated
--   USING (
--     auth.uid() = courier_id
--     AND EXISTS (
--       SELECT 1
--       FROM public.profiles
--       WHERE id = auth.uid()
--         AND role = 'courier'
--     )
--   )
--   WITH CHECK (
--     auth.uid() = courier_id
--     AND EXISTS (
--       SELECT 1
--       FROM public.profiles
--       WHERE id = auth.uid()
--         AND role = 'courier'
--     )
--   );

-- -- ---------------------------------------------------------------------------
-- -- 12. Prevent users from changing their own role through the app
-- -- ---------------------------------------------------------------------------
-- CREATE OR REPLACE FUNCTION public.prevent_profile_role_change()
-- RETURNS trigger
-- LANGUAGE plpgsql
-- SECURITY DEFINER
-- SET search_path = ''
-- AS $$
-- BEGIN
--   IF auth.uid() IS NOT NULL
--      AND NEW.role IS DISTINCT FROM OLD.role THEN
--     RAISE EXCEPTION 'Changing account role from the app is not allowed';
--   END IF;

--   RETURN NEW;
-- END;
-- $$;

-- DROP TRIGGER IF EXISTS profiles_prevent_role_change
--   ON public.profiles;

-- CREATE TRIGGER profiles_prevent_role_change
--   BEFORE UPDATE ON public.profiles
--   FOR EACH ROW
--   EXECUTE FUNCTION public.prevent_profile_role_change();

-- -- ---------------------------------------------------------------------------
-- -- 13. Realtime
-- -- ---------------------------------------------------------------------------
-- DO $$
-- BEGIN
--   ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
-- EXCEPTION
--   WHEN duplicate_object THEN NULL;
--   WHEN undefined_object THEN
--     RAISE NOTICE 'Publication supabase_realtime does not exist.';
-- END;
-- $$;

-- DO $$
-- BEGIN
--   ALTER PUBLICATION supabase_realtime ADD TABLE public.order_events;
-- EXCEPTION
--   WHEN duplicate_object THEN NULL;
--   WHEN undefined_object THEN
--     RAISE NOTICE 'Publication supabase_realtime does not exist.';
-- END;
-- $$;

-- DO $$
-- BEGIN
--   ALTER PUBLICATION supabase_realtime ADD TABLE public.courier_locations;
-- EXCEPTION
--   WHEN duplicate_object THEN NULL;
--   WHEN undefined_object THEN
--     RAISE NOTICE 'Publication supabase_realtime does not exist.';
-- END;
-- $$;

-- -- ---------------------------------------------------------------------------
-- -- 14. Initial categories
-- -- ---------------------------------------------------------------------------
-- INSERT INTO public.categories (id, name_ar, icon, sort_order)
-- VALUES
--   ('grocery',  'بقالة',       '🥫', 1),
--   ('fruits',   'فاكهة وخضار', '🍅', 2),
--   ('bakery',   'مخبوزات',     '🥖', 3),
--   ('drinks',   'مشروبات',     '🥤', 4),
--   ('cleaning', 'منظفات',      '🧼', 5),
--   ('other',    'منتجات أخرى', '🛍️', 6)
-- ON CONFLICT (id) DO NOTHING;

-- -- ---------------------------------------------------------------------------
-- -- 15. Storage bucket for product images
-- -- ---------------------------------------------------------------------------
-- INSERT INTO storage.buckets (
--   id,
--   name,
--   public,
--   file_size_limit,
--   allowed_mime_types
-- )
-- VALUES (
--   'product-images',
--   'product-images',
--   true,
--   5242880,
--   ARRAY[
--     'image/jpeg',
--     'image/png',
--     'image/webp',
--     'image/heic',
--     'image/heif'
--   ]
-- )
-- ON CONFLICT (id) DO UPDATE
-- SET
--   public = EXCLUDED.public,
--   file_size_limit = EXCLUDED.file_size_limit,
--   allowed_mime_types = EXCLUDED.allowed_mime_types;

-- DROP POLICY IF EXISTS product_images_read ON storage.objects;
-- CREATE POLICY product_images_read ON storage.objects
--   FOR SELECT TO anon, authenticated
--   USING (bucket_id = 'product-images');

-- DROP POLICY IF EXISTS product_images_insert ON storage.objects;
-- CREATE POLICY product_images_insert ON storage.objects
--   FOR INSERT TO authenticated
--   WITH CHECK (
--     bucket_id = 'product-images'
--     AND (storage.foldername(name))[1] = 'products'
--     AND (storage.foldername(name))[2] = auth.uid()::text
--     AND EXISTS (
--       SELECT 1
--       FROM public.profiles
--       WHERE id = auth.uid()
--         AND role = 'seller'
--     )
--   );

-- -- ---------------------------------------------------------------------------
-- -- 16. Table grants
-- -- ---------------------------------------------------------------------------
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
-- GRANT SELECT, INSERT, UPDATE, DELETE
--   ON ALL TABLES IN SCHEMA public TO authenticated;

-- ALTER DEFAULT PRIVILEGES IN SCHEMA public
--   GRANT SELECT ON TABLES TO anon;

-- ALTER DEFAULT PRIVILEGES IN SCHEMA public
--   GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

-- -- Refresh PostgREST schema cache.
-- NOTIFY pgrst, 'reload schema';

-- COMMIT;
