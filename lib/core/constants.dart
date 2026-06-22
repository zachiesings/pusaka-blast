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
  static const String kHaptics   = 'pb_haptics';
  static const String kFirstRun  = 'pb_first_run';
  static const String kUnlockedSkins = 'pb_unlocked_skins';
  static const String kSelectedSkin  = 'pb_selected_skin';
}

/// Nusantara / batik-inspired palette. Warm earth tones (sogan brown, indigo,
/// gold, maroon) evoke traditional batik without using any copyrighted artwork.
class Palette {
  Palette._();

  static const Color bg0      = Color(0xFF15110A); // near-black sogan
  static const Color bg1      = Color(0xFF241B10); // deep coffee brown
  static const Color panel    = Color(0xFF2E2316); // raised wood panel
  static const Color gridCell = Color(0xFF3A2D1C); // empty board cell
  static const Color gridLine = Color(0xFF4A3A24);

  static const Color gold     = Color(0xFFE3B23C); // gamelan gold (accents)
  static const Color goldSoft = Color(0xFFC8923A);
  static const Color cream    = Color(0xFFF3E5C8); // batik canvas cream
  static const Color ink      = Color(0xFF1B130A);

  // Block / batik-motif colors (each piece picks one).
  static const List<Color> blockColors = <Color>[
    Color(0xFF7A3B2E), // bata — terracotta red
    Color(0xFF1F4E5F), // indigo nila
    Color(0xFFB5832E), // sogan kuning
    Color(0xFF4A6B3A), // daun — leaf green
    Color(0xFF6E3B5C), // anggur — plum
    Color(0xFF2E5E6E), // teal pesisir
    Color(0xFFA84B2A), // tembaga — copper
  ];
}
