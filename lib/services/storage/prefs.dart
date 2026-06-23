import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';

/// Thin wrapper over SharedPreferences for the handful of values we persist.
class Prefs {
  final SharedPreferences _p;
  Prefs(this._p);

  static Future<Prefs> create() async => Prefs(await SharedPreferences.getInstance());

  int get highScore => _p.getInt(K.kHighScore) ?? 0;
  Future<void> setHighScore(int v) => _p.setInt(K.kHighScore, v);

  int get coins => _p.getInt(K.kCoins) ?? 0;
  Future<void> setCoins(int v) => _p.setInt(K.kCoins, v);

  bool get sound => _p.getBool(K.kSound) ?? true;
  Future<void> setSound(bool v) => _p.setBool(K.kSound, v);

  bool get music => _p.getBool(K.kMusic) ?? true;
  Future<void> setMusic(bool v) => _p.setBool(K.kMusic, v);

  bool get haptics => _p.getBool(K.kHaptics) ?? true;
  Future<void> setHaptics(bool v) => _p.setBool(K.kHaptics, v);

  bool get firstRun => _p.getBool(K.kFirstRun) ?? true;
  Future<void> setFirstRunDone() => _p.setBool(K.kFirstRun, false);

  List<String> get unlockedSkins =>
      (_p.getString(K.kUnlockedSkins) ?? 'klasik').split(',').where((s) => s.isNotEmpty).toList();
  Future<void> setUnlockedSkins(List<String> ids) =>
      _p.setString(K.kUnlockedSkins, ids.join(','));

  String get selectedSkin => _p.getString(K.kSelectedSkin) ?? 'klasik';
  Future<void> setSelectedSkin(String id) => _p.setString(K.kSelectedSkin, id);

  int get hammers => _p.getInt(K.kHammers) ?? 1;
  Future<void> setHammers(int v) => _p.setInt(K.kHammers, v);
  int get shuffles => _p.getInt(K.kShuffles) ?? 1;
  Future<void> setShuffles(int v) => _p.setInt(K.kShuffles, v);
  int get bombs => _p.getInt(K.kBombs) ?? 0;
  Future<void> setBombs(int v) => _p.setInt(K.kBombs, v);

  int get lastClaimDay => _p.getInt(K.kLastClaim) ?? 0;
  Future<void> setLastClaimDay(int v) => _p.setInt(K.kLastClaim, v);
  int get streak => _p.getInt(K.kStreak) ?? 0;
  Future<void> setStreak(int v) => _p.setInt(K.kStreak, v);

  int get gamesPlayed => _p.getInt(K.kGames) ?? 0;
  Future<void> setGamesPlayed(int v) => _p.setInt(K.kGames, v);
  int get totalLines => _p.getInt(K.kTotalLines) ?? 0;
  Future<void> setTotalLines(int v) => _p.setInt(K.kTotalLines, v);

  // ----- Campaign (Petualangan Nusantara) -----
  int get campaignUnlocked => _p.getInt(K.kCampaignUnlocked) ?? 1;
  Future<void> setCampaignUnlocked(int v) => _p.setInt(K.kCampaignUnlocked, v);

  /// Stars earned per wave, index 0 == wave 1. Always length 20.
  List<int> get waveStars {
    final raw = _p.getString(K.kWaveStars);
    final out = List<int>.filled(20, 0);
    if (raw == null || raw.isEmpty) return out;
    final parts = raw.split(',');
    for (var i = 0; i < 20 && i < parts.length; i++) {
      out[i] = int.tryParse(parts[i]) ?? 0;
    }
    return out;
  }

  Future<void> setWaveStars(List<int> stars) =>
      _p.setString(K.kWaveStars, stars.join(','));
}
