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
}
