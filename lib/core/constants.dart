import 'package:flutter/material.dart';

/// Global, compile-time-ish constants. Centralised so gameplay, ads and theming
/// never hard-code magic values. (Mirrors the proven Beat Nusantara layout.)
class K {
  K._();

  // ----- Game rules -----
  static const int gridSize = 8;          // 8x8 Block-Blast board
  static const int trayCount = 3;         // pieces offered at a time
  static const int reviveAdReward = 1;    // # of board-clears a rewarded ad grants

  // ----- Ads -----
  // While true we use Google's official TEST units (safe, never real revenue).
  // The boss flips this to false AFTER creating the real AdMob app + units and
  // pasting their ids below. See docs/PANDUAN-ADMOB.md.
  static const bool adsEnabled = true;
  static const bool useTestAds = true;

  // Real ad unit ids (Android). iOS ids are configured the same way in the doc.
  // Left as the test ids until the boss provides real ones.
  static const String rewardedAdUnit     = 'ca-app-pub-3940256099942544/5224354917';
  static const String interstitialAdUnit = 'ca-app-pub-3940256099942544/1033173712';
  static const String bannerAdUnit       = 'ca-app-pub-3940256099942544/6300978111';

  // ----- Persistence keys -----
  static const String kHighScore = 'pb_high_score';
  static const String kCoins     = 'pb_coins';
  static const String kSound     = 'pb_sound';
  static const String kMusic     = 'pb_music';
  static const String kHaptics   = 'pb_haptics';
  static const String kFirstRun  = 'pb_first_run';
  static const String kUnlockedSkins = 'pb_unlocked_skins';
  static const String kSelectedSkin  = 'pb_selected_skin';
}

/// Nusantara / batik-inspired palette. Warm earth tones (sogan brown, indigo,
/// gold, maroon) evoke traditional batik without using any copyrighted artwork.
class Palette {
  Palette._();

  // === "PENDOPO EMAS" — warm, regal golden-batik identity (distinct from Tiles) ===
  static const Color bg0      = Color(0xFF1A1108); // deepest warm sogan night
  static const Color bg1      = Color(0xFF2C1C0C); // espresso batik
  static const Color panel    = Color(0xFF3A2614); // raised teak wood panel
  static const Color panelHi  = Color(0xFF4E331A); // highlighted wood
  static const Color gridCell = Color(0xFF2E1F10); // empty board cell
  static const Color gridLine = Color(0xFF53381E);

  static const Color gold     = Color(0xFFF2B73C); // prada gold (hero)
  static const Color goldLt   = Color(0xFFFCD675);
  static const Color goldSoft = Color(0xFFC8923A);
  static const Color cream    = Color(0xFFF7EFE2); // kuning gading
  static const Color ink      = Color(0xFF1A1108);

  // warm accents
  static const Color coral    = Color(0xFFE8744C); // senja terracotta
  static const Color maroon   = Color(0xFFB23A4E); // marun
  static const Color jade     = Color(0xFF2FA987); // gamelan jade

  static const LinearGradient brand = LinearGradient(
    colors: [goldLt, gold, coral],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static List<BoxShadow> glow(Color c, {double blur = 26, double y = 10, double a = 0.5}) =>
      [BoxShadow(color: c.withOpacity(a), blurRadius: blur, offset: Offset(0, y))];

  // Block colors — rich, saturated, warm-led batik tones.
  static const List<Color> blockColors = <Color>[
    Color(0xFFE8744C), // terracotta
    Color(0xFFF2B73C), // prada gold
    Color(0xFF2FA987), // jade
    Color(0xFFB23A4E), // marun
    Color(0xFFD98A2B), // amber sogan
    Color(0xFF8C5BA6), // plum
    Color(0xFF3F8C7A), // teal tua
  ];
}
