import 'package:flutter/foundation.dart';
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

  AppState(this._prefs, this.ads, this.audio)
      : _highScore = _prefs.highScore,
        _coins = _prefs.coins,
        _sound = _prefs.sound,
        _haptics = _prefs.haptics {
    audio.enabled = _sound;
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
