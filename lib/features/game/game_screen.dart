import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../services/ads/ads_service.dart';
import '../../services/audio/audio_service.dart';
import '../../state/app_state.dart';
import '../../state/game_controller.dart';
import '../../game/game_mode.dart';
import '../../game/models/cell.dart';
import '../../widgets/batik.dart';
import '../../widgets/mascot.dart';
import 'widgets/board_view.dart';
import 'widgets/game_backdrop.dart';
import 'widgets/clear_fx.dart';
import 'widgets/place_fx.dart';
import 'widgets/piece_widget.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  final GlobalKey _boardKey = GlobalKey();
  double _boardCell = 40;

  int? _dragIndex;
  int _ghostCol = 0, _ghostRow = 0;
  bool _ghostValid = false;
  List<Cell> _previewCells = const []; // lines that would clear at the ghost spot
  int _tick = 0;

  static const double _liftCells = 1.3; // raise the piece above the finger

  // Line-clear flash + score-pop animation.
  late final AnimationController _fx;
  late final AnimationController _placeFx; // piece pop-in
  int _seenPlaceEvent = 0;
  List<Cell> _placeCells = const [];
  int _seenClearEvent = 0;
  int _seenSpecial = 0;
  bool _wasSpecial = false;
  bool _wasPerfect = false;
  bool _wasBerkah = false;
  List<Cell> _fxCells = const [];
  int _fxGained = 0;
  int _fxLines = 0;
  int _fxCombo = 0;

  bool _howToChecked = false;
  bool _showHowTo = false;

  AppState? _app;

  @override
  void initState() {
    super.initState();
    _fx = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _placeFx = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_app == null) {
      _app = context.read<AppState>();
      _app!.startGameMusic(); // switch to the driving in-game track
    }
  }

  @override
  void dispose() {
    _app?.startHomeMusic(); // restore the home gendhing on the way out
    _fx.dispose();
    _placeFx.dispose();
    super.dispose();
  }

  void _syncPlaceFx(GameController gc) {
    if (gc.placeEvent != _seenPlaceEvent) {
      _seenPlaceEvent = gc.placeEvent;
      _placeCells = gc.lastFilledCells;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _placeFx.forward(from: 0);
      });
    }
  }

  /// Trigger the clear animation once per new clear event from the controller.
  void _syncClearFx(GameController gc) {
    if (gc.clearEvent != _seenClearEvent) {
      _seenClearEvent = gc.clearEvent;
      _fxCells = gc.lastClearedCells;
      _fxGained = gc.lastGained;
      _fxLines = gc.lastLines;
      _fxCombo = gc.combo;
      _wasSpecial = gc.specialEvent != _seenSpecial;
      _wasPerfect = gc.lastPerfect;
      _wasBerkah = gc.berkahJustTriggered;
      _seenSpecial = gc.specialEvent;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fx.forward(from: 0);
      });
    }
  }

  void _onDragStarted(int index) {
    _app?.playSfx(Sfx.move); // soft wood "tuk" on lift
    setState(() {
      _dragIndex = index;
      _ghostValid = false;
    });
  }

  void _onDragUpdate(GameController gc, int index, Offset globalPos) {
    final piece = gc.tray[index];
    if (piece == null) return;
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(globalPos);
    final cell = _boardCell;
    final n = K.gridSize;

    var col = ((local.dx - piece.width * cell / 2) / cell).round();
    var row = ((local.dy - cell * _liftCells - piece.height * cell / 2) / cell).round();
    col = col.clamp(0, n - piece.width);
    row = row.clamp(0, n - piece.height);

    final valid = gc.engine.canPlace(piece, col, row);
    if (col != _ghostCol || row != _ghostRow || valid != _ghostValid) {
      setState(() {
        _ghostCol = col;
        _ghostRow = row;
        _ghostValid = valid;
        _previewCells = valid ? gc.engine.previewClears(piece, col, row) : const [];
      });
    }
  }

  void _onDragEnd(GameController gc, int index) {
    if (_ghostValid) {
      gc.place(index, _ghostCol, _ghostRow);
    }
    setState(() {
      _dragIndex = null;
      _previewCells = const [];
      _tick++;
    });
  }

  Future<void> _revive(BuildContext context, GameController gc, AppState app) async {
    final ok = await app.ads.showRewarded(RewardKind.revive);
    if (!context.mounted) return;
    if (ok) {
      gc.revive();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iklan belum siap, coba lagi sebentar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.watch<GameController>();
    final app = context.watch<AppState>();
    _syncClearFx(gc);
    _syncPlaceFx(gc);
    if (!_howToChecked) {
      _howToChecked = true;
      _showHowTo = app.firstRun;
    }

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: GameBackdrop()),
          SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _Hud(
                    score: gc.score,
                    best: app.highScore,
                    combo: gc.combo,
                    coins: app.coins,
                    timeLeft: gc.mode.timed ? gc.timeLeft : null,
                  ),
                  // Berkah Keraton meter
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 2, 28, 0),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            color: gc.berkahActive ? Palette.gold : Palette.goldSoft, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: gc.berkahActive ? 1.0 : gc.berkahMeter,
                              minHeight: 5,
                              backgroundColor: Palette.panel.withOpacity(0.6),
                              color: gc.berkahActive ? Palette.gold : Palette.goldSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _fx,
                      builder: (_, child) {
                        final amp = _fxLines >= 2 ? (1 - _fx.value) * (_wasSpecial ? 12 : 5) : 0.0;
                        final dx = math.sin(_fx.value * math.pi * 8) * amp;
                        return Transform.translate(offset: Offset(dx, 0), child: child);
                      },
                      child: _buildBoard(gc),
                    ),
                  ),
                  _buildTray(gc),
                  _PowerupBar(
                    hammers: app.hammers,
                    shuffles: app.shuffles,
                    bombs: app.bombs,
                    hammerArmed: gc.hammerArmed,
                    bombArmed: gc.bombArmed,
                    onHammer: () {
                      if (app.hammers > 0) {
                        gc.armHammer();
                      } else {
                        app.rewardedPowerup('hammer');
                      }
                    },
                    onShuffle: () {
                      if (app.shuffles > 0) {
                        gc.useShuffle();
                      } else {
                        app.rewardedPowerup('shuffle');
                      }
                    },
                    onBomb: () {
                      if (app.bombs > 0) {
                        gc.armBomb();
                      } else {
                        app.rewardedPowerup('bomb');
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
              if (gc.berkahActive && !gc.isGameOver)
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.0,
                        colors: [Colors.transparent, Palette.gold.withOpacity(0.16)],
                        stops: const [0.58, 1.0],
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              if (gc.berkahActive && !gc.isGameOver)
                IgnorePointer(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 64),
                      child: Text('✦ BERKAH ×2 — ${gc.berkahClears} ✦',
                          style: const TextStyle(
                              color: Palette.gold,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1)),
                    ),
                  ),
                ),
              if (gc.combo > 1 && !gc.isGameOver)
                IgnorePointer(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 92),
                      child: Transform.scale(
                        scale: 1 + gc.combo.clamp(0, 8) * 0.06,
                        child: Text('COMBO ×${gc.combo}',
                            style: const TextStyle(
                                color: Palette.coral,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1)),
                      ),
                    ),
                  ),
                ),
              if (_wasSpecial)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _fx,
                      builder: (_, __) {
                        if (_fx.value >= 1) return const SizedBox.shrink();
                        final v = 1 - _fx.value;
                        return Stack(
                          children: [
                            Positioned.fill(
                                child: ColoredBox(color: Palette.gold.withOpacity(0.2 * v))),
                            Center(
                              child: Opacity(
                                opacity: v,
                                child: Transform.scale(
                                  scale: 0.8 + (1 - v) * 0.5,
                                  child: Text(
                                      _wasBerkah
                                          ? 'BERKAH KERATON!'
                                          : _wasPerfect
                                              ? 'PAPAN BERSIH!'
                                              : 'PUKULAN GAMELAN!',
                                      style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: Palette.gold,
                                          letterSpacing: 1)),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              if (gc.isGameOver)
                _GameOverOverlay(
                  score: gc.score,
                  best: app.highScore,
                  isNewBest: gc.isNewBest,
                  onRevive: () => _revive(context, gc, app),
                  onRestart: () async {
                    await app.maybeShowInterstitial();
                    gc.newGame();
                  },
                  onHome: () => Navigator.of(context).maybePop(),
                ),
              if (_showHowTo)
                _HowToOverlay(onClose: () {
                  setState(() => _showHowTo = false);
                  context.read<AppState>().markOnboarded();
                }),
            ],
          ),
        ),
          ],
        ),
    );
  }

  Widget _buildBoard(GameController gc) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardPx =
            (constraints.maxWidth < constraints.maxHeight ? constraints.maxWidth : constraints.maxHeight) - 24;
        _boardCell = boardPx / K.gridSize;
        return Center(
          child: SizedBox(
            key: _boardKey,
            width: boardPx,
            height: boardPx,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: BoardPainter(
                    engine: gc.engine,
                    ghostPiece: _dragIndex != null ? gc.tray[_dragIndex!] : null,
                    ghostCol: _ghostCol,
                    ghostRow: _ghostRow,
                    ghostValid: _ghostValid,
                    previewClears: _previewCells,
                    repaintTick: _tick + gc.score,
                  ),
                ),
                if (gc.hammerArmed || gc.bombArmed)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) {
                      final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
                      if (box == null) return;
                      final local = box.globalToLocal(d.globalPosition);
                      final col = (local.dx / _boardCell).floor();
                      final row = (local.dy / _boardCell).floor();
                      gc.useToolAt(col, row);
                      setState(() => _tick++);
                    },
                  ),
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _placeFx,
                    builder: (_, __) => CustomPaint(
                      painter: PlacePopPainter(
                        cells: _placeCells,
                        gridSize: K.gridSize,
                        t: _placeFx.value,
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _fx,
                    builder: (_, __) => CustomPaint(
                      painter: ClearFxPainter(
                        cells: _fxCells,
                        gridSize: K.gridSize,
                        t: _fx.value,
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _fx,
                    builder: (_, __) {
                      if (_fxCells.isEmpty || _fx.value >= 1) {
                        return const SizedBox.shrink();
                      }
                      final t = _fx.value;
                      return Center(
                        child: Opacity(
                          opacity: (1 - t).clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, -boardPx * 0.10 - t * 42),
                            child: _ScorePop(gained: _fxGained, lines: _fxLines, combo: _fxCombo),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTray(GameController gc) {
    final cell = (_boardCell * 0.62).clamp(20.0, 44.0);
    return Container(
      height: cell * 3.4,
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.panel.withOpacity(0.7), Palette.bg1.withOpacity(0.5)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Palette.gold.withOpacity(0.3), width: 1.2),
        boxShadow: Palette.glow(Palette.gold, blur: 16, a: 0.12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(K.trayCount, (i) {
          final piece = gc.tray[i];
          if (piece == null) {
            return SizedBox(width: cell * 3, height: cell * 3);
          }
          // Grey out (and disable dragging) pieces that fit nowhere — a clear
          // hint that the board is getting tight / game over is near.
          if (!gc.engine.hasAnyPlacement(piece)) {
            return Opacity(opacity: 0.28, child: PieceWidget(piece: piece, cell: cell));
          }
          final feedbackCell = _boardCell;
          final feedbackW = piece.width * feedbackCell;
          final feedbackH = piece.height * feedbackCell;
          return Draggable<int>(
            data: i,
            dragAnchorStrategy: (draggable, ctx, pos) =>
                Offset(feedbackW / 2, feedbackH / 2 + feedbackCell * _liftCells),
            feedback: PieceWidget(piece: piece, cell: feedbackCell, opacity: 0.98, glow: true),
            childWhenDragging: Opacity(
              opacity: 0.25,
              child: PieceWidget(piece: piece, cell: cell),
            ),
            onDragStarted: () => _onDragStarted(i),
            onDragUpdate: (d) => _onDragUpdate(gc, i, d.globalPosition),
            onDragEnd: (_) => _onDragEnd(gc, i),
            onDraggableCanceled: (_, __) => _onDragEnd(gc, i),
            child: PieceWidget(piece: piece, cell: cell),
          );
        }),
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  final int score, best, combo, coins;
  final int? timeLeft;
  const _Hud(
      {required this.score,
      required this.best,
      required this.combo,
      required this.coins,
      this.timeLeft});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new, color: Palette.cream),
              ),
              MascotView(size: 50, mood: combo > 1 ? MascotMood.cheer : MascotMood.idle),
              const Spacer(),
              if (timeLeft != null) ...[
                _Pill(
                    icon: Icons.timer_rounded,
                    label: '${timeLeft}s',
                    color: timeLeft! <= 10 ? Palette.maroon : Palette.coral),
                const SizedBox(width: 8),
              ],
              _Pill(icon: Icons.monetization_on, label: '$coins', color: Palette.gold),
              const SizedBox(width: 8),
              _Pill(icon: Icons.emoji_events, label: '$best', color: Palette.cream),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _Diamond(),
              const SizedBox(width: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: ShaderMask(
                  key: ValueKey<int>(score),
                  shaderCallback: (b) => Palette.brand.createShader(b),
                  child: Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const _Diamond(),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 120,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Palette.gold.withOpacity(0),
                Palette.gold.withOpacity(0.6),
                Palette.gold.withOpacity(0),
              ]),
            ),
          ),
          SizedBox(
            height: 20,
            child: combo > 1
                ? Text('COMBO x$combo',
                    style: const TextStyle(
                        color: Palette.gold, fontWeight: FontWeight.w800, letterSpacing: 1.5))
                : null,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Pill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Palette.panel.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
        boxShadow: Palette.glow(color, blur: 12, a: 0.22),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

/// Small batik diamond ornament that flanks the score.
class _Diamond extends StatelessWidget {
  const _Diamond();
  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 12, height: 12, child: CustomPaint(painter: _DiamondPainter()));
}

class _DiamondPainter extends CustomPainter {
  const _DiamondPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final p = Path()
      ..moveTo(c.dx, 0)
      ..lineTo(size.width, c.dy)
      ..lineTo(c.dx, size.height)
      ..lineTo(0, c.dy)
      ..close();
    canvas.drawPath(p, Paint()..color = Palette.gold.withOpacity(0.8));
    canvas.drawPath(
        p,
        Paint()
          ..color = Palette.goldLt
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _PowerupBar extends StatelessWidget {
  final int hammers, shuffles, bombs;
  final bool hammerArmed, bombArmed;
  final VoidCallback onHammer, onShuffle, onBomb;
  const _PowerupBar({
    required this.hammers,
    required this.shuffles,
    required this.bombs,
    required this.hammerArmed,
    required this.bombArmed,
    required this.onHammer,
    required this.onShuffle,
    required this.onBomb,
  });

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, String label, int count, bool active, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: active ? Palette.gold.withOpacity(0.22) : Palette.panel.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: active ? Palette.gold : Palette.gold.withOpacity(0.25), width: active ? 2 : 1),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Palette.gold, size: 20),
            const SizedBox(width: 7),
            Text(label, style: const TextStyle(color: Palette.cream, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: Palette.gold, borderRadius: BorderRadius.circular(10)),
                child: Text('$count',
                    style: const TextStyle(
                        color: Palette.ink, fontWeight: FontWeight.w900, fontSize: 12)),
              )
            else
              const Icon(Icons.smart_display_rounded, color: Palette.coral, size: 18),
          ]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          btn(Icons.gavel_rounded, 'Palu', hammers, hammerArmed, onHammer),
          btn(Icons.dangerous_rounded, 'Bom', bombs, bombArmed, onBomb),
          btn(Icons.shuffle_rounded, 'Acak', shuffles, false, onShuffle),
        ],
      ),
    );
  }
}

