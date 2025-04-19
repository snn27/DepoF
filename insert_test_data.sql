-- Test verileri ekleme

-- 1. Test Müşterisi Ekle
INSERT INTO customers (first_name, last_name, phone, address, tax_id) 
VALUES 
  ('Ahmet', 'Yılmaz', '0555-111-22-33', 'İstanbul, Kadıköy', '12345678901'),
  ('Ayşe', 'Kaya', '0532-222-33-44', 'Ankara, Çankaya', '98765432109');

-- 2. Test Ürünleri Ekle
INSERT INTO products (sku, name, category, unit, min_stock_level) 
VALUES 
  ('P001', 'Buğday', 'Tahıl', 'ton', 5.0),
  ('P002', 'Arpa', 'Tahıl', 'ton', 3.0),
  ('P003', 'Mısır', 'Tahıl', 'ton', 4.0);

-- 3. Test Depo Ekle
INSERT INTO warehouses (name, address, phone, total_capacity, current_stock) 
VALUES 
  ('Ana Depo', 'İstanbul, Tuzla Sanayi Bölgesi', '0216-555-44-33', 1000.0, 0.0),
  ('Bölge Depo', 'Kocaeli, Gebze', '0262-444-55-66', 750.0, 0.0);

-- 4. Test Katları Ekle
INSERT INTO floors (warehouse_id, floor_number, name, area) 
VALUES 
  ((SELECT id FROM warehouses WHERE name = 'Ana Depo'), 1, 'Zemin Kat', 500.0),
  ((SELECT id FROM warehouses WHERE name = 'Ana Depo'), 2, 'Üst Kat', 500.0),
  ((SELECT id FROM warehouses WHERE name = 'Bölge Depo'), 1, 'Zemin Kat', 750.0);

-- 5. Admin kullanıcısı oluşturmak istiyorsanız, önce auth.users tablosuna 
-- kullanıcı ekleyip sonra bu sorguyu çalıştırın:
-- UPDATE profiles 
-- SET role = 'admin' 
-- WHERE user_id = 'KULLANICI_ID_BURAYA'; 