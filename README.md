# DepoF - Depo Yönetim Sistemi

DepoF, müşteri odaklı bir mobil depo yönetim uygulamasıdır. Bu uygulama, müşterilerden gelen ürünlerin depoya girişini, yönetici onay süreçlerini, depodaki stokların müşteri ve ürün bazında takibini, kontrollü ürün çıkışını, genel depo kapasite takibini ve rol bazlı erişimle temel raporlamayı yönetir.

## Özellikler

- **Kullanıcı Rolleri:** Admin ve Employee rolleri ile yetkilendirme
- **Müşteri Yönetimi:** Müşteri ekleme, düzenleme, silme, listeleme
- **Depo Yönetimi:** Depo ve kat yönetimi, kapasite takibi
- **Ürün Yönetimi:** Ürün ekleme, düzenleme, silme, listeleme
- **Stok İşlemleri:**
  - Ürün girişi (employee tarafından talep, admin tarafından onay)
  - Ürün çıkışı (admin tarafından)
  - Müşteri ve ürün bazlı stok takibi
  - Giriş/çıkış tarihleri ile birlikte stok hareketi izleme
- **Raporlama:** Temel stok ve kapasite raporları
- **Gerçek Zamanlı Görüntüleme:** Depo doluluğu ve stok durumunun grafiklerle gösterimi

## Teknik Altyapı

- **Frontend:** Flutter (State Management: Riverpod, Navigation: GoRouter)
- **Backend:** Supabase (Authentication, Database, RPC Functions, Realtime)
- **Veritabanı:** PostgreSQL
- **Kimlik Doğrulama:** Supabase Auth
- **Grafikler:** fl_chart

## Proje Kurulumu

### Gereksinimler

- Flutter SDK (en son sürüm)
- Supabase hesabı

### Kurulum Adımları

1. Projeyi klonlayın:
   ```
   git clone https://github.com/yourusername/depof.git
   cd depof
   ```

2. Bağımlılıkları yükleyin:
   ```
   flutter pub get
   ```

3. Supabase kurulumu:
   - Supabase'de yeni bir proje oluşturun
   - Supabase SQL Editor'de `schema.sql` dosyasını çalıştırın
   - `lib/core/constants/app_constants.dart` dosyasında Supabase URL ve anahtarlarını güncelleyin:
     ```dart
     static const String supabaseUrl = 'YOUR_SUPABASE_URL';
     static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
     ```

4. Uygulamayı çalıştırın:
   ```
   flutter run
   ```

## Veri Modeli

Sistem aşağıdaki tabloları içerir:

- `customers`: Müşteri bilgileri
- `warehouses`: Depo bilgileri
- `floors`: Depo katları
- `products`: Ürün bilgileri
- `profiles`: Kullanıcı profilleri ve rolleri
- `pending_entries`: Onay bekleyen girişler
- `inventory_transactions`: Stok hareketleri (giriş/çıkış)
- `audit_logs`: Denetim kayıtları

## Lisans

Bu proje [MIT Lisansı](LICENSE) ile lisanslanmıştır. 

flutter pub run build_runner build --delete-conflicting-outputs 