class _HowToOverlay extends StatelessWidget {
  final VoidCallback onClose;
  const _HowToOverlay({required this.onClose});

  @override
  Widget build(BuildContext context) {
    Widget step(IconData icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Icon(icon, color: Palette.gold),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(color: Palette.cream, height: 1.3))),
          ]),
        );
    return Container(
      color: Colors.black.withOpacity(0.78),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.all(28),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Palette.panel, Palette.bg1],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Palette.gold.withOpacity(0.45), width: 1.5),
          boxShadow: Palette.glow(Palette.gold, blur: 36, a: 0.35),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Cara Bermain',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Palette.cream)),
            const SizedBox(height: 12),
            step(Icons.touch_app, 'Seret balok dari rak ke papan 8×8. Baris yang akan terhapus menyala hijau.'),
            step(Icons.view_week, 'Penuhi satu baris atau kolom untuk membersihkannya — bersihkan beberapa sekaligus untuk COMBO.'),
            step(Icons.auto_awesome, 'Isi meter emas untuk BERKAH KERATON — 3 pembersihan berikutnya skor ×2.'),
            step(Icons.dangerous, 'Pakai power-up Palu, Bom (3×3) & Acak saat papan sesak.'),
            step(Icons.cleaning_services, 'Kosongkan seluruh papan untuk bonus PAPAN BERSIH!'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: onClose, child: const Text('Mengerti, Main!')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScorePop extends StatelessWidget {
  final int gained, lines, combo;
  const _ScorePop({required this.gained, required this.lines, required this.combo});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Palette.ink.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text('+$gained',
              style: const TextStyle(
                  color: Palette.gold, fontSize: 30, fontWeight: FontWeight.w900)),
        ),
        if (combo > 1)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('COMBO x$combo',
                style: const TextStyle(
                    color: Palette.cream, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          ),
      ],
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final int score, best;
  final bool isNewBest;
  final VoidCallback onRevive, onRestart, onHome;
  const _GameOverOverlay({
    required this.score,
    required this.best,
    required this.isNewBest,
    required this.onRevive,
    required this.onRestart,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.72),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.all(28),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Palette.panel, Palette.bg1],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Palette.gold.withOpacity(0.45), width: 1.5),
          boxShadow: Palette.glow(isNewBest ? Palette.gold : Palette.maroon, blur: 40, a: 0.4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MascotView(size: 110, mood: isNewBest ? MascotMood.cheer : MascotMood.sad),
            const SizedBox(height: 4),
            Text(isNewBest ? 'Rekor Baru! 🎉' : 'Permainan Selesai',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Palette.cream)),
            const SizedBox(height: 16),
            Text('$score',
                style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Palette.gold)),
            Text('Terbaik: $best', style: const TextStyle(color: Palette.cream)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRevive,
                icon: const Icon(Icons.play_circle_fill),
                label: const Text('Lanjut — Tonton Iklan'),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onHome,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Palette.cream,
                    side: const BorderSide(color: Palette.goldSoft),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Beranda'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onRestart,
                  child: const Text('Main Lagi'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
