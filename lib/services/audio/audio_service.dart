import 'package:audioplayers/audioplayers.dart';

enum Sfx { place, clear, combo, gameover, tap }

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
  };

  final List<AudioPlayer> _pool;
  int _next = 0;
  bool enabled = true;

  final AudioPlayer _bgm = AudioPlayer();
  bool musicEnabled = true;
  bool _bgmPlaying = false;

  AudioService() : _pool = List.generate(4, (_) => AudioPlayer()) {
    for (final p in _pool) {
      p.setReleaseMode(ReleaseMode.stop);
      p.setPlayerMode(PlayerMode.lowLatency);
    }
    _bgm.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> startBgm() async {
    if (!musicEnabled || _bgmPlaying) return;
    _bgmPlaying = true;
    try {
      await _bgm.play(AssetSource('audio/bgm_home.wav'), volume: 0.55);
    } catch (_) {
      _bgmPlaying = false;
    }
  }

  Future<void> stopBgm() async {
    _bgmPlaying = false;
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
