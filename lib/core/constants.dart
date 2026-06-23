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

  // === "NEON GRID" — dark cyber-arcade identity (distinct from Tiles' batik) ===
  // Same field NAMES kept (gold = hero accent, cream = text, etc.) so every
  // screen recolors automatically; only the VALUES changed to neon.
  static const Color bg0      = Color(0xFF07070D); // deepest void black
  static const Color bg1      = Color(0xFF0C0D18); // night blue-black
  static const Color panel    = Color(0xFF13162A); // glassy dark panel
  static const Color panelHi  = Color(0xFF1E2440); // raised glass / hover
  static const Color gridCell = Color(0xFF10131F); // empty board cell
  static const Color gridLine = Color(0xFF2B3360); // faint neon grid line

  static const Color gold     = Color(0xFF1FE3FF); // electric cyan (hero accent)
  static const Color goldLt   = Color(0xFF8BF4FF); // light cyan glow
  static const Color goldSoft = Color(0xFF16A6C4); // dim cyan
  static const Color cream    = Color(0xFFEAF2FF); // cool white text
  static const Color ink      = Color(0xFF06080F); // near-black (on bright btns)

  // neon accents
  static const Color coral    = Color(0xFFFF3DAE); // neon magenta
  static const Color maroon   = Color(0xFFFF2E63); // hot pink-red
  static const Color jade     = Color(0xFF9DFF3D); // neon lime

  static const LinearGradient brand = LinearGradient(
    colors: [goldLt, Color(0xFFB14DFF), coral], // cyan → violet → magenta sweep
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static List<BoxShadow> glow(Color c, {double blur = 26, double y = 10, double a = 0.5}) =>
      [BoxShadow(color: c.withOpacity(a), blurRadius: blur, offset: Offset(0, y))];

  // Block colors — vivid neon set (cyber arcade).
  static const List<Color> blockColors = <Color>[
    Color(0xFF1FE3FF), // cyan
    Color(0xFFFF3DAE), // magenta
    Color(0xFF9DFF3D), // lime
    Color(0xFFB14DFF), // violet
    Color(0xFFFFD23D), // electric yellow
    Color(0xFFFF6B35), // neon orange
    Color(0xFF3D8BFF), // electric blue
  ];
}
