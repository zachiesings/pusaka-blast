import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../game/models/block_piece.dart';
import '../../../widgets/batik.dart';

/// Renders a [BlockPiece] at a fixed [cell] size (used in the tray and as drag
/// feedback). [glow] adds a lifted shadow + gold halo for drag feedback.
class PieceWidget extends StatelessWidget {
  final BlockPiece piece;
  final double cell;
  final double opacity;
  final bool glow;
  const PieceWidget({
    super.key,
    required this.piece,
    required this.cell,
    this.opacity = 1,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: piece.width * cell,
      height: piece.height * cell,
      child: CustomPaint(painter: _PiecePainter(piece, opacity, glow)),
    );
  }
}

class _PiecePainter extends CustomPainter {
  final BlockPiece piece;
  final double opacity;
  final bool glow;
  _PiecePainter(this.piece, this.opacity, this.glow);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / piece.width;
    if (glow) {
      // lifted drop-shadow + gold halo under the whole piece
      final shadow = Paint()
        ..color = Colors.black.withOpacity(0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.18);
      final halo = Paint()
        ..color = Palette.gold.withOpacity(0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.3);
      for (final c in piece.cells) {
        final rect = Rect.fromLTWH(c.col * cell, c.row * cell, cell, cell);
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect.shift(Offset(0, cell * 0.12)), Radius.circular(cell * 0.2)),
            shadow);
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect.inflate(cell * 0.04), Radius.circular(cell * 0.2)), halo);
      }
    }
    for (final c in piece.cells) {
      final rect = Rect.fromLTWH(c.col * cell, c.row * cell, cell, cell);
      BatikTile.paint(canvas, rect, piece.color, opacity: opacity);
    }
  }

  @override
  bool shouldRepaint(covariant _PiecePainter old) =>
      old.piece != piece || old.opacity != opacity || old.glow != glow;
}
