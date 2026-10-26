-- -- ============================================================================
-- -- Delivery Elbalad - stock helpers
-- -- شغّل الملف ده في Supabase SQL Editor (أو احفظه كـ migration).
-- --
-- -- المشتري محتاج ينقص مخزون منتجات البائع عند تأكيد الطلب، وده مش مسموح ليه
-- -- مباشرة بسبب RLS. الدوال دي بتشتغل Security Definer وبتنفذ النقص/الزيادة
-- -- بشكل ذرّي وآمن (مش بتسمح بالمخزون السالب).
-- -- ============================================================================

-- create or replace function public.decrement_product_stock(
--   p_product_id text,
--   p_quantity integer
-- )
-- returns void
-- language plpgsql
-- security definer
-- set search_path = public
-- as $$
-- begin
--   if p_quantity is null or p_quantity <= 0 then
--     raise exception 'INVALID_QUANTITY';
--   end if;

--   update public.products
--      set stock = stock - p_quantity,
--          updated_at = now()
--    where id = p_product_id
--      and stock >= p_quantity;

--   if not found then
--     raise exception 'INSUFFICIENT_STOCK';
--   end if;
-- end;
-- $$;

-- create or replace function public.increment_product_stock(
--   p_product_id text,
--   p_quantity integer
-- )
-- returns void
-- language plpgsql
-- security definer
-- set search_path = public
-- as $$
-- begin
--   if p_quantity is null or p_quantity <= 0 then
--     raise exception 'INVALID_QUANTITY';
--   end if;

--   update public.products
--      set stock = stock + p_quantity,
--          updated_at = now()
--    where id = p_product_id;
-- end;
-- $$;

-- grant execute on function public.decrement_product_stock(text, integer)
--   to anon, authenticated;
-- grant execute on function public.increment_product_stock(text, integer)
--   to anon, authenticated;

-- -- اختياري: منع أي تحديث مباشر يخلّي المخزون سالب.
-- create or replace function public.prevent_negative_stock()
-- returns trigger
-- language plpgsql
-- as $$
-- begin
--   if new.stock < 0 then
--     raise exception 'INSUFFICIENT_STOCK';
--   end if;
--   return new;
-- end;
-- $$;

-- drop trigger if exists products_prevent_negative_stock on public.products;
-- create trigger products_prevent_negative_stock
-- before insert or update of stock on public.products
-- for each row execute function public.prevent_negative_stock();
