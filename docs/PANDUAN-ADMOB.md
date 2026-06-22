# Panduan AdMob — Pusaka Blast

Saat ini game memakai **unit iklan TEST resmi Google**, jadi aman dipakai &
disubmit ke store (tidak melanggar kebijakan AdMob). Iklan asli baru aktif
setelah langkah di bawah.

## 1. Buat app di AdMob
1. Masuk ke https://admob.google.com → **Apps → Add app**.
2. Buat **dua** entri: satu untuk **Android**, satu untuk **iOS** (nama: Pusaka Blast).
3. Catat **App ID** masing-masing, formatnya `ca-app-pub-XXXX~YYYY`.

## 2. Buat unit iklan
Untuk tiap platform, buat 3 unit lalu catat ID-nya (`ca-app-pub-XXXX/ZZZZ`):
- **Rewarded** (untuk tombol "Lanjut — Tonton Iklan")
- **Interstitial** (jeda antar permainan)
- **Banner** (opsional)

## 3. Tempel ID ke kode
Edit `lib/core/constants.dart`:
```dart
static const bool useTestAds = false;            // <- ubah ke false
static const String rewardedAdUnit     = 'ca-app-pub-XXXX/REWARDED_ANDROID';
static const String interstitialAdUnit = 'ca-app-pub-XXXX/INTERSTITIAL_ANDROID';
static const String bannerAdUnit       = 'ca-app-pub-XXXX/BANNER_ANDROID';
```
> Catatan: file ini memakai satu set unit. Jika ingin ID iOS terpisah, beri tahu
> saya — tinggal ditambah pembeda platform (sudah disiapkan polanya).

## 4. Tempel App ID ke CI
- **Android** — `.github/workflows/build-apk.yml`, cari
  `com.google.android.gms.ads.APPLICATION_ID`, ganti nilai test
  `ca-app-pub-3940256099942544~3347511713` dengan App ID Android-mu.
- **iOS** — `codemagic.yaml`, cari `GADApplicationIdentifier`, ganti nilai test
  `ca-app-pub-3940256099942544~1458002511` dengan App ID iOS-mu.

## 5. App Privacy / Data Safety
Iklan dikirim **non-personalized** (`nonPersonalizedAds: true`), jadi:
- App Store → bisa pilih **"Not used to track you"** (tidak butuh prompt ATT).
- Play Console → Data safety: deklarasikan AdMob seperti biasa.
