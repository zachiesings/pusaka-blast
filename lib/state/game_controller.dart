import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import '../game/engine/block_engine.dart';
import '../game/models/block_piece.dart';
import '../game/models/cell.dart';
import '../game/pieces.dart';
import '../services/audio/audio_service.dart';
import 'app_state.dart';

/// Drives a single play session: the board engine, the 3-piece tray, score and
/// combo. Persists best score / coins through [AppState].
class GameController extends ChangeNotifier {
  final AppState app;
  final BlockEngine engine = BlockEngine(size: K.gridSize);
  final Random _rng = Random();

  final List<BlockPiece?> tray = List<BlockPiece?>.filled(K.trayCount, null);

  int score = 0;
  int combo = 0;        // consecutive line-clearing placements
  int lastGained = 0;   // for the floating "+N" indicator
  int lastLines = 0;    // lines cleared on the last move
  bool isGameOver = false;
  bool isNewBest = false;

  /// Cells removed by the most recent line clear + a monotonic counter the UI
  /// watches to trigger the clear animation exactly once per event.
  List<Cell> lastClearedCells = const [];
  int clearEvent = 0;

  GameController(this.app);

  void newGame() {
    engine.reset();
    score = 0;
    combo = 0;
    lastGained = 0;
    lastLines = 0;
    isGameOver = false;
    isNewBest = false;
    _refillTray();
    notifyListeners();
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

    score += result.gained;
    lastGained = result.gained;
    lastLines = result.linesCleared;

    if (result.linesCleared > 0) {
      combo++;
      lastClearedCells = result.clearedCells;
      clearEvent++;
      app.addCoins(result.linesCleared); // coins fund the "double coins" reward
      app.playSfx(combo > 1 ? Sfx.combo : Sfx.clear);
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
    if (!anyFits) {
      isGameOver = true;
      isNewBest = app.submitScore(score);
      app.playSfx(Sfx.gameover);
    }
  }

  /// Ad-rewarded revive: wipe the board (keep the score) and continue. The
  /// caller shows the rewarded ad first and only calls this if it returned true.
  void revive() {
    engine.reset();
    combo = 0;
    isGameOver = false;
    _refillTray();
    notifyListeners();
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
