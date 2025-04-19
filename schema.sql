-- Gerekli Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;

-- Müşteriler Tablosu
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    phone TEXT,
    district TEXT,
    village TEXT,
    tc_kimlik_no TEXT, -- Nullable, ileride eklenecek, KVKK!
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
COMMENT ON COLUMN customers.tc_kimlik_no IS 'İleride eklenecek TC Kimlik No, KVKK''ya dikkat!';

-- Depolar Tablosu
CREATE TABLE warehouses (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    name TEXT UNIQUE NOT NULL,
    total_capacity NUMERIC NOT NULL CHECK (total_capacity > 0),
    capacity_unit TEXT NOT NULL,
    current_stock NUMERIC NOT NULL DEFAULT 0 CHECK (current_stock >= 0), -- Deponun genel fiziksel doluluğu
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Katlar Tablosu
CREATE TABLE floors (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
    floor_number INT NOT NULL,
    name TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE (warehouse_id, floor_number)
);

-- Ürünler Tablosu
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    sku TEXT UNIQUE NOT NULL, -- Barkod/QR için temel
    name TEXT NOT NULL,
    category TEXT,
    unit TEXT NOT NULL,
    min_stock_level NUMERIC CHECK (min_stock_level >= 0), -- Genel ürün uyarısı için
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Kullanıcı Profilleri ve Rolleri Tablosu
CREATE TABLE profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('admin', 'employee')),
    full_name TEXT,
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Onay Bekleyen Girişler Tablosu (Müşteri Bağlantılı)
CREATE TABLE pending_entries (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT, -- Müşteri bağlantısı eklendi
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE RESTRICT,
    floor_id UUID NOT NULL REFERENCES floors(id) ON DELETE RESTRICT,
    quantity NUMERIC NOT NULL CHECK (quantity > 0),
    unit TEXT NOT NULL,
    requested_by_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    request_timestamp TIMESTAMPTZ DEFAULT now() NOT NULL,
    approval_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    approval_timestamp TIMESTAMPTZ,
    notes TEXT
);

-- Stok Hareketleri Tablosu (Merkezi Log - Müşteri Bağlantılı)
CREATE TABLE inventory_transactions (
    id BIGSERIAL PRIMARY KEY,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT, -- Müşteri bağlantısı eklendi
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE RESTRICT,
    floor_id UUID NOT NULL REFERENCES floors(id) ON DELETE RESTRICT,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('approved_entry', 'dispatch', 'correction_plus', 'correction_minus')),
    quantity NUMERIC NOT NULL, -- Giriş: +, Çıkış: -
    transaction_date TIMESTAMPTZ DEFAULT now() NOT NULL, -- Giriş/Çıkış tarihi
    related_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
    pending_entry_id UUID REFERENCES pending_entries(id) ON DELETE SET NULL,
    notes TEXT
);

-- Audit Logları Tablosu
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    details JSONB,
    timestamp TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- İndeksler
CREATE INDEX idx_transactions_customer_product ON inventory_transactions(customer_id, product_id);
CREATE INDEX idx_transactions_date ON inventory_transactions(transaction_date);
CREATE INDEX idx_pending_entries_status ON pending_entries(status);
CREATE INDEX idx_pending_entries_requested_by ON pending_entries(requested_by_user_id);

-- Önce mevcut trigger'ı kaldır
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Trigger fonksiyonunu güncelle
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (user_id, full_name, email, role)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name', NEW.email, 'employee');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger'ı yeniden oluştur
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE handle_new_user();

-- Depo stok güncelleme fonksiyonu
CREATE OR REPLACE FUNCTION update_warehouse_stock(warehouse_id UUID, quantity_change NUMERIC)
RETURNS void AS $$
BEGIN
  -- Atomik olarak depo stoğunu güncelle
  UPDATE warehouses
  SET current_stock = current_stock + quantity_change
  WHERE id = warehouse_id;
  
  -- Eğer stok sıfırın altına düşerse hata döndür
  IF (SELECT current_stock FROM warehouses WHERE id = warehouse_id) < 0 THEN
    RAISE EXCEPTION 'Warehouse stock cannot be negative';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Giriş onayı tetikleyicisi fonksiyonu
CREATE OR REPLACE FUNCTION handle_entry_approval()
RETURNS TRIGGER AS $$
DECLARE
  entry_customer_id UUID;
  entry_product_id UUID;
  entry_warehouse_id UUID;
  entry_floor_id UUID;
  entry_quantity NUMERIC;
  entry_unit TEXT;
