-- Düzeltilmiş test verileri (mevcut şemaya uygun)

-- 1. Test Müşterileri
INSERT INTO customers (first_name, last_name, phone, district, village, tc_kimlik_no) 
VALUES 
  ('Ahmet', 'Yılmaz', '0555-111-22-33', 'Kadıköy', 'Merkez', '12345678901'),
  ('Ayşe', 'Kaya', '0532-222-33-44', 'Çankaya', 'Bahçelievler', '98765432109');

-- 2. Test Ürünleri
INSERT INTO products (sku, name, category, unit, min_stock_level) 
VALUES 
  ('P001', 'Buğday', 'Tahıl', 'ton', 5.0),
  ('P002', 'Arpa', 'Tahıl', 'ton', 3.0),
  ('P003', 'Mısır', 'Tahıl', 'ton', 4.0);

-- 3. Test Depolar
INSERT INTO warehouses (name, total_capacity, capacity_unit, current_stock) 
VALUES 
  ('Ana Depo', 1000.0, 'ton', 0.0),
  ('Bölge Depo', 750.0, 'ton', 0.0);

-- 4. Test Katlar
INSERT INTO floors (warehouse_id, floor_number, name) 
VALUES 
  ((SELECT id FROM warehouses WHERE name = 'Ana Depo'), 1, 'Zemin Kat'),
  ((SELECT id FROM warehouses WHERE name = 'Ana Depo'), 2, 'Üst Kat'),
  ((SELECT id FROM warehouses WHERE name = 'Bölge Depo'), 1, 'Zemin Kat');

-- 5. Admin kullanıcısı oluşturmak için
-- Not: Önce auth.users tablosuna bir kullanıcı ekleyin, sonra şunu çalıştırın:
-- UPDATE profiles 
-- SET role = 'admin' 
-- WHERE user_id = 'KULLANICI_ID_BURAYA'; 