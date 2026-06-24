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
  static const bool useTestAds = false; // REAL ads (production)
  static const bool interstitialEnabled = false; // Rewarded-only per design

  // Real AdMob ids (publisher ca-app-pub-1298950542115439).
  static const String rewardedAdUnit     = 'ca-app-pub-1298950542115439/1097238059';
  static const String interstitialAdUnit = ''; // disabled (interstitialEnabled=false)
  static const String bannerAdUnit       = '';

  // ----- Persistence keys -----
  static const String kHighScore = 'pb_high_score';
  static const String kCoins     = 'pb_coins';
  static const String kSound     = 'pb_sound';
  static const String kMusic     = 'pb_music';
  static const String kHaptics   = 'pb_haptics';
  static const String kFirstRun  = 'pb_first_run';
  static const String kUnlockedSkins = 'pb_unlocked_skins';
  static const String kSelectedSkin  = 'pb_selected_skin';
  static const String kHammers   = 'pb_hammers';
  static const String kShuffles  = 'pb_shuffles';
  static const String kBombs     = 'pb_bombs';
  static const String kLastClaim = 'pb_last_claim_day';
  static const String kStreak    = 'pb_daily_streak';
  static const String kGames     = 'pb_games_played';
  static const String kTotalLines = 'pb_total_lines';
  static const String kCampaignUnlocked = 'pb_campaign_unlocked'; // highest wave unlocked (1..20)
  static const String kWaveStars  = 'pb_wave_stars'; // CSV of 20 star counts (0..3)
  static const int powerupCost   = 40; // coins per power-up
}

/// Nusantara / batik-inspired palette. Warm earth tones (sogan brown, indigo,
/// gold, maroon) evoke traditional batik without using any copyrighted artwork.
class Palette {
  Palette._();

  // === "PUSAKA KERATON" — warm batik/keraton identity (distinct from Tiles'
  // cool indigo "Panggung Malam"). Field NAMES unchanged (gold = hero accent,
  // cream = text, etc.) so every screen + every FX recolors automatically; only
  // the VALUES changed — neon → sogan brown, prada gold, indigo & maroon batik.
  static const Color bg0      = Color(0xFF160E07); // deepest sogan-black
  static const Color bg1      = Color(0xFF241710); // dark roast night
  static const Color panel    = Color(0xFF2E2016); // glassy warm panel
  static const Color panelHi  = Color(0xFF3E2C1D); // raised wood / hover
  static const Color gridCell = Color(0xFF241A12); // empty board cell
  static const Color gridLine = Color(0xFF4A3520); // faint sogan grid line

  static const Color gold     = Color(0xFFE8B24C); // keraton prada gold (hero accent)
  static const Color goldLt   = Color(0xFFF8D98A); // bright gold glow
  static const Color goldSoft = Color(0xFFB5832E); // sogan gold (dim)
  static const Color cream    = Color(0xFFF4E8D2); // warm ivory text
  static const Color ink      = Color(0xFF160E07); // near-black (on bright btns)

  // batik accents
  static const Color coral    = Color(0xFFCD6A3D); // terracotta / pesisir
  static const Color maroon   = Color(0xFF8E3B2E); // deep batik maroon
  static const Color jade     = Color(0xFF5E7A3E); // batik daun olive-green

  static const LinearGradient brand = LinearGradient(
    colors: [goldLt, Color(0xFFB5832E), maroon], // gold → sogan → maroon sweep
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static List<BoxShadow> glow(Color c, {double blur = 26, double y = 10, double a = 0.5}) =>
      [BoxShadow(color: c.withOpacity(a), blurRadius: blur, offset: Offset(0, y))];

  // Block colors — traditional batik tones (sogan, indigo wedelan, prada, daun).
  static const List<Color> blockColors = <Color>[
    Color(0xFF9A4A36), // sogan terracotta
    Color(0xFF1F4E5F), // indigo wedelan
    Color(0xFFC2912F), // prada gold
    Color(0xFF4A6B3A), // daun olive
    Color(0xFF6E3B5C), // plum keraton
    Color(0xFF2E5E6E), // teal pesisir
    Color(0xFFB5632A), // amber sogan
  ];
}
