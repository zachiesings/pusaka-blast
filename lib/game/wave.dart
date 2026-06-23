import 'package:flutter/material.dart';
import '../core/constants.dart';

/// The kind of objective a campaign wave asks of the player.
enum WaveGoal {
  lines,    // clear a cumulative number of lines this wave
  score,    // reach a target score
  clears,   // perform N line-clearing placements
  combo,    // reach a combo of N in a single chain
  perfect,  // achieve N perfect board-clears (Papan Bersih)
  treasure, // free N Harta (treasure) cells
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
      case WaveGoal.treasure:
        return Icons.diamond_rounded;
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
      case WaveGoal.treasure:
        return 'Bebaskan $target Harta';
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
      case WaveGoal.treasure:
        return 'Harta';
      case WaveGoal.survive:
        return 'Bertahan';
    }
  }
}

/// One campaign stage: a *pusaka* (heirloom) to be claimed from a region of the
/// archipelago, with an objective, a move budget (for star rating), a coin
/// reward, and optional batik-stone obstacles, Harta (treasure) and Gembok
/// (locked, 2-hit) board cells + an optional time limit.
@immutable
class WaveSpec {
  final int index;        // 1..20
  final String region;    // island / culture
  final String title;     // the heirloom being claimed
  final String motif;     // a one-line flavour blurb
  final WaveGoal goal;
  final int target;
  final int par;          // move budget — clear at/under par for 3 stars
  final int coins;        // reward on first completion
  final int obstacles;    // pre-scattered batik-stone cells (rintangan)
  final int treasures;    // pre-scattered Harta cells
  final int locks;        // pre-scattered Gembok cells (need 2 clears)
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
    this.treasures = 0,
    this.locks = 0,
    this.seconds,
    required this.accent,
  });

  bool get timed => seconds != null;
  bool get hasTwist => obstacles > 0 || treasures > 0 || locks > 0 || timed;

  /// Stars (1..3) earned for clearing the wave using [movesUsed] placements.
  int starsFor(int movesUsed, {int timeLeft = 0}) {
    if (movesUsed <= par) return 3;
    if (movesUsed <= par + 6) return 2;
    return 1;
  }
}

/// The 20-wave "Petualangan Nusantara" campaign — a crafted journey across the
/// archipelago. The first ten waves introduce each mechanic in turn (clears →
/// Harta → obstacles → Gembok → combo → perfect), the back ten combine them.
class WaveCatalog {
  WaveCatalog._();

  static const _g = Palette.gold;
  static const _c = Palette.coral;
  static const _j = Palette.jade;
  static const _m = Palette.maroon;
  static const _p = Color(0xFF8C5BA6); // plum
  static const _t = Color(0xFF3F8C7A); // teal

