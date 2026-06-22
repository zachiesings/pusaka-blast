import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../game/models/cell.dart';

/// A satisfying "snap-in" pop on the cells a piece just occupied: a quick bright
/// flash + an expanding gold ring per cell, over [t] (0 → 1). Drawn as a board
/// overlay so geometry matches.
class PlacePopPainter extends CustomPainter {
  final List<Cell> cells;
  final int gridSize;
  final double t;

  PlacePopPainter({required this.cells, required this.gridSize, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    if (cells.isEmpty || t >= 1) return;
    final cell = size.width / gridSize;
    final fade = (1 - t).clamp(0.0, 1.0);

    for (final c in cells) {
      final center = Offset((c.col + 0.5) * cell, (c.row + 0.5) * cell);
      // bright flash that shrinks slightly
      final fs = cell * (0.5 - t * 0.1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: fs * 2, height: fs * 2),
          Radius.circular(cell * 0.2),
        ),
        Paint()..color = Colors.white.withOpacity(0.5 * fade),
      );
      // expanding gold ring
      final ringR = cell * (0.35 + t * 0.5);
      canvas.drawCircle(
        center,
        ringR,
        Paint()
          ..color = Palette.goldLt.withOpacity(0.7 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.06 * fade,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PlacePopPainter old) => old.t != t || old.cells != cells;
}
