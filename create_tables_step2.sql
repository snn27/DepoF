-- 5. Depolar tablosunu oluştur
CREATE TABLE IF NOT EXISTS warehouses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  total_capacity DOUBLE PRECISION DEFAULT 0,
  current_stock DOUBLE PRECISION DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. Katlar tablosunu oluştur
CREATE TABLE IF NOT EXISTS floors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
  floor_number INTEGER NOT NULL,
  name TEXT NOT NULL,
  area DOUBLE PRECISION NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(warehouse_id, floor_number)
);

-- 7. Stok hareketleri tablosunu oluştur
CREATE TABLE IF NOT EXISTS inventory_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID NOT NULL REFERENCES products(id),
  warehouse_id UUID NOT NULL REFERENCES warehouses(id),
  floor_id UUID REFERENCES floors(id),
  transaction_type TEXT NOT NULL,
  quantity DOUBLE PRECISION NOT NULL,
  balance DOUBLE PRECISION NOT NULL,
  unit_price DOUBLE PRECISION,
  total_price DOUBLE PRECISION,
  reference_id TEXT,
  customer_id UUID REFERENCES customers(id),
  notes TEXT,
  status TEXT DEFAULT 'pending',
  created_by UUID REFERENCES profiles(user_id),
  approved_by UUID REFERENCES profiles(user_id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT transaction_type_check CHECK (transaction_type IN ('entry', 'dispatch', 'transfer', 'adjustment')),
  CONSTRAINT status_check CHECK (status IN ('pending', 'approved', 'rejected', 'completed'))
); 