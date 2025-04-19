-- Mevcut tetikleyiciyi kaldır
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Tetikleyici fonksiyonunu güncelle
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- profiles tablosunun doğru şemasına göre veri ekle
  -- (email sütunu yok, sadece user_id, role ve full_name kullan)
  INSERT INTO profiles (user_id, role, full_name) 
  VALUES (NEW.id, 'employee', NEW.raw_user_meta_data->>'full_name');
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Tetikleyiciyi yeniden oluştur
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE handle_new_user(); 