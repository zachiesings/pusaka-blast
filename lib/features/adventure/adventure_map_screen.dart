import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../game/wave.dart';
import '../../state/app_state.dart';
import '../../state/game_controller.dart';
import '../../widgets/roaming_mascot.dart';
import '../game/widgets/game_backdrop.dart';
import '../game/game_screen.dart';

/// Petualangan Nusantara — a winding map of the 20 campaign waves. Each node is
/// an heirloom to claim in a region of the archipelago; cleared nodes light the
/// gold trail and show their stars. The mascot strolls along the bottom.
class AdventureMapScreen extends StatefulWidget {
  /// When embedded in the home's bottom-nav shell the back button is hidden.
  final bool embedded;
  const AdventureMapScreen({super.key, this.embedded = false});

  @override
  State<AdventureMapScreen> createState() => _AdventureMapScreenState();
}

class _AdventureMapScreenState extends State<AdventureMapScreen> {
  static const double _gap = 132;     // vertical spacing between nodes
  static const double _topPad = 120;  // room for the header
  static const double _botPad = 150;  // room for the strolling mascot

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToCurrent());
  }

  void _jumpToCurrent() {
    if (!_scroll.hasClients) return;
    final app = context.read<AppState>();
    final i = (app.campaignUnlocked - 1).clamp(0, WaveCatalog.count - 1);
    final target = (_topPad + i * _gap - 240)
        .clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(target,
        duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double _fracX(int i) => 0.5 + 0.30 * math.sin(i * 0.9);

  Future<void> _playWave(BuildContext context, AppState app, WaveSpec w) async {
    app.stopHomeMusic();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<GameController>(
          create: (_) => GameController(app, wave: w)..newGame(),
          child: const GameScreen(),
        ),
      ),
    );
    if (!mounted) return;
    app.startHomeMusic();
    setState(() {}); // refresh stars / unlocks
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final totalH = _topPad + WaveCatalog.count * _gap + _botPad;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: GameBackdrop()),
          // ----- the scrolling trail -----
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final centers = List<Offset>.generate(
                  WaveCatalog.count,
                  (i) => Offset(_fracX(i) * w, _topPad + i * _gap),
                );
                return SingleChildScrollView(
                  controller: _scroll,
                  child: SizedBox(
                    width: w,
                    height: totalH,
                    child: Stack(
                      children: [
                        // the path itself
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _TrailPainter(
                              centers: centers,
                              unlocked: app.campaignUnlocked,
                            ),
                          ),
                        ),
                        // nodes
                        for (var i = 0; i < WaveCatalog.count; i++)
                          _positionedNode(context, app, i, centers[i]),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // ----- mascot strolling along the bottom (fixed) -----
          const Positioned(
            left: 0, right: 0, bottom: 0, height: 120,
            child: IgnorePointer(child: RoamingMascot(size: 70)),
          ),
          // ----- header -----
          _Header(totalStars: app.totalStars, showBack: !widget.embedded),
        ],
      ),
    );
  }

  Widget _positionedNode(BuildContext context, AppState app, int i, Offset c) {
    final w = WaveCatalog.all[i];
    const node = 76.0;
    final unlocked = app.isWaveUnlocked(w.index);
    final stars = app.starsForWave(w.index);
    final isCurrent = unlocked && stars == 0;
    return Positioned(
      left: c.dx - node / 2,
      top: c.dy - node / 2,
      width: node,
      height: node + 46,
      child: _WaveNode(
        spec: w,
        unlocked: unlocked,
        stars: stars,
        isCurrent: isCurrent,
        onTap: unlocked ? () => _showWaveSheet(context, app, w) : null,
      ),
    );
  }

  void _showWaveSheet(BuildContext context, AppState app, WaveSpec w) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _WaveSheet(
        spec: w,
        stars: app.starsForWave(w.index),
        onPlay: () {
          Navigator.of(context).pop();
          _playWave(context, app, w);
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int totalStars;
  final bool showBack;
  const _Header({required this.totalStars, this.showBack = true});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(showBack ? 8 : 20, 6, 16, 0),
        child: Row(
          children: [
            if (showBack)
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new, color: Palette.cream),
              ),
            const Expanded(
              child: Text('Petualangan Nusantara',
                  style: TextStyle(
                      color: Palette.cream, fontSize: 18, fontWeight: FontWeight.w900)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Palette.panel.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Palette.gold.withOpacity(0.4)),
                boxShadow: Palette.glow(Palette.gold, blur: 12, a: 0.18),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded, color: Palette.gold, size: 18),
                const SizedBox(width: 5),
                Text('$totalStars/${WaveCatalog.count * 3}',
                    style: const TextStyle(
                        color: Palette.gold, fontWeight: FontWeight.w900)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single heirloom node on the trail.
class _WaveNode extends StatefulWidget {
  final WaveSpec spec;
  final bool unlocked, isCurrent;
  final int stars;
  final VoidCallback? onTap;
  const _WaveNode({
    required this.spec,
    required this.unlocked,
    required this.isCurrent,
    required this.stars,
    this.onTap,
  });

  @override
  State<_WaveNode> createState() => _WaveNodeState();
}

class _WaveNodeState extends State<_WaveNode> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.spec;
    final locked = !widget.unlocked;
    final accent = locked ? Palette.goldSoft : w.accent;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, child) {
              final glow = widget.isCurrent ? (0.3 + _pulse.value * 0.5) : 0.22;
              return Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: locked
                        ? [Palette.panel, Palette.bg1]
                        : [Color.lerp(accent, Colors.white, 0.25)!, accent],
                  ),
                  border: Border.all(
                      color: widget.isCurrent ? Palette.goldLt : Palette.gold.withOpacity(0.6),
                      width: widget.isCurrent ? 3 : 2),
                  boxShadow: locked
                      ? null
                      : [BoxShadow(color: accent.withOpacity(glow), blurRadius: 22, spreadRadius: 1)],
                ),
                child: child,
              );
            },
            child: Center(
              child: locked
                  ? const Icon(Icons.lock_rounded, color: Palette.goldSoft, size: 26)
                  : widget.stars > 0
                      ? Icon(w.goal.icon, color: Palette.ink, size: 28)
                      : Text('${w.index}',
                          style: const TextStyle(
                              color: Palette.ink, fontSize: 26, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 4),
          // stars
          if (!locked)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (s) => Icon(
                  s < widget.stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 14,
                  color: s < widget.stars ? Palette.gold : Palette.goldSoft.withOpacity(0.5),
                ),
              ),
            )
          else
            Text('Wave ${w.index}',
                style: TextStyle(color: Palette.cream.withOpacity(0.4), fontSize: 11)),
        ],
      ),
    );
  }
}

