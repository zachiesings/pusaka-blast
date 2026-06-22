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
  bool _music;
  late Set<String> _unlockedSkins;
  late String _selectedSkin;
  int _overCount = 0; // game-overs, for interstitial cadence

  AppState(this._prefs, this.ads, this.audio)
      : _highScore = _prefs.highScore,
        _coins = _prefs.coins,
        _sound = _prefs.sound,
        _music = _prefs.music,
        _haptics = _prefs.haptics {
    audio.enabled = _sound;
    audio.musicEnabled = _music;
    _unlockedSkins = _prefs.unlockedSkins.toSet()..add('klasik');
    _selectedSkin = _prefs.selectedSkin;
    CoreColors.active = SkinCatalog.byId(_selectedSkin).colors;
    _loadPowerups();
  }

  bool get music => _music;
  void setMusic(bool v) {
    _music = v;
    audio.setMusicEnabled(v);
    if (v) audio.startBgm();
    _prefs.setMusic(v);
    notifyListeners();
  }

  void startHomeMusic() => audio.startBgm();
  void stopHomeMusic() => audio.stopBgm();

  // ----- Power-ups -----
  int _hammers = 0, _shuffles = 0, _bombs = 0;
  int get hammers => _hammers;
  int get shuffles => _shuffles;
  int get bombs => _bombs;
  void _loadPowerups() {
    _hammers = _prefs.hammers;
    _shuffles = _prefs.shuffles;
    _bombs = _prefs.bombs;
  }

  /// Buy a power-up (kind: 'hammer'|'shuffle'|'bomb') with coins.
  bool buyPowerup(String kind) {
    if (!spendCoins(40)) return false;
    if (kind == 'hammer') {
      _hammers++;
      _prefs.setHammers(_hammers);
    } else if (kind == 'bomb') {
      _bombs++;
      _prefs.setBombs(_bombs);
    } else {
      _shuffles++;
      _prefs.setShuffles(_shuffles);
    }
    notifyListeners();
    return true;
  }

  bool consumeBomb() {
    if (_bombs <= 0) return false;
    _bombs--;
    _prefs.setBombs(_bombs);
    notifyListeners();
    return true;
  }

  // ----- Daily reward -----
  int get _today => DateTime.now().millisecondsSinceEpoch ~/ 86400000;
  bool get dailyClaimable => _prefs.lastClaimDay != _today;
  int get dailyStreak => _prefs.streak;

  /// Claim today's reward. Returns (coins, streak), or (0,0) if already claimed.
  (int, int) claimDaily() {
    if (!dailyClaimable) return (0, 0);
    final streak = _prefs.lastClaimDay == _today - 1 ? _prefs.streak + 1 : 1;
    final reward = 20 + (streak - 1).clamp(0, 6) * 10;
    _prefs.setLastClaimDay(_today);
    _prefs.setStreak(streak);
    addCoins(reward);
    return (reward, streak);
  }

  bool consumeHammer() {
    if (_hammers <= 0) return false;
    _hammers--;
    _prefs.setHammers(_hammers);
    notifyListeners();
    return true;
  }

  bool consumeShuffle() {
    if (_shuffles <= 0) return false;
    _shuffles--;
    _prefs.setShuffles(_shuffles);
    notifyListeners();
    return true;
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
