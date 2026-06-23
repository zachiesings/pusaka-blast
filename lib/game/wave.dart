import 'package:flutter/material.dart';
import '../core/constants.dart';

/// The kind of objective a campaign wave asks of the player.
enum WaveGoal {
  lines,    // clear a cumulative number of lines this wave
  score,    // reach a target score
  clears,   // perform N line-clearing placements
  combo,    // reach a combo of N in a single chain
  perfect,  // achieve N perfect board-clears (Papan Bersih)
  survive,  // place N pieces without a game-over
}

extension WaveGoalX on WaveGoal {
  IconData get icon {
    switch (this) {
      case WaveGoal.lines:
        return Icons.view_week_rounded;
      case WaveGoal.score:
        return Icons.stars_rounded;
      case WaveGoal.clears:
        return Icons.grid_on_rounded;
      case WaveGoal.combo:
        return Icons.bolt_rounded;
      case WaveGoal.perfect:
        return Icons.cleaning_services_rounded;
      case WaveGoal.survive:
        return Icons.shield_rounded;
    }
  }

  /// Indonesian objective label, with the [target] interpolated.
  String label(int target) {
    switch (this) {
      case WaveGoal.lines:
        return 'Bersihkan $target baris';
      case WaveGoal.score:
        return 'Raih skor $target';
      case WaveGoal.clears:
        return 'Lakukan $target pembersihan';
      case WaveGoal.combo:
        return 'Capai combo ×$target';
      case WaveGoal.perfect:
        return target > 1 ? 'Papan Bersih ×$target' : 'Satu kali Papan Bersih';
      case WaveGoal.survive:
        return 'Pasang $target balok';
    }
  }

  String get short {
    switch (this) {
      case WaveGoal.lines:
        return 'Baris';
      case WaveGoal.score:
        return 'Skor';
      case WaveGoal.clears:
        return 'Bersih';
      case WaveGoal.combo:
        return 'Combo';
      case WaveGoal.perfect:
        return 'Papan';
      case WaveGoal.survive:
        return 'Bertahan';
    }
  }
}

/// One campaign stage: a *pusaka* (heirloom) to be claimed from a region of the
/// archipelago, with an objective, a move budget (for star rating), a coin
/// reward, and an optional batik-stone obstacle count + time limit.
@immutable
class WaveSpec {
  final int index;        // 1..20
  final String region;    // island / culture
  final String title;     // the heirloom being claimed
  final String motif;     // a one-line flavour blurb
  final WaveGoal goal;
  final int target;
  final int par;          // move budget — clear at/under par for 3 stars
  final int coins;        // reward on first completion (scaled at runtime too)
  final int obstacles;    // pre-scattered batik-stone cells (rintangan)
  final int? seconds;     // optional time limit
  final Color accent;     // node colour on the map

  const WaveSpec({
    required this.index,
    required this.region,
    required this.title,
    required this.motif,
    required this.goal,
    required this.target,
    required this.par,
    required this.coins,
    this.obstacles = 0,
    this.seconds,
    required this.accent,
  });

  bool get timed => seconds != null;

  /// Stars (1..3) earned for clearing the wave using [movesUsed] placements
  /// (and, for timed waves, with [timeLeft] seconds to spare).
  int starsFor(int movesUsed, {int timeLeft = 0}) {
    if (movesUsed <= par) return 3;
    if (movesUsed <= par + 6) return 2;
    return 1;
  }
}

/// The 20-wave "Petualangan Nusantara" campaign — a journey across the
/// archipelago claiming an heirloom in each region, difficulty rising steadily.
class WaveCatalog {
  WaveCatalog._();

  static const _g = Palette.gold;
  static const _c = Palette.coral;
  static const _j = Palette.jade;
  static const _m = Palette.maroon;
  static const _p = Color(0xFF8C5BA6); // plum
  static const _t = Color(0xFF3F8C7A); // teal

