# Green Life 🌿 (Flutter · Konsept 2 "Orman Sade")

Ev bitkileri için: fotoğrafla tanıma, Türkçe bakım rehberi, sulama alarmları ve gün gün büyüme takibi.

## Neler hazır

| Ekran | İçerik |
|---|---|
| Giriş | Animasyonlu bitki, Google ile giriş, e-posta ile giriş |
| Ana sayfa | En acil bitki kartı, animasyonlu sağlık halkası, bugünün sulama görevleri (dokun → sulandı), alarm aç/kapa + saat seçimi, bitki şeridi |
| Bitkiler | Arama, sulama sırasına göre liste, "Listeden ekle" (20 popüler bitki, Türkçe bakım bilgisi) |
| Tara | Kamera/galeri, tarama çizgisi animasyonu, Pl@ntNet ile tanıma, alternatif sonuçlar, bakım bilgisi, tek dokunuşla ekle |
| Bitki detayı | Gün 1 / 7 / 14 / 30 sekmeleri → bitki yaprak yaprak büyür, boy sayacı, animasyonlu çubuk grafik, "Sulandı", "Boy ekle", sulama aralığı değiştirme, silme |
| Profil | Alarm ayarları, istatistik, çıkış |

Animasyonlar: yaprakların sırayla açılması, rüzgârda sallanma, ekranlar arası kayarak solma geçişi, kartların sıralı belirmesi, Hero geçişi (ana sayfa → detay), basınca küçülen kartlar, zıplayan su damlası.

İlk girişte örnek olarak 3 bitki (Monstera, Paşa Kılıcı, Barış Çiçeği) eklenir; istersen detaydan silebilirsin.

---

## 1. Kurulum (Windows)

1. Flutter'ı kur: https://docs.flutter.dev/get-started/install/windows/mobile (Android Studio ile birlikte).
2. Bu klasörde bir terminal (PowerShell) aç ve platform dosyalarını oluştur:

   ```powershell
   cd "C:\Users\user\OneDrive\Desktop\green life\green_life"
   flutter create --org com.greenlife --platforms=android,ios .
   flutter pub get
   ```

   > `flutter create` mevcut `lib/` ve `test/` dosyalarına dokunmaz, sadece `android/` ve `ios/` klasörlerini ekler.

## 2. Android ayarı (alarmlar için zorunlu, 2 dosya)

### a) `android/app/build.gradle.kts` (eski projelerde `build.gradle`)

`compileOptions` bloğuna bir satır, en alta bir `dependencies` bloğu ekle:

```kotlin
android {
    // ...
    compileOptions {
        isCoreLibraryDesugaringEnabled = true   // ← EKLE
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")   // ← EKLE
}
```

(Groovy `build.gradle` ise: `coreLibraryDesugaringEnabled true` ve `coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'`.)

### b) `android/app/src/main/AndroidManifest.xml`

`<manifest ...>` satırının hemen altına:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

`<application ...>` içine (`</application>`'dan önce):

```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
    </intent-filter>
</receiver>
```

## 3. Çalıştır

Telefonu USB ile bağla (geliştirici modu + USB hata ayıklama açık) ya da emülatör başlat:

```powershell
flutter run
```

Bitki tanımayı da açmak için (aşağıdaki anahtarla):

```powershell
flutter run --dart-define=PLANTNET_KEY=BURAYA_ANAHTAR
```

## 4. Bitki tanıma anahtarı (ücretsiz)

1. https://my.plantnet.org adresinde ücretsiz hesap aç → "API key" oluştur.
2. Ücretsiz plan: günde 500 tanıma, bu sınırda ticari kullanım serbest.
3. İsteğe bağlı: https://perenual.com'dan ücretsiz anahtar alıp `--dart-define=PERENUAL_KEY=...` eklersen, yerel listede olmayan bitkilerin bakım bilgisi oradan çekilir.

Anahtar yoksa uygulama yine çalışır; tarama ekranı "Listeden seç" seçeneğini sunar.

Nasıl çalışıyor: önce Pl@ntNet bitkiyi tanır → sonuç `lib/data/care_db.dart` içindeki Türkçe listede varsa API'ye hiç gidilmez → yoksa Perenual → o da yoksa genel bakım önerisi.

## 5. Google ile giriş

Firebase gerekmez, ama Google'a uygulamanı tanıtman lazım:

1. https://console.cloud.google.com → yeni proje → **APIs & Services → OAuth consent screen** (External, uygulama adı "Green Life").
2. **Credentials → Create credentials → OAuth client ID → Android**
   - Package name: `com.greenlife.green_life`
   - SHA-1: terminalde `cd android; ./gradlew signingReport` → "debug" altındaki SHA1.
3. Kaydet. Birkaç dakika sonra "Google ile devam et" çalışır.

Yapılandırma yapılmadan basarsan uygulama nazikçe uyarır; bu sırada **E-posta ile giriş** ile devam edebilirsin (şimdilik hesap sadece telefonda tutulur).

## Proje yapısı

```
lib/
  main.dart                 Uygulama girişi, giriş ↔ ana ekran geçişi
  theme.dart                Konsept 2 renkleri, font (Manrope), sayfa geçişi
  models/plant.dart         Bitki, büyüme kaydı, sulama/sağlık hesapları
  data/care_db.dart         20 popüler ev bitkisinin Türkçe bakım bilgisi
  services/
    store.dart              Uygulama durumu + telefona kayıt
    notifications.dart      Sulama alarmları (yerel bildirim)
    plant_id.dart           Pl@ntNet tanıma + Perenual bakım
    auth.dart               Google ile giriş
  widgets/
    animated_plant.dart     Büyüyen / sallanan bitki çizimi
    common.dart             Kart, düğme, sağlık halkası, giriş animasyonları
  screens/                  Giriş, iskelet+menü, ana sayfa, bitkiler, tara, detay, profil
```

## Sonraki adımlar (öneri)

- Hesapları buluta taşımak (Firebase Auth + Firestore) → telefon değişince veriler kaybolmaz.
- Uygulama ikonu ve açılış ekranı (`flutter_launcher_icons`, `flutter_native_splash`).
- Bakım listesini 20'den 150+ bitkiye genişletmek.
