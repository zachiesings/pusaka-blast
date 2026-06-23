import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../core/constants.dart';

/// A living in-game backdrop for Pusaka Blast — a NEON GRID arcade scene:
/// a synthwave perspective grid marching toward a glowing horizon, drifting
/// neon star particles and soft cyan/magenta glow orbs. Self-animated via a
/// [Ticker]; cheap enough to sit behind the board every frame.
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
    final horizon = h * 0.46;

    // 1) deep void gradient
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.bg0, Palette.bg1, Color(0xFF0A0A16)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & size),
    );

    // 2) soft cyan/magenta sky glow + glowing horizon line
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, horizon),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.coral.withOpacity(0.05), Palette.gold.withOpacity(0.10)],
        ).createShader(Rect.fromLTWH(0, 0, w, horizon)),
    );
    canvas.drawLine(
      Offset(0, horizon),
      Offset(w, horizon),
      Paint()
        ..color = Palette.gold.withOpacity(0.55)
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 3) synthwave perspective grid below the horizon
    final cx = w * 0.5;
    final grid = Paint()
      ..color = Palette.gold.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (var i = -6; i <= 6; i++) {
      final bx = cx + i * (w * 0.16);
      canvas.drawLine(Offset(cx + i * (w * 0.02), horizon), Offset(bx, h), grid);
    }
    for (var i = 0; i < 12; i++) {
      final p = ((t * 0.15 + i / 12.0) % 1.0);
      final y = horizon + (h - horizon) * (p * p); // ease → perspective
      canvas.drawLine(
        Offset(0, y),
        Offset(w, y),
        Paint()
          ..color = Palette.gold.withOpacity(0.06 + 0.16 * p)
          ..strokeWidth = 1.1,
      );
    }

    // 4) drifting neon star particles in the sky
    for (var i = 0; i < 26; i++) {
      final seed = i * 0.618;
      final x = w * ((seed + 0.04 * math.sin(t * 0.5 + i)) % 1.0);
      final y = horizon * ((seed * 1.7) % 1.0);
      final tw = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(t * 2 + i));
      final c = (i % 3 == 0) ? Palette.coral : (i % 3 == 1) ? Palette.gold : Palette.jade;
      canvas.drawCircle(
        Offset(x, y),
        1.0 + (i % 3) * 0.7,
        Paint()
          ..color = c.withOpacity(0.5 * tw)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    // 5) two soft neon glow orbs drifting
    _orb(canvas, Offset(w * (0.25 + 0.05 * math.sin(t * 0.3)), horizon * 0.5), w * 0.5, Palette.gold);
    _orb(canvas, Offset(w * (0.78 + 0.05 * math.cos(t * 0.27)), horizon * 0.35), w * 0.42, Palette.coral);
  }

  void _orb(Canvas canvas, Offset c, double r, Color col) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [col.withOpacity(0.10), col.withOpacity(0.0)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter old) => old.t != t;
}