  static const List<WaveSpec> all = <WaveSpec>[
    WaveSpec(index: 1, region: 'Yogyakarta', title: 'Keris Pusaka', motif: 'Tempa pertama sang empu.', goal: WaveGoal.lines, target: 4, par: 8, coins: 15, accent: _g),
    WaveSpec(index: 2, region: 'Surakarta', title: 'Blangkon Raja', motif: 'Mahkota tutur orang Jawa.', goal: WaveGoal.score, target: 300, par: 10, coins: 18, accent: _g),
    WaveSpec(index: 3, region: 'Bali', title: 'Topeng Barong', motif: 'Penjaga dari dunia roh.', goal: WaveGoal.clears, target: 7, par: 11, coins: 20, accent: _c),
    WaveSpec(index: 4, region: 'Bali', title: 'Keris Bali', motif: 'Bilah berukir naga.', goal: WaveGoal.lines, target: 9, par: 12, coins: 22, obstacles: 3, accent: _c),
    WaveSpec(index: 5, region: 'Sunda', title: 'Angklung Bambu', motif: 'Getar bambu yang menyatu.', goal: WaveGoal.combo, target: 2, par: 12, coins: 24, accent: _j),
    WaveSpec(index: 6, region: 'Palembang', title: 'Songket Emas', motif: 'Tenun benang emas raja.', goal: WaveGoal.score, target: 600, par: 13, coins: 28, obstacles: 4, accent: _g),
    WaveSpec(index: 7, region: 'Aceh', title: 'Rencong Aceh', motif: 'Pusaka tanah Serambi.', goal: WaveGoal.clears, target: 11, par: 14, coins: 30, obstacles: 3, accent: _m),
    WaveSpec(index: 8, region: 'Minangkabau', title: 'Saluak Rumah Gadang', motif: 'Atap bertanduk kerbau.', goal: WaveGoal.lines, target: 13, par: 15, coins: 32, obstacles: 4, accent: _c),
    WaveSpec(index: 9, region: 'Kalimantan', title: 'Mandau Dayak', motif: 'Parang sakral rimba.', goal: WaveGoal.combo, target: 3, par: 14, coins: 34, obstacles: 5, accent: _j),
    WaveSpec(index: 10, region: 'Dayak', title: 'Perisai Talawang', motif: 'Tameng ukir leluhur.', goal: WaveGoal.score, target: 1000, par: 16, coins: 40, obstacles: 4, accent: _t),
    WaveSpec(index: 11, region: 'Bugis', title: 'Badik Makassar', motif: 'Bilah kehormatan pelaut.', goal: WaveGoal.clears, target: 15, par: 17, coins: 42, obstacles: 5, accent: _m),
    WaveSpec(index: 12, region: 'Toraja', title: 'Tongkonan Emas', motif: 'Rumah arwah para datu.', goal: WaveGoal.perfect, target: 1, par: 16, coins: 50, obstacles: 4, accent: _g),
    WaveSpec(index: 13, region: 'Maluku', title: 'Parang Salawaku', motif: 'Parang & perisai cengkih.', goal: WaveGoal.lines, target: 17, par: 18, coins: 46, obstacles: 6, accent: _c),
    WaveSpec(index: 14, region: 'Ternate', title: 'Mahkota Kesultanan', motif: 'Mahkota rempah utara.', goal: WaveGoal.score, target: 1400, par: 18, coins: 55, obstacles: 5, seconds: 100, accent: _g),
    WaveSpec(index: 15, region: 'Nusa Tenggara', title: 'Tenun Ikat', motif: 'Benang diikat sebelum dicelup.', goal: WaveGoal.combo, target: 4, par: 17, coins: 52, obstacles: 6, accent: _p),
    WaveSpec(index: 16, region: 'Lombok', title: 'Gendang Beleq', motif: 'Genderang perang Sasak.', goal: WaveGoal.clears, target: 19, par: 20, coins: 56, obstacles: 6, accent: _t),
    WaveSpec(index: 17, region: 'Papua', title: 'Tifa Sentani', motif: 'Tabuh dari kayu lenggua.', goal: WaveGoal.lines, target: 21, par: 21, coins: 60, obstacles: 7, accent: _m),
    WaveSpec(index: 18, region: 'Papua', title: 'Mahkota Cendrawasih', motif: 'Bulu burung surga.', goal: WaveGoal.score, target: 1800, par: 20, coins: 70, obstacles: 6, seconds: 110, accent: _g),
    WaveSpec(index: 19, region: 'Nusantara', title: 'Gunungan Wayang', motif: 'Lambang semesta lakon.', goal: WaveGoal.combo, target: 5, par: 19, coins: 75, obstacles: 7, accent: _p),
    WaveSpec(index: 20, region: 'Nusantara', title: 'Pusaka Agung', motif: 'Mahkota seluruh negeri.', goal: WaveGoal.score, target: 2600, par: 22, coins: 120, obstacles: 8, accent: _g),
  ];

  static const int count = 20;

  static WaveSpec byIndex(int index) =>
      all.firstWhere((w) => w.index == index, orElse: () => all.first);
}
