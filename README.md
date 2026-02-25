# Ctrl - Kişisel Finans Takip Uygulaması 🚀

**Ctrl**, modern VIP estetiği ve cam (glassmorphism) tasarımı ile geliştirilmiş, kullanıcı dostu bir kişisel finans yönetim uygulamasıdır. Gelir, gider ve sabit masraflarınızı en şık şekilde takip etmeniz için tasarlanmıştır.

## ✨ Öne Çıkan Özellikler

-   **💎 VIP Tasarım**: Karanlık mod odaklı, altın rengi vurgular ve gelişmiş cam efekti (Glassmorphism) ile premium kullanıcı deneyimi.
-   **📊 Dashboard**: Mevcut bakiyenizi, o ayki toplam gelirinizi ve giderlerinizi anlık olarak görün.
-   **🏦 Hesap Yönetimi**: Birden fazla hesap (Nakit, Banka Kartı, Kredi Kartı vb.) tanımlayın ve bakiyelerini ayrı ayrı takip edin.
-   **📂 Kategorizasyon**: Harcamalarınızı Market, Ulaşım, Eğlence gibi kategorilere ayırarak nereye ne kadar harcadığınızı analiz edin.
-   **🗓️ Sabit Masraflar**: Kira, faturalar gibi her ay tekrarlayan masraflarınızı kaydedin; uygulama her ay başında bunları sizin için otomatik olarak klonlar.
-   **📱 S22 & Modern Cihaz Desteği**: Samsung One UI ve diğer modern Android cihazlar için tam uyumlu, full-bleed adaptif ikon desteği.
-   **🔒 Yerel Depolama**: Verileriniz Hive ile cihazınızda güvenli bir şekilde saklanır, internet gerektirmez.

## 🛠️ Teknik Stack

-   **Framework**: Flutter
-   **State Management**: Riverpod (Generator destekli)
-   **Veritabanı**: Hive (NoSQL, hızlı yerel depolama)
-   **Tasarım**: Custom Glassmorphism UI & Google Fonts (Poppins)
-   **Konfigürasyon**: Flutter Launcher Icons (Adaptif İkon Senkronizasyonu)

## 📥 Kurulum (Geliştiriciler İçin)

1.  **Repoyu Klonlayın**:
    ```bash
    git clone https://github.com/KULLANICI_ADINIZ/Ctrl-App.git
    cd Ctrl-App/vip_finance
    ```

2.  **Bağımlılıkları Yükleyin**:
    ```bash
    flutter pub get
    ```

3.  **Hive Adapter'ları Üretin**:
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

4.  **Uygulamayı Çalıştırın**:
    ```bash
    flutter run
    ```

## 📦 APK Oluşturma (Release)

Samsung S22 gibi cihazlarda sorunsuz kurulum için imzalı release APK oluşturmak gerekir:

```bash
flutter build apk --release --no-tree-shake-icons
```
*Not: APK dosyası `build/app/outputs/flutter-apk/Ctrl-v1.0.apk` yolunda oluşturulacaktır.*

---
*Bu proje "Ctrl" ismiyle finansal özgürlüğünüzü kontrol altına almanız için geliştirilmiştir.*
