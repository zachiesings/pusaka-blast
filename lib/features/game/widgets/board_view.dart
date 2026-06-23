import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../game/engine/block_engine.dart';
import '../../../game/models/block_piece.dart';
import '../../../game/models/cell.dart';
import '../../../widgets/batik.dart';

/// Draws the 8x8 board: empty cells, placed tiles, and a live "ghost" preview of
/// the piece currently being dragged (green-tinted if it fits, red if not).
class BoardPainter extends CustomPainter {
  final BlockEngine engine;
  final BlockPiece? ghostPiece;
  final int ghostCol;
  final int ghostRow;
  final bool ghostValid;
  final List<Cell> previewClears; // cells that would clear at the ghost spot
  final int repaintTick; // bumped to force repaint on state change

  BoardPainter({
    required this.engine,
    required this.ghostPiece,
    required this.ghostCol,
    required this.ghostRow,
    required this.ghostValid,
    this.previewClears = const [],
    required this.repaintTick,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = engine.size;
    final cell = size.width / n;

    // Board backing panel — carved teak with a gradient + gold ornate frame
    final panel = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(cell * 0.25),
    );
    canvas.drawRRect(panel.inflate(cell * 0.18).shift(Offset(0, cell * 0.1)),
        Paint()..color = Colors.black.withOpacity(0.35));
    canvas.drawRRect(
      panel,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(Palette.panel, Palette.gold, 0.06)!, Palette.panel],
        ).createShader(Offset.zero & size),
    );
    // double gold frame
    canvas.drawRRect(
      panel.deflate(cell * 0.04),
      Paint()
        ..color = Palette.gold.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.05,
    );
    canvas.drawRRect(
      panel.deflate(cell * 0.13),
      Paint()
        ..color = Palette.gold.withOpacity(0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.02,
    );
    // corner flourishes
    final fl = Paint()
      ..color = Palette.gold.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.05
      ..strokeCap = StrokeCap.round;
    final m = cell * 0.32, len = cell * 0.5;
    for (final cn in [
      [Offset(m, m), const Offset(1, 0), const Offset(0, 1)],
      [Offset(size.width - m, m), const Offset(-1, 0), const Offset(0, 1)],
      [Offset(m, size.height - m), const Offset(1, 0), const Offset(0, -1)],
      [Offset(size.width - m, size.height - m), const Offset(-1, 0), const Offset(0, -1)],
    ]) {
      final p = cn[0] as Offset, dx = cn[1] as Offset, dy = cn[2] as Offset;
      canvas.drawLine(p, p + dx * len, fl);
      canvas.drawLine(p, p + dy * len, fl);
    }

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

    // Placed tiles (+ special Harta / Gembok overlays)
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final color = engine.cellColor(c, r);
        if (color != null) {
          final rect = Rect.fromLTWH(c * cell, r * cell, cell, cell);
          BatikTile.paint(canvas, rect, color);
          final k = engine.kindAt(c, r);
          if (k == CellKind.treasure) {
            _treasure(canvas, rect, cell);
          } else if (k == CellKind.locked) {
            _lock(canvas, rect, cell, cracked: false);
          } else if (k == CellKind.cracked) {
            _lock(canvas, rect, cell, cracked: true);
          }
        }
      }
    }

    // Would-be-clear preview: glow the rows/cols that this drop would clear.
    if (previewClears.isNotEmpty) {
      final glow = Paint()
        ..color = Palette.jade.withOpacity(0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      final outline = Paint()
        ..color = Palette.jade
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.06;
      for (final pc in previewClears) {
        final rect = Rect.fromLTWH(pc.col * cell, pc.row * cell, cell, cell).deflate(cell * 0.06);
        final rr = RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.16));
        canvas.drawRRect(rr, glow);
        canvas.drawRRect(rr, outline);
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

  /// Harta — a glinting gold gem set into the tile.
  void _treasure(Canvas canvas, Rect rect, double cell) {
    final c = rect.center;
    final s = cell * 0.26;
    // soft halo
    canvas.drawCircle(c, s * 1.5,
        Paint()..color = Palette.goldLt.withOpacity(0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    final gem = Path()
      ..moveTo(c.dx, c.dy - s)
      ..lineTo(c.dx + s * 0.8, c.dy - s * 0.2)
      ..lineTo(c.dx + s * 0.5, c.dy + s)
      ..lineTo(c.dx - s * 0.5, c.dy + s)
      ..lineTo(c.dx - s * 0.8, c.dy - s * 0.2)
      ..close();
    canvas.drawPath(
      gem,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF0BE), Palette.gold, Color(0xFFD98A2B)],
        ).createShader(rect),
    );
    canvas.drawPath(
        gem,
        Paint()
          ..color = const Color(0xFF7A4A12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.025);
    // facet highlight
    canvas.drawLine(Offset(c.dx, c.dy - s), Offset(c.dx - s * 0.3, c.dy + s * 0.2),
        Paint()..color = Colors.white.withOpacity(0.7)..strokeWidth = cell * 0.02);
  }

  /// Gembok — a forged lock; shows a crack once it has taken its first hit.
  void _lock(Canvas canvas, Rect rect, double cell, {required bool cracked}) {
    // darken the tile so locks read as heavy stone
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(cell * 0.06), Radius.circular(cell * 0.16)),
      Paint()..color = Colors.black.withOpacity(cracked ? 0.18 : 0.34),
    );
    final c = rect.center;
    final w = cell * 0.34, h = cell * 0.28;
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(c.dx, c.dy + h * 0.25), width: w, height: h),
      Radius.circular(cell * 0.06),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFFCBB37A));
    canvas.drawRRect(
        body,
        Paint()
          ..color = const Color(0xFF5A4636)
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.02);
    // shackle
    canvas.drawArc(
      Rect.fromCenter(center: Offset(c.dx, c.dy - h * 0.25), width: w * 0.7, height: h * 0.9),
      3.14, 3.14, false,
      Paint()
        ..color = const Color(0xFFCBB37A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.05
        ..strokeCap = StrokeCap.round,
    );
    // keyhole
    canvas.drawCircle(Offset(c.dx, c.dy + h * 0.2), cell * 0.03, Paint()..color = const Color(0xFF5A4636));
    if (cracked) {
      final p = Paint()
        ..color = Colors.white.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.03
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - w * 0.4, c.dy - h * 0.3)
          ..lineTo(c.dx - w * 0.05, c.dy + h * 0.05)
          ..lineTo(c.dx + w * 0.2, c.dy - h * 0.1)
          ..lineTo(c.dx + w * 0.45, c.dy + h * 0.3),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) =>
      old.repaintTick != repaintTick ||
      old.ghostPiece != ghostPiece ||
      old.ghostCol != ghostCol ||
      old.ghostRow != ghostRow ||
      old.ghostValid != ghostValid ||
      old.previewClears != previewClears;
}
