# Panduan Go-Live — Pusaka Blast

Checklist final untuk mengubah build dari **mode tes** ke **rilis sungguhan** (AdMob real, App Store / Play Store). Semua kode sudah ada di GitHub & siap dibangun via **GitHub Actions** dan **Codemagic**.

---

## 1. AdMob (ganti dari iklan TES ke iklan SUNGGUHAN)

Saat ini app pakai **ID iklan tes Google** supaya aman saat development (tidak melanggar kebijakan AdMob). Untuk menghasilkan uang, ganti ke ID akun AdMob bos:

**Langkah:**
1. Buat akun di https://admob.google.com → tambah app **Pusaka Blast** (iOS & Android).
2. Buat 3 unit iklan: **Banner**, **Interstitial**, **Rewarded**.
3. Edit `lib/core/constants.dart`:
   ```dart
   static const bool useTestAds = false;          // ← dari true ke false
   static const String bannerAdUnit       = 'ca-app-pub-XXXX/BANNER';
   static const String interstitialAdUnit = 'ca-app-pub-XXXX/INTERSTITIAL';
   static const String rewardedAdUnit     = 'ca-app-pub-XXXX/REWARDED';
   ```
4. Ganti **AdMob App ID**:
   - iOS: `ios/Runner/Info.plist` → `GADApplicationIdentifier` (juga ada langkah di `codemagic.yaml` yang mengisi ini — update nilainya).
   - Android: `android/app/src/main/AndroidManifest.xml` → `<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" .../>`.

> Penempatan iklan yang sudah jalan: **Banner** di beranda, **Interstitial** tiap ±2× game-over, **Rewarded** untuk revive, power-up gratis, & "Koin Gratis" di toko.

---

## 2. Build & distribusi

**Opsi A — GitHub Actions (otomatis, tanpa Mac):**
- Push ke `main` → workflow `build-apk.yml` bikin APK/AAB; `ios.yml` bikin & upload IPA ke TestFlight (pakai App Store Connect API key dari secrets).

**Opsi B — Codemagic:** `codemagic.yaml` sudah berisi workflow iOS lengkap (signing via API key, upload App Store). Tinggal connect repo di Codemagic & jalankan.

---

## 3. App Store (iOS)
1. App Store Connect → app **Pusaka Blast** sudah ada (build masuk TestFlight).
2. Isi metadata: deskripsi, kata kunci, screenshot, kategori (Games > Puzzle), rating umur.
3. **App Privacy**: app pakai AdMob → deklarasikan pengumpulan data iklan (Identifiers, Usage Data) di kuesioner privasi + sertakan link kebijakan privasi.
4. Submit for Review.

## 4. Play Store (Android)
1. Build AAB (`build-apk.yml`) → upload ke Play Console.
2. Isi store listing + Data Safety (AdMob).
3. Submit.

---

✅ **Kode, CI (GitHub + Codemagic), dan AdMob semua sudah terpasang.** Yang tersisa hanyalah swap 4 nilai di atas + isi metadata toko.
