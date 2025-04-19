# DepoF - Kullanıcı Yönetimi Rehberi

Bu rehber, DepoF uygulaması için Supabase'de admin ve çalışan kullanıcılarını oluşturma ve yönetme sürecini açıklar.

## 1. Supabase Authentication Ayarları

Öncelikle, Supabase'de Authentication ayarlarının doğru yapılandırıldığından emin olun:

1. Supabase Dashboard'a giriş yapın
2. Sol menüden "Authentication" seçeneğine tıklayın
3. "Settings" alt sekmesine gidin
4. "Email Auth" bölümünde "Enable Email Signup" seçeneğinin açık olduğundan emin olun
5. Aynı sayfada "Redirect URLs" alanına uygulamanızın URL'sini ekleyin (veya localhost için `http://localhost:3000`)

## 2. Admin Kullanıcısı Oluşturma

### Adım 1: Kullanıcıyı Oluşturun
1. Supabase Dashboard'da "Authentication" sekmesine gidin
2. "Users" alt sekmesini seçin
3. "Invite" butonuna tıklayın
4. Geçerli bir e-posta adresi ve şifre girin (gerçek test için kullanabileceğiniz bir e-posta)
5. "Send" butonuna tıklayın

### Adım 2: Kullanıcıya Admin Rolü Verin
1. Kullanıcı oluşturulduktan sonra, kullanıcı listesinden yeni oluşturulan kullanıcıyı bulun
2. User ID'sini kopyalayın (UUID formatında olacak)
3. SQL Editor'e gidin ve aşağıdaki sorguyu çalıştırın:

```sql
UPDATE profiles 
SET role = 'admin' 
WHERE user_id = 'BURAYA_KULLANICI_ID_YAZIN';
```

## 3. Çalışan (Employee) Kullanıcısı Oluşturma

### Adım 1: Kullanıcıyı Oluşturun
1. Supabase Dashboard'da "Authentication" sekmesine gidin
2. "Users" alt sekmesini seçin
3. "Invite" butonuna tıklayın
4. Geçerli bir e-posta adresi ve şifre girin
5. "Send" butonuna tıklayın

### Adım 2: Çalışan Rolünün Kontrol Edilmesi
Otomatik olarak, yeni oluşturulan tüm kullanıcılar employee rolüne sahip olacaktır. Eğer kontrol etmek isterseniz:

```sql
SELECT user_id, role, full_name 
FROM profiles 
WHERE user_id = 'BURAYA_KULLANICI_ID_YAZIN';
```

## 4. Kullanıcı Bilgilerini Güncelleme (İsim, vb.)

Kullanıcının adını veya diğer bilgilerini güncellemek için:

```sql
UPDATE profiles 
SET full_name = 'Yeni İsim Soyisim' 
WHERE user_id = 'BURAYA_KULLANICI_ID_YAZIN';
```

## 5. Şifre Sıfırlama

Bir kullanıcının şifresini sıfırlamanız gerekirse:

1. Supabase Dashboard'da "Authentication" > "Users" bölümüne gidin
2. İlgili kullanıcıyı bulun
3. "..." menüsüne tıklayın ve "Reset password" seçeneğini seçin
4. Kullanıcıya şifre sıfırlama e-postası gönderilecektir

## 6. Uygulama İçi Kullanıcı Kaydı

Uygulamanızda kullanıcı kaydı sayfası yapılandırmak istiyorsanız, uygulamanızdaki Sign Up formundan gelen verileri Supabase Authentication API'sine göndermelisiniz. Bu işlemler zaten auth_service.dart içinde yapılandırılmıştır.

## 7. Sorun Giderme

Kullanıcı oluşturma veya rollerini atama sırasında sorunlar yaşıyorsanız, şunları kontrol edin:

1. Profiles tablosunun doğru yapılandırıldığından emin olun:
```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'profiles';
```

2. Trigger fonksiyonunun doğru çalıştığından emin olun:
```sql
-- Bu şekilde güncellendi:
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (user_id, role, full_name) 
  VALUES (NEW.id, 'employee', NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

Bu rehber, DepoF uygulamanızın kullanıcı yönetimi için temel adımları içermektedir. Daha fazla bilgi için Supabase belgeleri ve Flutter entegrasyonu hakkında daha fazla bilgi edinin. 