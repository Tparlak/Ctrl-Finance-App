# Ctrl - AI Destekli Premium Kişisel Finans Takip Uygulaması 🚀

<div align="center">
  <img src="docs/images/dashboard.png" alt="Ctrl Dashboard" width="800"/>
</div>

**Ctrl**, modern VIP estetiği, cam (glassmorphism) tasarımı ve **Yapay Zeka Destekli OCR (Optik Karakter Tanıma)** teknolojisi ile geliştirilmiş, en gelişmiş kişisel finans yönetim uygulamasıdır. Gelir, gider, sabit masraflarınızı, hesaplarınızı ve kredi kartlarınızı şık, güvenli ve akıllı bir şekilde takip etmeniz için tasarlanmıştır.

## ✨ Öne Çıkan Özellikler

- 💎 **VIP & Glassmorphism Tasarım**: Karanlık mod odaklı, altın ve neon vurgulara sahip premium kullanıcı deneyimi sunan akıcı ve fütüristik arayüz.
- 🤖 **Yapay Zeka Destekli Fiş Tarama (OCR)**: Market veya akaryakıt fişlerinizi telefonunuzun kamerasıyla tarayın. Ctrl, market/yakıt istasyonu adını, *ürünlerin listesini ve fiyatlarını* otomatik olarak okur ve kategorize ederek işleminizin açıklamasına ekler.
- 📊 **Akıllı Dashboard**: Mevcut bakiyenizi, o ayki toplam gelirinizi ve giderlerinizi anlık ve grafiksel olarak görün.
- 🏦 **Gelişmiş Hesap Yönetimi**: Birden fazla hesap (Nakit, Banka Kartı, Kredi Kartı, Birikim) tanımlayın. Bakiyeleri isterseniz genel toplama dahil edin, isterseniz gizleyin.
- 🗂️ **Hiyerarşik Alt Kategorizasyon**: Harcamalarınızı (Örn: Mutfak > Market) alt kategorilerle detaylı olarak ayrıştırın.
- 🗓️ **Sabit Masraflar ve Güçlü Hatırlatıcılar**: Kira, faturalar veya kredi taksitlerinizi kaydedin. **Android 12+ için Exact Alarm** (Tam Zamanlı Alarm) entegrasyonu sayesinde, hatırlatmalarınız tam zamanında ekranınıza bildirim olarak düşer. İşlemleri tek tıkla otomatik ödeyin.
- 🔒 **Güvenlik ve Gizlilik**: Ctrl Security App Lock özelliği sayesinde uygulamanız şifrelidir. Verileriniz Hive veritabanı ile sadece **yerel cihazınızda** saklanır; internete hiçbir veri gitmez.

---

### AI Fiş ve Fatura Okuma (Smart Scanner)
<div align="center">
  <img src="docs/images/ocr.png" alt="Fiş Tarama ve OCR" width="800"/>
</div>

Yenilenen yapay zeka entegrasyonu sayesinde harcamaları elle girmeye son. Fişinizi tarattığınızda sistem satırları okur, gereksiz "Vergi, KDV" yazılarını eler, fişteki market ismini ve satın aldığınız her bir ürünü fiyatıyla beraber veritabanına kaydeder.

### Sabit Giderler ve Akıllı Bildirimler
<div align="center">
  <img src="docs/images/reminders.png" alt="Hatırlatıcılar ve Takvim" width="800"/>
</div>

Gelişmiş arka plan servisleri yardımıyla (Flutter Local Notifications + exact alarms), önemli günlerinizi, araç muayene tarihlerini, fatura kesim zamanlarını saniyesi saniyesine haber alın.

---

## 🛠️ Teknik Stack

- **Geliştirme Ortamı**: Flutter & Dart
- **State Yönetimi**: Riverpod (Generator destekli)
- **Veritabanı**: Hive & Hive Flutter (Çok hızlı, yerel NoSQL çözüm)
- **OCR (Görsel Tanıma)**: Google ML Kit (Text Recognition)
- **Bildirim Altyapısı**: Flutter Local Notifications (Arka plan tam-zamanlı alarm destekli)
- **Arayüz Tasarımı**: Custom Glassmorphism UI, Google Fonts (Poppins), Dinamik Temalandırma

## 📥 Kurulum (Geliştiriciler İçin)

1. **Repoyu Klonlayın**:
    ```bash
    git clone https://github.com/Tparlak/Ctrl-Finance-App.git
    cd Ctrl-Finance-App/vip_finance
    ```

2. **Bağımlılıkları Yükleyin**:
    ```bash
    flutter pub get
    ```

3. **Riverpod ve Hive Adapter'ları Üretin** (Zaten repodaysa bu adımı atlayabilirsiniz):
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

4. **Uygulamayı Çalıştırın**:
    ```bash
    flutter run
    ```

## 📦 Çıktı Alma (Release Build)

Minimum APK boyutunu sağlayan ve yeni Android telefonlarda (Samsung S22/S24 serisi, vs.) en yüksek performansta çalışacak şekilde optimize edilmiş build komutu:

```bash
flutter build apk --release --no-tree-shake-icons
```
*Not: RAM limitine takılıyorsanız başına ortam değişkeni ekleyebilirsiniz:*
`$env:JAVA_OPTS="-Xmx1536m"; flutter build apk --release --no-tree-shake-icons`

---
<div align="center">
  <b>Finansal Özgürlüğünüzü "Ctrl" Altına Alın.</b>
</div>
