import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Shared block-tile painter — matte carved-wood tile with a bevel + a small
/// kawung batik stamp + gold rim. (Distinct from Tiles' glassy glowing tiles.)
class BatikTile {
  BatikTile._();

  static void paint(Canvas canvas, Rect rect, Color color, {double opacity = 1}) {
    final r = rect.deflate(rect.width * 0.06);
    final radius = Radius.circular(rect.width * 0.22);
    final rr = RRect.fromRectAndRadius(r, radius);
    canvas.drawRRect(rr.shift(const Offset(0, 2)),
        Paint()..color = Colors.black.withOpacity(0.28 * opacity));
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, 0.16)!, color, Color.lerp(color, Colors.black, 0.12)!],
        ).createShader(r),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.4), radius),
      Paint()..color = Colors.white.withOpacity(0.14 * opacity),
    );
    final cx = r.center.dx, cy = r.center.dy, s = r.width * 0.24;
    final motif = Paint()
      ..color = Palette.cream.withOpacity(0.22 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r.width * 0.04;
    canvas.drawPath(
      Path()..moveTo(cx, cy - s)..lineTo(cx + s, cy)..lineTo(cx, cy + s)..lineTo(cx - s, cy)..close(),
      motif,
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..color = Palette.goldSoft.withOpacity(0.45 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = rect.width * 0.025,
    );
  }
}

/// PENDOPO EMAS background — warm wood-panel + a carved gold ornamental frame
/// with corner flourishes + a soft warm vignette. Deliberately NOT the drifting
/// glow-blob look; this is a regal, tactile, framed identity unique to Blast.
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

/// Faint warm wood grain — gentle horizontal flowing lines.
class _WoodPainter extends CustomPainter {
  const _WoodPainter();
  @override
  void paint(Canvas c, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Palette.goldSoft.withOpacity(0.04);
    const gap = 26.0;
    for (double y = 0; y < size.height; y += gap) {
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 22) {
        path.quadraticBezierTo(x + 11, y + math.sin(x / 90 + y) * 3.5, x + 22, y);
      }
      c.drawPath(path, p);
    }
    // soft vignette
    c.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 1.1,
          colors: [Colors.transparent, Palette.bg0.withOpacity(0.55)],
          stops: const [0.6, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _WoodPainter old) => false;
}

/// A carved gold ornamental frame with kawung corner flourishes; gently glints.
class _OrnamentFrame extends CustomPainter {
  final double t; // 0..1 shimmer
  _OrnamentFrame(this.t);

  @override
  void paint(Canvas c, Size size) {
    final glint = 0.5 + t * 0.5;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Palette.gold.withOpacity(0.32 * glint);
    final inset = 14.0;
    final rect = Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2);
    c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(26)), line);
    c.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(5), const Radius.circular(22)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Palette.gold.withOpacity(0.16 * glint),
    );
    // corner kawung flourishes
    final fill = Paint()..color = Palette.gold.withOpacity(0.5 * glint);
    final fillF = Paint()..color = Palette.gold.withOpacity(0.18 * glint);
    for (final corner in [
      rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight,
    ]) {
      _flourish(c, corner, fill, fillF);
    }
  }

  void _flourish(Canvas c, Offset o, Paint fill, Paint fillF) {
    c.drawCircle(o, 3.2, fill);
    for (var k = 0; k < 4; k++) {
      final ang = math.pi / 4 + k * math.pi / 2;
      final p = o + Offset(math.cos(ang), math.sin(ang)) * 12;
      c.save();
      c.translate(p.dx, p.dy);
      c.rotate(ang);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: 16, height: 7), fillF);
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _OrnamentFrame old) => old.t != t;
}
