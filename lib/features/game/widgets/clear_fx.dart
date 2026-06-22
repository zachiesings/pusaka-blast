import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../game/models/cell.dart';

/// Paints the line-clear flash: each cleared cell bursts with a gold glow that
/// scales up and fades out over [t] (0 → 1). Drawn as an overlay aligned to the
/// board so geometry matches exactly.
class ClearFxPainter extends CustomPainter {
  final List<Cell> cells;
  final int gridSize;
  final double t; // animation progress 0..1

  ClearFxPainter({required this.cells, required this.gridSize, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    if (cells.isEmpty || t >= 1) return;
    final cell = size.width / gridSize;
    final fade = (1 - t).clamp(0.0, 1.0);
    final grow = 1 + t * 0.5;

    for (final c in cells) {
      final center = Offset((c.col + 0.5) * cell, (c.row + 0.5) * cell);
      final s = cell * 0.5 * grow;
      final rect = Rect.fromCenter(center: center, width: s * 2, height: s * 2);
      // Outer gold glow
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.2)),
        Paint()
          ..color = Palette.gold.withOpacity(0.55 * fade)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.18),
      );
      // Bright core
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: cell * 0.7, height: cell * 0.7),
          Radius.circular(cell * 0.18),
        ),
        Paint()..color = Palette.cream.withOpacity(0.85 * fade),
      );
      // Expanding gold ring
      canvas.drawCircle(
        center,
        cell * (0.3 + t * 0.9),
        Paint()
          ..color = Palette.goldLt.withOpacity(0.6 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.07 * fade,
      );
      // Flying batik shards (diamonds) spinning outward
      final shard = Paint()..color = Palette.goldLt.withOpacity(0.9 * fade);
      for (var k = 0; k < 4; k++) {
        final ang = k * math.pi / 2 + t * 3 + (c.col + c.row);
        final dist = cell * (0.2 + t * 1.1);
        final p = center + Offset(math.cos(ang), math.sin(ang)) * dist;
        final sz = cell * 0.12 * fade;
        canvas.drawPath(
          Path()
            ..moveTo(p.dx, p.dy - sz)
            ..lineTo(p.dx + sz, p.dy)
            ..lineTo(p.dx, p.dy + sz)
            ..lineTo(p.dx - sz, p.dy)
            ..close(),
          shard,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ClearFxPainter old) =>
      old.t != t || old.cells != cells;
}
