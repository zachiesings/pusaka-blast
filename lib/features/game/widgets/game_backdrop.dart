import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../core/constants.dart';

/// A living in-game backdrop for Pusaka Blast — a Javanese pendopo at night:
/// drifting kawung batik motifs, a swaying wayang *gunungan* silhouette, rising
/// gold embers and soft pendopo light. Self-animated via a [Ticker]; cheap
/// enough to sit behind the board every frame.
class GameBackdrop extends StatefulWidget {
  const GameBackdrop({super.key});

  @override
  State<GameBackdrop> createState() => _GameBackdropState();
}

class _GameBackdropState extends State<GameBackdrop> {
  Ticker? _ticker;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Ticker((d) {
      setState(() => _t = d.inMicroseconds / 1e6);
    })..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(painter: _BackdropPainter(_t), size: Size.infinite),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  final double t;
  _BackdropPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // 1) warm night gradient
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.bg0, Palette.bg1, Color(0xFF120A04)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & size),
    );

    // 2) soft pendopo light rays from the top
    for (var i = 0; i < 4; i++) {
      final cx = w * (0.2 + 0.2 * i);
      final sway = math.sin(t * 0.4 + i) * w * 0.04;
      final path = Path()
        ..moveTo(cx, -10)
        ..lineTo(cx - w * 0.12 + sway, h * 0.75)
        ..lineTo(cx + w * 0.12 + sway, h * 0.75)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Palette.gold.withOpacity(0.05), Palette.gold.withOpacity(0.0)],
          ).createShader(Rect.fromLTWH(0, 0, w, h)),
      );
    }

    // 3) drifting kawung batik motifs (parallax, wrap)
    final motif = Paint()
      ..color = Palette.gold.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var i = 0; i < 5; i++) {
      final r = w * (0.16 + 0.05 * (i % 3));
      final speed = 8 + i * 3.0;
      final x = (w * 0.5 + i * 137.0 + t * speed) % (w + 2 * r) - r;
      final y = (h * (0.18 + 0.16 * i) + math.sin(t * 0.3 + i) * 12);
      _kawung(canvas, Offset(x, y), r, motif);
    }

    // 4) swaying gunungan (wayang mountain) silhouette at bottom-centre
    canvas.save();
    canvas.translate(w * 0.5, h);
    canvas.rotate(math.sin(t * 0.5) * 0.03);
    _gunungan(canvas, w * 0.34, h * 0.5);
    canvas.restore();

    // 5) rising gold embers
    final ember = Paint()..color = Palette.goldLt;
    for (var i = 0; i < 20; i++) {
      final seed = i * 0.618;
      final speed = 14 + (i % 5) * 6.0;
      final y = h - ((t * speed + i * 90.0) % (h + 40)) + 20;
      final x = w * ((seed + 0.12 * math.sin(t * 0.6 + i)) % 1.0);
      final tw = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(t * 2 + i));
      canvas.drawCircle(Offset(x, y), 1.4 + (i % 3) * 0.5,
          ember..color = Palette.goldLt.withOpacity(0.35 * tw));
    }
  }

  void _kawung(Canvas canvas, Offset c, double r, Paint p) {
    // four-petal kawung rosette
    for (final a in [0, 1, 2, 3]) {
      final ang = a * math.pi / 2;
      final oc = c + Offset(math.cos(ang), math.sin(ang)) * r * 0.5;
      canvas.drawOval(
        Rect.fromCenter(center: oc, width: r * 0.7, height: r * 1.1)
            .shift(Offset.zero),
        p,
      );
    }
    canvas.drawCircle(c, r * 0.18, p);
  }

  void _gunungan(Canvas canvas, double bw, double bh) {
    // leaf-shaped wayang mountain, pointing up, dark with a faint gold edge
    final path = Path()
      ..moveTo(0, -bh)
      ..cubicTo(bw * 0.9, -bh * 0.7, bw * 0.7, -bh * 0.15, bw * 0.5, 0)
      ..lineTo(-bw * 0.5, 0)
      ..cubicTo(-bw * 0.7, -bh * 0.15, -bw * 0.9, -bh * 0.7, 0, -bh)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF0E0803).withOpacity(0.85));
    canvas.drawPath(
      path,
      Paint()
        ..color = Palette.gold.withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    // a few inner ornament lines
    final orn = Paint()
      ..color = Palette.gold.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (var k = 1; k <= 3; k++) {
      canvas.drawCircle(Offset(0, -bh * 0.45), bw * 0.12 * k, orn);
    }
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter old) => old.t != t;
}
