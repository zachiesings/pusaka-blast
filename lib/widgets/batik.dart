import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Shared tile painter — used by the board, tray and drag-feedback so every
/// block looks identical. A bevel + a procedural batik "kawung" motif. No images.
class BatikTile {
  BatikTile._();

  static void paint(Canvas canvas, Rect rect, Color color, {double opacity = 1}) {
    final r = rect.deflate(rect.width * 0.06);
    final radius = Radius.circular(rect.width * 0.22);
    final rr = RRect.fromRectAndRadius(r, radius);

    // soft drop for depth
    canvas.drawRRect(rr.shift(const Offset(0, 2)),
        Paint()..color = Colors.black.withOpacity(0.25 * opacity));
    // body with a subtle vertical gradient
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, 0.18)!, color],
        ).createShader(r),
    );
    // top gloss
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.4), radius),
      Paint()..color = Colors.white.withOpacity(0.16 * opacity),
    );
    // kawung motif
    final cx = r.center.dx, cy = r.center.dy, s = r.width * 0.26;
    final motif = Paint()
      ..color = Palette.cream.withOpacity(0.26 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r.width * 0.045;
    final path = Path()
      ..moveTo(cx, cy - s)
      ..lineTo(cx + s, cy)
      ..lineTo(cx, cy + s)
      ..lineTo(cx - s, cy)
      ..close();
    canvas.drawPath(path, motif);
    canvas.drawCircle(Offset(cx, cy), r.width * 0.06,
        Paint()..color = Palette.cream.withOpacity(0.3 * opacity));
    // gold rim
    canvas.drawRRect(
      rr,
      Paint()
        ..color = Palette.goldSoft.withOpacity(0.4 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = rect.width * 0.025,
    );
  }
}

/// Premium living background: warm batik-night gradient + drifting gold glows +
/// a cached, detailed KAWUNG batik motif (Pusaka Blast identity). Mirrors the
/// Beat Nusantara quality bar. Same name so every screen gets it for free.
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
      AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.bg1, Palette.bg0],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) => CustomPaint(painter: _GlowPainter(_c.value)),
              ),
            ),
          ),
          const Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _KawungPainter()))),
          if (widget.dim) const Positioned.fill(child: ColoredBox(color: Color(0x66000000))),
          widget.child,
        ],
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final double t;
  _GlowPainter(this.t);

  static const _blobs = [
    (Palette.gold, 0.16, 0.10, 360.0, 0.0),
    (Palette.maroon, 0.90, 0.85, 380.0, 0.5),
    (Palette.coral, 0.92, 0.16, 300.0, 0.25),
    (Palette.jade, 0.08, 0.74, 280.0, 0.75),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in _blobs) {
      final phase = (t + b.$5) * 2 * math.pi;
      final cx = b.$2 * size.width + math.sin(phase) * 26;
      final cy = b.$3 * size.height + math.cos(phase) * 26;
      final r = b.$4;
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..shader = RadialGradient(colors: [b.$1.withOpacity(0.22), b.$1.withOpacity(0.0)])
              .createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
      );
    }
    // drifting gold specks
    final spark = Paint();
    for (var i = 0; i < 12; i++) {
      final seed = i * 0.137;
      final x = ((seed + 0.05) % 1.0) * size.width;
      final prog = (t * (0.4 + seed) + seed) % 1.0;
      final y = size.height * (1.05 - prog);
      final a = math.sin(prog * math.pi) * 0.22;
      spark.color = (i.isEven ? Palette.gold : Palette.goldLt).withOpacity(a);
      canvas.drawCircle(Offset(x, y), 1.6 + (i % 3), spark);
    }
  }

  @override
  bool shouldRepaint(covariant _GlowPainter old) => old.t != t;
}

/// Detailed KAWUNG motif — four petals in a ring + center jewel + isen dots.
class _KawungPainter extends CustomPainter {
  const _KawungPainter();

  @override
  void paint(Canvas c, Size size) {
    final petal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Palette.gold.withOpacity(0.085);
    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = Palette.gold.withOpacity(0.05);
    final jewel = Paint()..color = Palette.gold.withOpacity(0.08);
    const gap = 66.0, r = gap * 0.5;
    for (double y = -gap; y < size.height + gap; y += gap) {
      for (double x = -gap; x < size.width + gap; x += gap) {
        final center = Offset(x + gap / 2, y + gap / 2);
        c.drawCircle(center, r * 0.94, faint);
        for (var k = 0; k < 4; k++) {
          final ang = math.pi / 4 + k * math.pi / 2;
          final oc = center + Offset(math.cos(ang), math.sin(ang)) * (r * 0.46);
          c.save();
          c.translate(oc.dx, oc.dy);
          c.rotate(ang);
          c.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 1.02, height: r * 0.5), petal);
          c.restore();
        }
        c.drawCircle(center, 2.2, jewel);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KawungPainter old) => false;
}
