import 'package:audioplayers/audioplayers.dart';

enum Sfx { place, clear, combo, gameover, tap, gong, move }

/// Plays the original synthesized SFX. A small round-robin pool of players lets
/// rapid sounds overlap without cutting each other off. All playback is gated by
/// the user's sound setting via [enabled].
class AudioService {
  static const Map<Sfx, String> _files = {
    Sfx.place: 'audio/place.wav',
    Sfx.clear: 'audio/clear.wav',
    Sfx.combo: 'audio/combo.wav',
    Sfx.gameover: 'audio/gameover.wav',
    Sfx.tap: 'audio/tap.wav',
    Sfx.gong: 'audio/gong.wav',
    Sfx.move: 'audio/move.wav',
  };

  final List<AudioPlayer> _pool;
  int _next = 0;
  bool enabled = true;

  final AudioPlayer _bgm = AudioPlayer();
  bool musicEnabled = true;
  String _track = ''; // currently-playing bgm asset ('' = none)

  AudioService() : _pool = List.generate(4, (_) => AudioPlayer()) {
    for (final p in _pool) {
      p.setReleaseMode(ReleaseMode.stop);
      p.setPlayerMode(PlayerMode.lowLatency);
    }
    _bgm.setReleaseMode(ReleaseMode.loop);
  }

  /// Home-screen regal gendhing.
  Future<void> startBgm() => _playTrack('audio/bgm_home.wav', 0.5);

  /// Driving in-game gamelan groove (distinct track).
  Future<void> startGameBgm() => _playTrack('audio/bgm_game.wav', 0.42);

  Future<void> _playTrack(String asset, double vol) async {
    if (!musicEnabled) return;
    if (_track == asset) return; // already on this track
    _track = asset;
    try {
      await _bgm.stop();
      await _bgm.play(AssetSource(asset), volume: vol);
    } catch (_) {
      _track = '';
    }
  }

  Future<void> stopBgm() async {
    _track = '';
    try {
      await _bgm.stop();
    } catch (_) {}
  }

  void setMusicEnabled(bool v) {
    musicEnabled = v;
    if (!v) stopBgm();
  }

  Future<void> play(Sfx s) async {
    if (!enabled) return;
    final p = _pool[_next];
    _next = (_next + 1) % _pool.length;
    try {
      await p.stop();
      await p.play(AssetSource(_files[s]!), volume: 0.9);
    } catch (_) {
      // Audio is non-essential — never let a playback error reach gameplay.
    }
  }

  void dispose() {
    for (final p in _pool) {
      p.dispose();
    }
    _bgm.dispose();
  }
}
