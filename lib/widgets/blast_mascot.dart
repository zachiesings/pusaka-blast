import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'mascot.dart' show MascotMood; // reuse the mood enum

/// "Macan Batik" — Pusaka Blast's OWN mascot: a chubby, GROUNDED batik tiger cub
/// (warm sogan/amber fur, batik stripes, cream belly, little paws). Deliberately a
/// different silhouette + species from Pusaka Tiles' tall hovering dancer-spirit
/// and from the shared blangkon kid (Guideline 4.3 differentiation). Code-drawn.
class BlastMascot extends StatefulWidget {
  final MascotMood mood;
  final double size;
  const BlastMascot({super.key, this.mood = MascotMood.idle, this.size = 120});

  @override
  State<BlastMascot> createState() => _BlastMascotState();
}

class _BlastMascotState extends State<BlastMascot> with TickerProviderStateMixin {
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
  late final AnimationController _react =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 760));

  @override
  void didUpdateWidget(covariant BlastMascot old) {
    super.didUpdateWidget(old);
    if (widget.mood != old.mood && widget.mood != MascotMood.idle) _react.forward(from: 0);
  }

  @override
  void dispose() {
    _idle.dispose();
    _react.dispose();
    super.dispose();
  }

  double _blink(double t) {
    final d = (t - 0.5).abs();
    return d < 0.05 ? (d / 0.05) : 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_idle, _react]),
        builder: (_, __) => CustomPaint(
          painter: _MacanPainter(
            mood: widget.mood,
            breath: math.sin(2 * math.pi * _idle.value),
            blink: _blink(_idle.value),
            react: Curves.easeOutBack.transform(_react.value.clamp(0.0, 1.0)),
          ),
        ),
      ),
    );
  }
}

class _MacanPainter extends CustomPainter {
  final MascotMood mood;
  final double breath, blink, react;
  _MacanPainter({required this.mood, required this.breath, required this.blink, required this.react});

  static const _fur = Color(0xFFD98A3D);   // amber sogan fur
  static const _fur2 = Color(0xFFB5632A);  // deeper sogan
  static const _belly = Color(0xFFF4E8D2); // cream belly/muzzle
  static const _stripe = Color(0xFF3E211A);// dark batik stripe
  static const _nose = Color(0xFF8E3B2E);  // maroon nose
  static const _ear = Color(0xFFE8B98A);   // inner ear

  bool get _up => mood == MascotMood.cheer || mood == MascotMood.happy;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cx = size.width / 2;
    double dy = breath * s * 0.012;
    if (_up) dy -= math.sin(math.pi * react) * s * 0.10;
    if (mood == MascotMood.sad) dy += react * s * 0.04;
    canvas.save();
    canvas.translate(0, dy);