  static const List<WaveSpec> all = <WaveSpec>[
    WaveSpec(index: 1, region: 'Yogyakarta', title: 'Keris Pusaka', motif: 'Tempa pertama sang empu — kenali papannya.', goal: WaveGoal.lines, target: 3, par: 7, coins: 15, accent: _g),
    WaveSpec(index: 2, region: 'Surakarta', title: 'Blangkon Raja', motif: 'Susun skor seperti menata mahkota.', goal: WaveGoal.score, target: 300, par: 10, coins: 18, accent: _g),
    WaveSpec(index: 3, region: 'Bali', title: 'Topeng Barong', motif: 'Bersihkan berkali-kali, usir gangguan.', goal: WaveGoal.clears, target: 6, par: 11, coins: 22, obstacles: 2, accent: _c),
    WaveSpec(index: 4, region: 'Sunda', title: 'Angklung Emas', motif: 'Harta emas tersembunyi — bebaskan dengan membersihkan barisnya.', goal: WaveGoal.treasure, target: 2, par: 11, coins: 26, treasures: 2, accent: _j),
    WaveSpec(index: 5, region: 'Cirebon', title: 'Mega Mendung', motif: 'Awan berlapis — banyak rintangan menumpuk.', goal: WaveGoal.lines, target: 8, par: 12, coins: 28, obstacles: 4, accent: _p),
    WaveSpec(index: 6, region: 'Palembang', title: 'Songket Emas', motif: 'Tenun benang emas; raih skor sambil ambil harta.', goal: WaveGoal.score, target: 650, par: 13, coins: 32, obstacles: 2, treasures: 2, accent: _g),
    WaveSpec(index: 7, region: 'Aceh', title: 'Rencong Tergembok', motif: 'Gembok besi butuh dua kali pembersihan untuk pecah.', goal: WaveGoal.clears, target: 9, par: 13, coins: 36, locks: 2, accent: _m),
    WaveSpec(index: 8, region: 'Minangkabau', title: 'Saluak Gadang', motif: 'Atap bertanduk — papan makin sesak.', goal: WaveGoal.lines, target: 11, par: 14, coins: 38, obstacles: 4, treasures: 2, accent: _c),
    WaveSpec(index: 9, region: 'Kalimantan', title: 'Mandau Dayak', motif: 'Rangkai combo beruntun di tengah gembok.', goal: WaveGoal.combo, target: 3, par: 14, coins: 42, locks: 3, accent: _j),
    WaveSpec(index: 10, region: 'Dayak', title: 'Perisai Talawang', motif: 'Pusaka penuh harta — kumpulkan semuanya.', goal: WaveGoal.treasure, target: 4, par: 15, coins: 55, obstacles: 3, treasures: 4, accent: _t),
    WaveSpec(index: 11, region: 'Bugis', title: 'Badik Makassar', motif: 'Bilah kehormatan pelaut.', goal: WaveGoal.clears, target: 13, par: 16, coins: 46, obstacles: 3, locks: 2, accent: _m),
    WaveSpec(index: 12, region: 'Toraja', title: 'Tongkonan Emas', motif: 'Kosongkan seluruh papan — Papan Bersih.', goal: WaveGoal.perfect, target: 1, par: 16, coins: 60, obstacles: 3, accent: _g),
    WaveSpec(index: 13, region: 'Maluku', title: 'Parang Salawaku', motif: 'Parang & perisai cengkih.', goal: WaveGoal.lines, target: 15, par: 18, coins: 50, obstacles: 5, treasures: 3, accent: _c),
    WaveSpec(index: 14, region: 'Ternate', title: 'Mahkota Kesultanan', motif: 'Mahkota rempah — kejar skor sebelum waktu habis.', goal: WaveGoal.score, target: 1400, par: 18, coins: 64, obstacles: 4, seconds: 100, accent: _g),
    WaveSpec(index: 15, region: 'Nusa Tenggara', title: 'Tenun Ikat', motif: 'Benang diikat — combo di antara gembok.', goal: WaveGoal.combo, target: 4, par: 17, coins: 58, locks: 4, accent: _p),
    WaveSpec(index: 16, region: 'Lombok', title: 'Gendang Beleq', motif: 'Genderang perang penuh harta.', goal: WaveGoal.treasure, target: 6, par: 19, coins: 66, obstacles: 3, treasures: 6, accent: _t),
    WaveSpec(index: 17, region: 'Papua', title: 'Tifa Sentani', motif: 'Tabuh dari kayu lenggua.', goal: WaveGoal.lines, target: 18, par: 20, coins: 70, obstacles: 6, locks: 3, accent: _m),
    WaveSpec(index: 18, region: 'Papua', title: 'Mahkota Cendrawasih', motif: 'Bulu burung surga — skor & harta, lawan waktu.', goal: WaveGoal.score, target: 1800, par: 20, coins: 82, treasures: 4, seconds: 110, accent: _g),
    WaveSpec(index: 19, region: 'Nusantara', title: 'Gunungan Wayang', motif: 'Lambang semesta — combo panjang di papan keras.', goal: WaveGoal.combo, target: 5, par: 19, coins: 90, obstacles: 4, locks: 5, accent: _p),
    WaveSpec(index: 20, region: 'Nusantara', title: 'Pusaka Agung', motif: 'Mahkota seluruh negeri — ujian terakhir.', goal: WaveGoal.score, target: 2600, par: 22, coins: 150, obstacles: 5, treasures: 4, locks: 3, accent: _g),
  ];

  static const int count = 20;

  static WaveSpec byIndex(int index) =>
      all.firstWhere((w) => w.index == index, orElse: () => all.first);
}
