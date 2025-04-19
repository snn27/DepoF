-- Bu sorgu, Supabase'de admin kullanıcısı oluşturmak için kullanılır
-- Önce, kullanıcıyı Supabase Dashboard'dan oluşturun, ardından aşağıdaki sorguyu çalıştırın.

-- E-posta ile kullanıcı bulma:
SELECT id, email
FROM auth.users
WHERE email = 'BURAYA_EMAIL_ADRESI_YAZIN';

-- Kullanıcıya admin rolü verme (id'yi üstteki sorgudan alın):
UPDATE profiles
SET role = 'admin'
WHERE user_id = 'BURAYA_KULLANICI_ID_YAZIN';

-- Kullanıcının rolünü doğrulama:
SELECT user_id, full_name, role
FROM profiles
WHERE user_id = 'BURAYA_KULLANICI_ID_YAZIN';

-- Eğer kullanıcının profili oluşmadıysa (trigger çalışmadıysa), manuel olarak oluşturun:
-- INSERT INTO profiles (user_id, full_name, role)
-- SELECT id, COALESCE(raw_user_meta_data->>'full_name', email), 'admin'
-- FROM auth.users
-- WHERE id = 'BURAYA_KULLANICI_ID_YAZIN'; 