import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../services/ads/ads_service.dart';
import '../../state/app_state.dart';
import '../../state/game_controller.dart';
import '../../game/models/cell.dart';
import '../../widgets/batik.dart';
import '../../widgets/mascot.dart';
import 'widgets/board_view.dart';
import 'widgets/clear_fx.dart';
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
  int _tick = 0;

  static const double _liftCells = 1.3; // raise the piece above the finger

  // Line-clear flash + score-pop animation.
  late final AnimationController _fx;
  int _seenClearEvent = 0;
  List<Cell> _fxCells = const [];
  int _fxGained = 0;
  int _fxLines = 0;
  int _fxCombo = 0;

  bool _howToChecked = false;
  bool _showHowTo = false;

  @override
  void initState() {
    super.initState();
    _fx = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void dispose() {
    _fx.dispose();
    super.dispose();
  }

  /// Trigger the clear animation once per new clear event from the controller.
  void _syncClearFx(GameController gc) {
    if (gc.clearEvent != _seenClearEvent) {
      _seenClearEvent = gc.clearEvent;
      _fxCells = gc.lastClearedCells;
      _fxGained = gc.lastGained;
      _fxLines = gc.lastLines;
      _fxCombo = gc.combo;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fx.forward(from: 0);
      });
    }
  }

  void _onDragStarted(int index) {
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
      });
    }
  }

  void _onDragEnd(GameController gc, int index) {
    if (_ghostValid) {
      gc.place(index, _ghostCol, _ghostRow);
    }
    setState(() {
      _dragIndex = null;
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
    if (!_howToChecked) {
      _howToChecked = true;
      _showHowTo = app.firstRun;
    }

    return Scaffold(
      body: BatikBackground(
        child: SafeArea(
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
                  Expanded(child: _buildBoard(gc)),
                  _buildTray(gc),
                  _PowerupBar(
                    hammers: app.hammers,
                    shuffles: app.shuffles,
                    hammerArmed: gc.hammerArmed,
                    onHammer: () => app.hammers > 0 ? gc.armHammer() : app.buyPowerup('hammer'),
                    onShuffle: () => app.shuffles > 0 ? gc.useShuffle() : app.buyPowerup('shuffle'),
                  ),
                  const SizedBox(height: 10),
                ],
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
                    repaintTick: _tick + gc.score,
                  ),
                ),
                if (gc.hammerArmed)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) {
                      final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
                      if (box == null) return;
                      final local = box.globalToLocal(d.globalPosition);
                      final col = (local.dx / _boardCell).floor();
                      final row = (local.dy / _boardCell).floor();
                      gc.useHammerAt(col, row);
                      setState(() => _tick++);
                    },
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
    return SizedBox(
      height: cell * 3.4,
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
            feedback: PieceWidget(piece: piece, cell: feedbackCell, opacity: 0.92),
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Text(
              '$score',
              key: ValueKey<int>(score),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Palette.cream,
                height: 1,
              ),
            ),
          ),
          SizedBox(
            height: 22,
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

class _PowerupBar extends StatelessWidget {
  final int hammers, shuffles;
  final bool hammerArmed;
  final VoidCallback onHammer, onShuffle;
  const _PowerupBar({
    required this.hammers,
    required this.shuffles,
    required this.hammerArmed,
    required this.onHammer,
    required this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, String label, int count, bool active, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
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
              Row(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.add, color: Palette.coral, size: 14),
                Icon(Icons.monetization_on, color: Palette.coral, size: 13),
                Text(' 40', style: TextStyle(color: Palette.coral, fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
          ]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          btn(Icons.gavel_rounded, 'Palu', hammers, hammerArmed, onHammer),
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
            step(Icons.touch_app, 'Seret balok dari bawah ke papan 8×8.'),
            step(Icons.view_week, 'Penuhi satu baris atau kolom untuk membersihkannya.'),
            step(Icons.bolt, 'Bersihkan beberapa garis berturut-turut untuk COMBO & skor besar.'),
            step(Icons.warning_amber, 'Balok yang tak muat di mana pun akan meredup — hati-hati!'),
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
