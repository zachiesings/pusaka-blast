import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import '../game/engine/block_engine.dart';
import '../game/game_mode.dart';
import '../game/models/block_piece.dart';
import '../game/models/cell.dart';
import '../game/pieces.dart';
import '../services/audio/audio_service.dart';
import 'app_state.dart';

/// Drives a single play session: the board engine, the 3-piece tray, score and
/// combo. Persists best score / coins through [AppState].
class GameController extends ChangeNotifier {
  final AppState app;
  final BlastMode mode;
  final BlockEngine engine = BlockEngine(size: K.gridSize);
  final Random _rng = Random();

  final List<BlockPiece?> tray = List<BlockPiece?>.filled(K.trayCount, null);

  int score = 0;
  int combo = 0;        // consecutive line-clearing placements
  int lastGained = 0;   // for the floating "+N" indicator
  int lastLines = 0;    // lines cleared on the last move
  bool isGameOver = false;
  bool isNewBest = false;

  int timeLeft = 0;     // seconds remaining (time-attack)
  bool hammerArmed = false; // next board tap clears a cell
  bool bombArmed = false;   // next board tap clears a 3x3 area
  Timer? _timer;

  List<Cell> lastClearedCells = const [];
  int clearEvent = 0;
  int specialEvent = 0; // bumped on a big "Pukulan Gamelan" combo (screen flash + shake)
  bool lastPerfect = false; // last special was a perfect board clear
  List<Cell> lastFilledCells = const []; // cells the last piece occupied (pop-in FX)
  int placeEvent = 0;

  // ----- Berkah Keraton: clear-fuelled x2 mode -----
  double berkahMeter = 0;   // 0..1, fills with each clearing move
  int berkahClears = 0;     // remaining x2 clears while a Berkah is active
  bool berkahJustTriggered = false; // bumped the frame a Berkah starts
  bool get berkahActive => berkahClears > 0;
  int maxCombo = 0;         // best combo this run (game-over summary)
  int berkahCount = 0;      // Berkah triggers this run

  GameController(this.app, {this.mode = BlastMode.klasik});

  void newGame() {
    engine.reset();
    score = 0;
    combo = 0;
    lastGained = 0;
    lastLines = 0;
    isGameOver = false;
    isNewBest = false;
    hammerArmed = false;
    bombArmed = false;
    berkahMeter = 0;
    berkahClears = 0;
    maxCombo = 0;
    berkahCount = 0;
    _refillTray();
    _timer?.cancel();
    if (mode.timed) {
      timeLeft = mode.seconds;
      _startTimer();
    }
    notifyListeners();
  }

  // ----- Power-ups -----
  void useShuffle() {
    if (isGameOver || !app.consumeShuffle()) return;
    _refillTray();
    app.playSfx(Sfx.place);
    notifyListeners();
  }

  void armHammer() {
    if (isGameOver || app.hammers <= 0) return;
    hammerArmed = !hammerArmed;
    bombArmed = false;
    notifyListeners();
  }

  void armBomb() {
    if (isGameOver || app.bombs <= 0) return;
    bombArmed = !bombArmed;
    hammerArmed = false;
    notifyListeners();
  }

  void useToolAt(int col, int row) {
    if (hammerArmed) {
      if (engine.clearCell(col, row) && app.consumeHammer()) {
        app.playSfx(Sfx.clear);
        _haptic(HapticFeedbackLevel.medium);
      }
      hammerArmed = false;
    } else if (bombArmed) {
      if (app.consumeBomb()) {
        engine.clearArea(col, row);
        app.playSfx(Sfx.gong);
        _haptic(HapticFeedbackLevel.medium);
      }
      bombArmed = false;
    } else {
      return;
    }
    isGameOver = false; // clearing may re-open moves
    notifyListeners();
  }

  void _endGame() {
    if (isGameOver) return;
    isGameOver = true;
    _timer?.cancel();
    isNewBest = app.submitScore(score);
    app.recordGameOver();
    app.playSfx(Sfx.gameover);
  }

