import 'package:flutter/foundation.dart';
import '../game/core_colors.dart';
import '../game/skins.dart';
import '../services/storage/prefs.dart';
import '../services/ads/ads_service.dart';
import '../services/audio/audio_service.dart';

/// App-wide persisted state: high score, coins, and settings. Lives above the
/// gameplay session so values survive between runs.
class AppState extends ChangeNotifier {
  final Prefs _prefs;
  final AdsService ads;
  final AudioService audio;

  int _highScore;
  int _coins;
  bool _sound;
  bool _haptics;
  late Set<String> _unlockedSkins;
  late String _selectedSkin;
  int _overCount = 0; // game-overs, for interstitial cadence

  AppState(this._prefs, this.ads, this.audio)
      : _highScore = _prefs.highScore,
        _coins = _prefs.coins,
        _sound = _prefs.sound,
        _haptics = _prefs.haptics {
    audio.enabled = _sound;
    _unlockedSkins = _prefs.unlockedSkins.toSet()..add('klasik');
    _selectedSkin = _prefs.selectedSkin;
    CoreColors.active = SkinCatalog.byId(_selectedSkin).colors;
  }

  // ----- Batik skins -----
  String get selectedSkin => _selectedSkin;
  bool isSkinUnlocked(String id) => _unlockedSkins.contains(id);

  /// Buy [skin] with coins (and equip it). Returns false if too poor / owned.
  bool buySkin(Skin skin) {
    if (_unlockedSkins.contains(skin.id)) return false;
    if (!spendCoins(skin.cost)) return false;
    _unlockedSkins.add(skin.id);
    _prefs.setUnlockedSkins(_unlockedSkins.toList());
    selectSkin(skin.id);
    return true;
  }

  void selectSkin(String id) {
    if (!_unlockedSkins.contains(id)) return;
    _selectedSkin = id;
    _prefs.setSelectedSkin(id);
    CoreColors.active = SkinCatalog.byId(id).colors;
    notifyListeners();
  }

  /// Show an interstitial on roughly every 2nd game-over (called on restart).
  Future<void> maybeShowInterstitial() async {
    _overCount++;
    if (_overCount % 2 == 0) await ads.maybeShowInterstitial();
  }

  /// Play an SFX if sound is on. Called by gameplay code.
  void playSfx(Sfx s) {
    if (_sound) audio.play(s);
  }

  int get highScore => _highScore;
  int get coins => _coins;
  bool get sound => _sound;
  bool get haptics => _haptics;
  bool get firstRun => _prefs.firstRun;

  /// Returns true if [score] beat the stored best (so UI can celebrate).
  bool submitScore(int score) {
    if (score > _highScore) {
      _highScore = score;
      _prefs.setHighScore(score);
      notifyListeners();
      return true;
    }
    return false;
  }

  void addCoins(int n) {
    if (n <= 0) return;
    _coins += n;
    _prefs.setCoins(_coins);
    notifyListeners();
  }

  bool spendCoins(int n) {
    if (_coins < n) return false;
    _coins -= n;
    _prefs.setCoins(_coins);
    notifyListeners();
    return true;
  }

  void setSound(bool v) {
    _sound = v;
    audio.enabled = v;
    _prefs.setSound(v);
    notifyListeners();
  }

  void setHaptics(bool v) {
    _haptics = v;
    _prefs.setHaptics(v);
    notifyListeners();
  }

  void markOnboarded() => _prefs.setFirstRunDone();
}
