import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../services/ads/ads_service.dart';
import '../../state/app_state.dart';
import '../../state/game_controller.dart';
import '../../widgets/batik.dart';
import 'widgets/board_view.dart';
import 'widgets/piece_widget.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GlobalKey _boardKey = GlobalKey();
  double _boardCell = 40;

  int? _dragIndex;
  int _ghostCol = 0, _ghostRow = 0;
  bool _ghostValid = false;
  int _tick = 0;

  static const double _liftCells = 1.3; // raise the piece above the finger

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

    return Scaffold(
      body: BatikBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _Hud(score: gc.score, best: app.highScore, combo: gc.combo, coins: app.coins),
                  Expanded(child: _buildBoard(gc)),
                  _buildTray(gc),
                  const SizedBox(height: 12),
                ],
              ),
              if (gc.isGameOver)
                _GameOverOverlay(
                  score: gc.score,
                  best: app.highScore,
                  isNewBest: gc.isNewBest,
                  onRevive: () => _revive(context, gc, app),
                  onRestart: () => gc.newGame(),
                  onHome: () => Navigator.of(context).maybePop(),
                ),
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
            child: CustomPaint(
              painter: BoardPainter(
                engine: gc.engine,
                ghostPiece: _dragIndex != null ? gc.tray[_dragIndex!] : null,
                ghostCol: _ghostCol,
                ghostRow: _ghostRow,
                ghostValid: _ghostValid,
                repaintTick: _tick + gc.score,
              ),
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
  const _Hud({required this.score, required this.best, required this.combo, required this.coins});

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
              const Spacer(),
              _Pill(icon: Icons.monetization_on, label: '$coins', color: Palette.gold),
              const SizedBox(width: 8),
              _Pill(icon: Icons.emoji_events, label: '$best', color: Palette.cream),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$score',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Palette.cream,
              height: 1,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.panel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      ]),
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
          color: Palette.bg1,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Palette.gold.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