  void _refillTray() {
    final fresh = PieceCatalog.generateTray(K.trayCount, _rng);
    for (var i = 0; i < K.trayCount; i++) {
      tray[i] = fresh[i];
    }
  }

  bool canPlace(int trayIndex, int col, int row) {
    final p = tray[trayIndex];
    if (p == null) return false;
    return engine.canPlace(p, col, row);
  }

  /// Attempt to drop tray piece [trayIndex] at board (col,row). Returns true on
  /// success. Handles scoring, combo, coins, tray refill and game-over.
  bool place(int trayIndex, int col, int row) {
    final piece = tray[trayIndex];
    if (piece == null || !engine.canPlace(piece, col, row)) return false;

    final result = engine.place(piece, col, row, comboMultiplier: combo + 1);
    if (!result.placed) return false;

    lastFilledCells = result.filledCells;
    placeEvent++;
    berkahJustTriggered = false;
    var gained = result.gained;
    if (berkahActive && result.linesCleared > 0) {
      gained *= 2; // Berkah Keraton doubles clear scores
      berkahClears--;
    }
    score += gained;
    lastGained = gained;
    lastLines = result.linesCleared;

    if (result.linesCleared > 0) {
      combo++;
      if (combo > maxCombo) maxCombo = combo;
      lastClearedCells = result.clearedCells;
      clearEvent++;
      // Fill the Berkah meter; when full, light up a x2 streak.
      berkahMeter += 0.13 * result.linesCleared;
      if (berkahMeter >= 1.0 && !berkahActive) {
        berkahMeter = 0;
        berkahClears = 3;
        berkahJustTriggered = true;
        berkahCount++;
        specialEvent++;
        app.playSfx(Sfx.gong);
      }
      app.recordLines(result.linesCleared);
      app.addCoins(result.linesCleared); // coins fund the "double coins" reward
      lastPerfect = result.boardCleared;
      if (result.boardCleared) {
        specialEvent++;
        app.addCoins(5); // perfect-clear coin bonus
        app.playSfx(Sfx.gong);
      } else if (combo >= 3 || result.linesCleared >= 3) {
        specialEvent++;
        app.playSfx(Sfx.gong); // Pukulan Gamelan!
      } else {
        app.playSfx(combo > 1 ? Sfx.combo : Sfx.clear);
      }
      _haptic(HapticFeedbackLevel.medium);
    } else {
      combo = 0;
      app.playSfx(Sfx.place);
      _haptic(HapticFeedbackLevel.light);
    }

    tray[trayIndex] = null;
    if (tray.every((p) => p == null)) _refillTray();

    _checkGameOver();
    notifyListeners();
    return true;
  }

  void _checkGameOver() {
    final remaining = tray.whereType<BlockPiece>();
    if (remaining.isEmpty) return; // about to refill
    final anyFits = remaining.any(engine.hasAnyPlacement);
    if (!anyFits) _endGame();
  }

  /// Ad-rewarded revive: wipe the board (keep the score) and continue. The
  /// caller shows the rewarded ad first and only calls this if it returned true.
  void revive() {
    engine.reset();
    combo = 0;
    isGameOver = false;
    if (mode.timed) {
      if (timeLeft <= 0) timeLeft = 30; // give time back on revive
      _startTimer(); // restart the (cancelled) countdown
    }
    _refillTray();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isGameOver) return;
      timeLeft--;
      if (timeLeft <= 0) {
        timeLeft = 0;
        _endGame();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _haptic(HapticFeedbackLevel level) {
    if (!app.haptics) return;
    switch (level) {
      case HapticFeedbackLevel.light:
        HapticFeedback.selectionClick();
      case HapticFeedbackLevel.medium:
        HapticFeedback.lightImpact();
    }
  }
}

enum HapticFeedbackLevel { light, medium }
