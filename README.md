# Pusaka Blast

Teka-teki balok **8×8** (gaya Block Blast) dengan tema **batik Nusantara**. Seret
balok ke papan, penuhi baris/kolom untuk membersihkannya, kejar combo & skor
tertinggi. Monetisasi lewat **AdMob** (rewarded ad untuk lanjut main + interstitial).

## Struktur repo

Repo ini **hanya menyimpan `lib/` + `assets/` + konfigurasi CI**. Folder native
(`android/`, `ios/`) **digenerate otomatis** oleh CI dengan `flutter create`, jadi
tidak perlu di-commit (lihat `.gitignore`).

```
lib/
  core/        konstanta, tema (palet batik)
  game/        model + engine Block Blast (logika murni, ada unit test)
  state/       AppState (skor/koin/setelan) + GameController (sesi main)
  services/    ads (AdMob, abstraksi stub+real) + storage (shared_preferences)
  widgets/     pelukis ubin & latar batik (digambar via kode, no image asset)
  features/    home / game / settings / about
test/          unit test untuk engine
```

## Build

- **Android (APK/AAB):** GitHub Actions `.github/workflows/build-apk.yml` jalan
  otomatis tiap push ke `main`. Artefak APK & AAB bisa diunduh dari tab Actions.
- **iOS (TestFlight/App Store):** Codemagic `codemagic.yaml` (butuh App Store
  Connect API key sebagai env var, sama seperti Beat Nusantara).

## AdMob

Sekarang masih pakai **unit iklan TEST resmi Google** (`K.useTestAds = true`) supaya
build aman & tidak melanggar kebijakan. Untuk pakai iklan asli, lihat
[`docs/PANDUAN-ADMOB.md`](docs/PANDUAN-ADMOB.md).
