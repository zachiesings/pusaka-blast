import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../game/engine/block_engine.dart';
import '../../../game/models/block_piece.dart';
import '../../../widgets/batik.dart';

/// Draws the 8x8 board: empty cells, placed tiles, and a live "ghost" preview of
/// the piece currently being dragged (green-tinted if it fits, red if not).
class BoardPainter extends CustomPainter {
  final BlockEngine engine;
  final BlockPiece? ghostPiece;
  final int ghostCol;
  final int ghostRow;
  final bool ghostValid;
  final int repaintTick; // bumped to force repaint on state change

  BoardPainter({
    required this.engine,
    required this.ghostPiece,
    required this.ghostCol,
    required this.ghostRow,
    required this.ghostValid,
    required this.repaintTick,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = engine.size;
    final cell = size.width / n;

    // Board backing panel
    final panel = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(cell * 0.25),
    );
    canvas.drawRRect(panel, Paint()..color = Palette.panel);

    // Empty cells
    final empty = Paint()..color = Palette.gridCell;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final rect = Rect.fromLTWH(c * cell, r * cell, cell, cell).deflate(cell * 0.06);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.16)),
          empty,
        );
      }
    }

    // Placed tiles
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final color = engine.cellColor(c, r);
        if (color != null) {
          BatikTile.paint(canvas, Rect.fromLTWH(c * cell, r * cell, cell, cell), color);
        }
      }
    }

    // Ghost preview
    final gp = ghostPiece;
    if (gp != null) {
      final tint = ghostValid ? Palette.gold : Colors.redAccent;
      for (final cc in gp.cells) {
        final bc = ghostCol + cc.col, br = ghostRow + cc.row;
        if (bc < 0 || bc >= n || br < 0 || br >= n) continue;
        final rect = Rect.fromLTWH(bc * cell, br * cell, cell, cell).deflate(cell * 0.08);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.16)),
          Paint()..color = tint.withOpacity(0.32),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.16)),
          Paint()
            ..color = tint.withOpacity(0.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.04,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) =>
      old.repaintTick != repaintTick ||
      old.ghostPiece != ghostPiece ||
      old.ghostCol != ghostCol ||
      old.ghostRow != ghostRow ||
      old.ghostValid != ghostValid;
}