    // ground shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, s * 0.95 - dy * 0.4), width: s * 0.56, height: s * 0.1),
      Paint()..color = Colors.black.withOpacity(0.18),
    );

    // curling tail (with a stripe)
    final tail = Path()
      ..moveTo(cx + s * 0.20, s * 0.80)
      ..quadraticBezierTo(cx + s * 0.44, s * 0.78, cx + s * 0.40, s * 0.56)
      ..quadraticBezierTo(cx + s * 0.37, s * 0.66, cx + s * 0.24, s * 0.70);
    canvas.drawPath(
        tail,
        Paint()
          ..color = _fur2
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.09
          ..strokeCap = StrokeCap.round);

    // paws raise up on cheer/happy
    final pawUp = _up ? react : 0.0;

    // body (rounded, sitting)
    final bodyRect = Rect.fromCenter(center: Offset(cx, s * 0.72), width: s * 0.6, height: s * 0.46);
    final body = RRect.fromRectAndRadius(bodyRect, Radius.circular(s * 0.26));
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [_fur, _fur2],
        ).createShader(bodyRect),
    );
    // cream belly
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, s * 0.78), width: s * 0.3, height: s * 0.3),
      Paint()..color = _belly,
    );
    // body batik stripes
    final sp = Paint()
      ..color = _stripe
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.03
      ..strokeCap = StrokeCap.round;
    for (final o in [-0.18, 0.0, 0.18]) {
      canvas.drawArc(Rect.fromCenter(center: Offset(cx + s * o, s * 0.66), width: s * 0.14, height: s * 0.2),
          math.pi * 0.15, math.pi * 0.7, false, sp);
    }

    // front paws
    for (final d in [-1.0, 1.0]) {
      final px = cx + d * s * 0.16;
      final py = s * 0.9 - pawUp * s * 0.30;
      canvas.drawOval(Rect.fromCenter(center: Offset(px, py), width: s * 0.18, height: s * 0.14),
          Paint()..color = _fur);
      // toe lines
      for (final t in [-0.04, 0.0, 0.04]) {
        canvas.drawLine(Offset(px + s * t, py - s * 0.03), Offset(px + s * t, py + s * 0.03),
            Paint()..color = _stripe.withOpacity(0.6)..strokeWidth = s * 0.008);
      }
    }

    // head
    final headC = Offset(cx, s * 0.36);
    final headR = s * 0.27;
    // ears
    for (final d in [-1.0, 1.0]) {
      final ec = Offset(cx + d * headR * 0.72, headC.dy - headR * 0.66);
      canvas.drawCircle(ec, headR * 0.34, Paint()..color = _fur);
      canvas.drawCircle(ec, headR * 0.18, Paint()..color = _ear);
    }
    canvas.drawCircle(headC, headR, Paint()..color = _fur);
    // head stripes (batik) on the forehead
    for (final d in [-0.5, 0.0, 0.5]) {
      canvas.drawLine(
        Offset(cx + headR * d * 0.7, headC.dy - headR * 0.92),
        Offset(cx + headR * d * 0.45, headC.dy - headR * 0.5),
        sp,
      );
    }
    // cheeks / muzzle (cream)
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, headC.dy + headR * 0.4), width: headR * 1.2, height: headR * 0.95),
        Paint()..color = _belly);

    // eyes
    final eyeY = headC.dy + headR * 0.02;
    final eyeDx = headR * 0.42;
    final ink = Paint()..color = const Color(0xFF1B130A);
    if (_up) {
      final p = Paint()
        ..color = ink.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.02
        ..strokeCap = StrokeCap.round;
      for (final sx in [cx - eyeDx, cx + eyeDx]) {
        canvas.drawArc(Rect.fromCircle(center: Offset(sx, eyeY + headR * 0.04), radius: headR * 0.15),
            math.pi, math.pi, false, p);
      }
    } else {
      final eh = headR * 0.26 * blink + headR * 0.02;
      for (final sx in [cx - eyeDx, cx + eyeDx]) {
        canvas.drawOval(Rect.fromCenter(center: Offset(sx, eyeY), width: headR * 0.24, height: eh), ink);
      }
      if (mood == MascotMood.sad) {
        final brow = Paint()..color = ink.color..style = PaintingStyle.stroke..strokeWidth = s * 0.016..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(cx - eyeDx - headR * 0.12, eyeY - headR * 0.22),
            Offset(cx - eyeDx + headR * 0.1, eyeY - headR * 0.12), brow);
        canvas.drawLine(Offset(cx + eyeDx + headR * 0.12, eyeY - headR * 0.22),
            Offset(cx + eyeDx - headR * 0.1, eyeY - headR * 0.12), brow);
      }
    }

    // nose + mouth + whiskers
    final noseC = Offset(cx, headC.dy + headR * 0.34);
    canvas.drawPath(
      Path()
        ..moveTo(noseC.dx - headR * 0.12, noseC.dy)
        ..lineTo(noseC.dx + headR * 0.12, noseC.dy)
        ..lineTo(noseC.dx, noseC.dy + headR * 0.12)
        ..close(),
      Paint()..color = _nose,
    );
    final mouth = Paint()..color = ink.color..style = PaintingStyle.stroke..strokeWidth = s * 0.016..strokeCap = StrokeCap.round;
    final my = noseC.dy + headR * 0.2;
    if (mood == MascotMood.sad) {
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, my + headR * 0.14), radius: headR * 0.16),
          math.pi + 0.5, math.pi - 1.0, false, mouth);
    } else {
      canvas.drawArc(Rect.fromCircle(center: Offset(cx - headR * 0.12, my), radius: headR * 0.14), 0.2, math.pi - 0.4, false, mouth);
      canvas.drawArc(Rect.fromCircle(center: Offset(cx + headR * 0.12, my), radius: headR * 0.14), 0.2, math.pi - 0.4, false, mouth);
    }
    // whiskers
    final wp = Paint()..color = _belly.withOpacity(0.9)..strokeWidth = s * 0.008..strokeCap = StrokeCap.round;
    for (final d in [-1.0, 1.0]) {
      for (final yy in [-0.03, 0.02]) {
        canvas.drawLine(Offset(cx + d * headR * 0.3, noseC.dy + headR * yy),
            Offset(cx + d * headR * 0.95, noseC.dy + headR * (yy - 0.04)), wp);
      }
    }

    // sparkles on cheer
    if (mood == MascotMood.cheer && react > 0) {
      final spk = Paint()..color = Palette.gold.withOpacity((1 - react).clamp(0.0, 1.0));
      for (final a in [0.4, 1.5, 2.7, 3.9, 5.1]) {
        final rr = headR * (1.4 + react * 0.6);
        canvas.drawCircle(Offset(cx + math.cos(a) * rr, headC.dy + math.sin(a) * rr), s * 0.022, spk);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MacanPainter old) =>
      old.breath != breath || old.blink != blink || old.react != react || old.mood != mood;
}
