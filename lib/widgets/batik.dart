import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Shared block-tile painter — glossy NEON tile: a rounded glass block with a
/// bright top gloss and a glowing rim in its own colour. (Distinct from Tiles'
/// batik tiles.) Public API unchanged so all callers keep working.
class BatikTile {
  BatikTile._();

  static void paint(Canvas canvas, Rect rect, Color color, {double opacity = 1}) {
    final r = rect.deflate(rect.width * 0.06);
    final radius = Radius.circular(rect.width * 0.26);
    final rr = RRect.fromRectAndRadius(r, radius);

    // outer neon glow
    canvas.drawRRect(
      rr,
      Paint()
        ..color = color.withOpacity(0.45 * opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rect.width * 0.10),
    );
    // glass body — darker base so the neon rim reads as light
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, Colors.white, 0.30)!,
            color,
            Color.lerp(color, Colors.black, 0.45)!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(r),
    );
    // top gloss highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.42), radius),
      Paint()..color = Colors.white.withOpacity(0.22 * opacity),
    );
    // small inner core sheen
    canvas.drawCircle(
      Offset(r.center.dx, r.top + r.height * 0.30),
      r.width * 0.12,
      Paint()..color = Colors.white.withOpacity(0.18 * opacity),
    );
    // bright neon rim
    canvas.drawRRect(
      rr,
      Paint()
        ..color = Color.lerp(color, Colors.white, 0.35)!.withOpacity(0.9 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = rect.width * 0.04,
    );
  }
}

/// NEON GRID background — a dark void with a faint glowing grid + a soft neon
/// frame that gently shimmers. Deliberately NOT the batik wood-frame look; this
/// is the cyber-arcade identity unique to Blast's new design.
class BatikBackground extends StatefulWidget {
  final Widget child;
  final bool dim;
  const BatikBackground({super.key, required this.child, this.dim = false});

  @override
  State<BatikBackground> createState() => _BatikBackgroundState();
}

class _BatikBackgroundState extends State<BatikBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.2,
          colors: [Palette.bg1, Palette.bg0],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _WoodPainter()))),
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) => CustomPaint(painter: _OrnamentFrame(_c.value)),
              ),
            ),
          ),
          if (widget.dim) const Positioned.fill(child: ColoredBox(color: Color(0x66000000))),
          widget.child,
        ],
      ),
    );
  }
}

/// Faint glowing neon grid + vignette.
class _WoodPainter extends CustomPainter {
  const _WoodPainter();
  @override
  void paint(Canvas c, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Palette.gold.withOpacity(0.05);
    const gap = 34.0;
    for (double x = 0; x <= size.width; x += gap) {
      c.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += gap) {
      c.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    // soft vignette
    c.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 1.1,
          colors: [Colors.transparent, Palette.bg0.withOpacity(0.65)],
          stops: const [0.55, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _WoodPainter old) => false;
}

/// A glowing neon border frame with corner accents; gently pulses.
class _OrnamentFrame extends CustomPainter {
  final double t; // 0..1 shimmer
  _OrnamentFrame(this.t);

  @override
  void paint(Canvas c, Size size) {
    final glint = 0.5 + t * 0.5;
    final inset = 14.0;
    final rect = Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(24));
    // glow halo
    c.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Palette.gold.withOpacity(0.18 * glint)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // crisp neon line
    c.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Palette.gold.withOpacity(0.40 * glint),
    );
    // corner accent ticks (cyan + magenta)
    const len = 22.0;
    final corners = <List<Offset>>[
      [rect.topLeft + const Offset(0, len), rect.topLeft, rect.topLeft + const Offset(len, 0)],
      [rect.topRight + const Offset(0, len), rect.topRight, rect.topRight + const Offset(-len, 0)],
      [rect.bottomLeft + const Offset(0, -len), rect.bottomLeft, rect.bottomLeft + const Offset(len, 0)],
      [rect.bottomRight + const Offset(0, -len), rect.bottomRight, rect.bottomRight + const Offset(-len, 0)],
    ];
    final accent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = Palette.coral.withOpacity(0.7 * glint);
    for (final pts in corners) {
      c.drawPath(Path()..moveTo(pts[0].dx, pts[0].dy)..lineTo(pts[1].dx, pts[1].dy)..lineTo(pts[2].dx, pts[2].dy), accent);
    }
  }

  @override
  bool shouldRepaint(covariant _OrnamentFrame old) => old.t != t;
}