BEGIN
  -- Sadece 'pending' durumundan 'approved' durumuna geçişleri işle
  IF OLD.status = 'pending' AND NEW.status = 'approved' THEN
    -- Onay bilgilerini güncelle
    NEW.approval_timestamp = now();
    
    -- Gereken alanları değişkenlere ata
    entry_customer_id := NEW.customer_id;
    entry_product_id := NEW.product_id;
    entry_warehouse_id := NEW.warehouse_id;
    entry_floor_id := NEW.floor_id;
    entry_quantity := NEW.quantity;
    entry_unit := NEW.unit;
    
    -- Stok hareketleri tablosuna giriş kaydı ekle
    INSERT INTO inventory_transactions (
      customer_id,
      product_id,
      warehouse_id,
      floor_id,
      transaction_type,
      quantity,
      related_user_id,
      pending_entry_id,
      notes
    )
    VALUES (
      entry_customer_id,
      entry_product_id,
      entry_warehouse_id,
      entry_floor_id,
      'approved_entry',
      entry_quantity,
      NEW.approval_user_id,
      NEW.id,
      'Onaylanan giriş talebi'
    );
    
    -- Depo stoğunu güncelle
    PERFORM update_warehouse_stock(entry_warehouse_id, entry_quantity);
    
    -- Audit log kaydı ekle
    INSERT INTO audit_logs (user_id, action, details)
    VALUES (
      NEW.approval_user_id,
      'entry_approved',
      json_build_object(
        'pending_entry_id', NEW.id,
        'product_id', entry_product_id,
        'customer_id', entry_customer_id,
        'quantity', entry_quantity
      )
    );
  END IF;
  
  -- Eğer red durumuna geçilmişse, sadece onay bilgisini güncelle
  IF OLD.status = 'pending' AND NEW.status = 'rejected' THEN
    NEW.approval_timestamp = now();
    
    -- Audit log kaydı ekle
    INSERT INTO audit_logs (user_id, action, details)
    VALUES (
      NEW.approval_user_id,
      'entry_rejected',
      json_build_object(
        'pending_entry_id', NEW.id,
        'product_id', NEW.product_id,
        'customer_id', NEW.customer_id,
        'quantity', NEW.quantity
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Giriş onayı tetikleyicisi
CREATE TRIGGER on_pending_entry_status_change
BEFORE UPDATE OF status ON pending_entries
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION handle_entry_approval();

-- Stok çıkış RPC fonksiyonu
CREATE OR REPLACE FUNCTION create_dispatch(
  p_customer_id UUID,
  p_product_id UUID,
  p_warehouse_id UUID,
  p_floor_id UUID,
  p_quantity NUMERIC,
  p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_user_id UUID;
  v_customer_stock NUMERIC;
  v_transaction_id BIGINT;
BEGIN
  -- Geçerli kullanıcı ID'sini al
  v_current_user_id := auth.uid();
  
  -- Geçerli kullanıcı yoksa hata döndür
  IF v_current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Negatif miktar kontrolü
  IF p_quantity <= 0 THEN
    RAISE EXCEPTION 'Quantity must be positive';
  END IF;
  
  -- Müşterinin ilgili ürün için toplam stok miktarını hesapla
  SELECT COALESCE(SUM(
    CASE WHEN transaction_type IN ('approved_entry', 'correction_plus') THEN quantity
         WHEN transaction_type IN ('dispatch', 'correction_minus') THEN -quantity
         ELSE 0
    END
  ), 0)
  INTO v_customer_stock
  FROM inventory_transactions
  WHERE customer_id = p_customer_id
    AND product_id = p_product_id;
    
  -- Yetersiz stok kontrolü
  IF v_customer_stock < p_quantity THEN
    RAISE EXCEPTION 'Insufficient stock. Available: %, Requested: %', v_customer_stock, p_quantity;
  END IF;
  
  -- Stok hareketi oluştur (negatif miktar kullan)
  INSERT INTO inventory_transactions (
    customer_id,
    product_id,
    warehouse_id,
    floor_id,
    transaction_type,
    quantity,
    related_user_id,
    notes
  )
  VALUES (
    p_customer_id,
    p_product_id,
    p_warehouse_id,
    p_floor_id,
    'dispatch',
    p_quantity,
    v_current_user_id,
    p_notes
  )
  RETURNING id INTO v_transaction_id;
  
  -- Depo stoğunu azalt
  PERFORM update_warehouse_stock(p_warehouse_id, -p_quantity);
  
  -- Audit log kaydı ekle
  INSERT INTO audit_logs (user_id, action, details)
  VALUES (
    v_current_user_id,
    'product_dispatched',
    json_build_object(
      'transaction_id', v_transaction_id,
      'product_id', p_product_id,
      'customer_id', p_customer_id,
      'quantity', p_quantity
    )
  );
  
  -- Başarılı sonuç döndür
  RETURN json_build_object(
    'success', true,
    'transaction_id', v_transaction_id,
    'remaining_stock', v_customer_stock - p_quantity,
    'message', 'Product dispatched successfully'
  );
  
EXCEPTION WHEN OTHERS THEN
  -- Hata durumunda
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$;

-- Denetim günlüğü için örnek bir trigger fonksiyonu
CREATE OR REPLACE FUNCTION log_customer_change()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO audit_logs (action, details)
    VALUES (
      'customer_created',
      json_build_object('customer_id', NEW.id, 'name', NEW.first_name || ' ' || NEW.last_name)
    );
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO audit_logs (action, details)
    VALUES (
      'customer_updated',
      json_build_object(
        'customer_id', NEW.id,
        'old_name', OLD.first_name || ' ' || OLD.last_name,
        'new_name', NEW.first_name || ' ' || NEW.last_name
      )
    );
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO audit_logs (action, details)
    VALUES (
      'customer_deleted',
      json_build_object('customer_id', OLD.id, 'name', OLD.first_name || ' ' || OLD.last_name)
    );
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Müşteri değişiklikleri için denetim günlüğü tetikleyicisi
CREATE TRIGGER audit_customer_changes
AFTER INSERT OR UPDATE OR DELETE ON customers
FOR EACH ROW EXECUTE FUNCTION log_customer_change();

-- Row Level Security (RLS) Policies

-- RLS'yi tüm tablolarda etkinleştir
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE warehouses ENABLE ROW LEVEL SECURITY;
ALTER TABLE floors ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE pending_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Kullanıcı rolünü getiren yardımcı fonksiyon
CREATE OR REPLACE FUNCTION get_user_role(user_id uuid)
RETURNS TEXT AS $$
DECLARE
  user_role TEXT;
BEGIN
  SELECT role INTO user_role FROM profiles WHERE user_id = user_id;
  RETURN user_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- customers tablosu için politikalar
CREATE POLICY customers_select_policy ON customers
  FOR SELECT USING (true); -- Tüm kullanıcılar okuyabilir

CREATE POLICY customers_insert_policy ON customers
  FOR INSERT WITH CHECK (get_user_role(auth.uid()) = 'admin'); -- Sadece admin ekleyebilir

CREATE POLICY customers_update_policy ON customers
  FOR UPDATE USING (get_user_role(auth.uid()) = 'admin'); -- Sadece admin güncelleyebilir

CREATE POLICY customers_delete_policy ON customers
  FOR DELETE USING (get_user_role(auth.uid()) = 'admin'); -- Sadece admin silebilir

-- warehouses tablosu için politikalar
CREATE POLICY warehouses_select_policy ON warehouses
  FOR SELECT USING (true); -- Tüm kullanıcılar okuyabilir

CREATE POLICY warehouses_insert_policy ON warehouses
  FOR INSERT WITH CHECK (get_user_role(auth.uid()) = 'admin'); -- Sadece admin ekleyebilir

CREATE POLICY warehouses_update_policy ON warehouses
  FOR UPDATE USING (get_user_role(auth.uid()) = 'admin'); -- Sadece admin güncelleyebilir

CREATE POLICY warehouses_delete_policy ON warehouses
  FOR DELETE USING (get_user_role(auth.uid()) = 'admin'); -- Sadece admin silebilir

-- floors tablosu için politikalar - warehouses ile aynı politikalar
CREATE POLICY floors_select_policy ON floors
  FOR SELECT USING (true);

CREATE POLICY floors_insert_policy ON floors
  FOR INSERT WITH CHECK (get_user_role(auth.uid()) = 'admin');

CREATE POLICY floors_update_policy ON floors
  FOR UPDATE USING (get_user_role(auth.uid()) = 'admin');

CREATE POLICY floors_delete_policy ON floors
  FOR DELETE USING (get_user_role(auth.uid()) = 'admin');

-- products tablosu için politikalar - warehouses ile aynı politikalar
CREATE POLICY products_select_policy ON products
  FOR SELECT USING (true);

CREATE POLICY products_insert_policy ON products
  FOR INSERT WITH CHECK (get_user_role(auth.uid()) = 'admin');

CREATE POLICY products_update_policy ON products
  FOR UPDATE USING (get_user_role(auth.uid()) = 'admin');

CREATE POLICY products_delete_policy ON products
  FOR DELETE USING (get_user_role(auth.uid()) = 'admin');

-- profiles tablosu için politikalar
CREATE POLICY profiles_select_policy ON profiles
  FOR SELECT USING (
    auth.uid() = user_id OR  -- Kullanıcı kendi profilini görebilir
    get_user_role(auth.uid()) = 'admin' -- Veya admin tüm profilleri görebilir
  );

CREATE POLICY profiles_update_policy ON profiles
  FOR UPDATE USING (
    auth.uid() = user_id OR  -- Kullanıcı kendi profilini güncelleyebilir
    get_user_role(auth.uid()) = 'admin' -- Veya admin herhangi bir profili güncelleyebilir
  );

-- pending_entries tablosu için politikalar
CREATE POLICY pending_entries_select_policy ON pending_entries
  FOR SELECT USING (
    get_user_role(auth.uid()) = 'admin' OR  -- Admin hepsini görebilir
    (get_user_role(auth.uid()) = 'employee' AND requested_by_user_id = auth.uid()) -- Employee sadece kendi girişlerini görür
  );

CREATE POLICY pending_entries_insert_policy ON pending_entries
  FOR INSERT WITH CHECK (true); -- Tüm kullanıcılar giriş talebi oluşturabilir

CREATE POLICY pending_entries_update_policy ON pending_entries
  FOR UPDATE USING (
    get_user_role(auth.uid()) = 'admin' OR -- Admin hepsini güncelleyebilir
    (get_user_role(auth.uid()) = 'employee' AND requested_by_user_id = auth.uid() AND status = 'pending') -- Employee sadece kendi bekleyen girişlerini güncelleyebilir
  );

CREATE POLICY pending_entries_delete_policy ON pending_entries
  FOR DELETE USING (
    get_user_role(auth.uid()) = 'admin' OR -- Admin hepsini silebilir
    (get_user_role(auth.uid()) = 'employee' AND requested_by_user_id = auth.uid() AND status = 'pending') -- Employee sadece kendi bekleyen girişlerini silebilir
  );

-- inventory_transactions tablosu için politikalar
CREATE POLICY inventory_transactions_select_policy ON inventory_transactions
  FOR SELECT USING (true); -- Tüm kullanıcılar stok hareketlerini görebilir

CREATE POLICY inventory_transactions_insert_policy ON inventory_transactions
  FOR INSERT WITH CHECK (
    get_user_role(auth.uid()) = 'admin' -- Sadece admin manuel stok hareketi ekleyebilir
  );

CREATE POLICY inventory_transactions_update_policy ON inventory_transactions
  FOR UPDATE USING (
    get_user_role(auth.uid()) = 'admin' -- Sadece admin stok hareketlerini güncelleyebilir
  );

CREATE POLICY inventory_transactions_delete_policy ON inventory_transactions
  FOR DELETE USING (
    get_user_role(auth.uid()) = 'admin' -- Sadece admin stok hareketlerini silebilir
  );

-- audit_logs tablosu için politikalar
CREATE POLICY audit_logs_select_policy ON audit_logs
  FOR SELECT USING (
    get_user_role(auth.uid()) = 'admin' -- Sadece admin audit logları görebilir
  );

-- Varsayılan admin kullanıcısı oluşturmak için (uygulama ilk kurulumunda)
-- NOT: Bu kodu güvenlik gereği yalnızca bir kez çalıştırın, daha sonra silin veya yorumlayın
/*
INSERT INTO auth.users (id, email, email_confirmed_at, raw_user_meta_data)
VALUES (
  extensions.uuid_generate_v4(),
  'admin@example.com',
  now(),
  '{"full_name":"Admin User"}'
);

-- Admin kullanıcısına admin rolü ver
UPDATE profiles
SET role = 'admin'
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'admin@example.com');
*/