/// Pre-game sheet: shows the heirloom, region, objective and best stars.
class _WaveSheet extends StatelessWidget {
  final WaveSpec spec;
  final int stars;
  final VoidCallback onPlay;
  const _WaveSheet({required this.spec, required this.stars, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Palette.panel, Palette.bg1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: spec.accent.withOpacity(0.6), width: 1.5),
        boxShadow: Palette.glow(spec.accent, blur: 36, a: 0.32),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: spec.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('WAVE ${spec.index} • ${spec.region.toUpperCase()}',
                style: TextStyle(
                    color: spec.accent, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
          const SizedBox(height: 10),
          Text(spec.title,
              style: const TextStyle(
                  color: Palette.cream, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(spec.motif,
              textAlign: TextAlign.center,
              style: TextStyle(color: Palette.cream.withOpacity(0.6), fontSize: 13, height: 1.3)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (s) => Icon(
                s < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 26,
                color: s < stars ? Palette.gold : Palette.goldSoft.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Palette.bg1.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Palette.gold.withOpacity(0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(spec.goal.icon, color: Palette.gold, size: 22),
              const SizedBox(width: 10),
              Flexible(
                child: Text(spec.goal.label(spec.target),
                    style: const TextStyle(
                        color: Palette.cream, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          if (spec.obstacles > 0 || spec.timed) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (spec.obstacles > 0) ...[
                  const Icon(Icons.grid_4x4_rounded, color: Palette.coral, size: 16),
                  const SizedBox(width: 4),
                  Text('${spec.obstacles} rintangan',
                      style: const TextStyle(color: Palette.coral, fontSize: 12)),
                ],
                if (spec.obstacles > 0 && spec.timed) const SizedBox(width: 14),
                if (spec.timed) ...[
                  const Icon(Icons.timer_rounded, color: Palette.coral, size: 16),
                  const SizedBox(width: 4),
                  Text('${spec.seconds}s',
                      style: const TextStyle(color: Palette.coral, fontSize: 12)),
                ],
              ],
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(stars > 0 ? 'Main Lagi' : 'Mulai'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  final List<Offset> centers;
  final int unlocked; // highest unlocked wave (1-based)
  _TrailPainter({required this.centers, required this.unlocked});

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;

    Path build(int from, int to) {
      final p = Path()..moveTo(centers[from].dx, centers[from].dy);
      for (var i = from; i < to; i++) {
        final a = centers[i], b = centers[i + 1];
        final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
        p.quadraticBezierTo(a.dx, mid.dy, mid.dx, mid.dy);
        p.quadraticBezierTo(b.dx, mid.dy, b.dx, b.dy);
      }
      return p;
    }

    // faint full trail
    canvas.drawPath(
      build(0, centers.length - 1),
      Paint()
        ..color = Palette.gold.withOpacity(0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    // lit portion up to the unlocked node
    final litTo = (unlocked - 1).clamp(0, centers.length - 1);
    if (litTo > 0) {
      canvas.drawPath(
        build(0, litTo),
        Paint()
          ..color = Palette.gold.withOpacity(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawPath(
        build(0, litTo),
        Paint()
          ..color = Palette.goldLt
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPainter old) =>
      old.unlocked != unlocked || old.centers.length != centers.length;
}
