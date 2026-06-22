import 'package:flutter/material.dart';
import '../../../game/models/block_piece.dart';
import '../../../widgets/batik.dart';

/// Renders a [BlockPiece] at a fixed [cell] size (used in the tray and as drag
/// feedback). Sized to the piece's bounding box.
class PieceWidget extends StatelessWidget {
  final BlockPiece piece;
  final double cell;
  final double opacity;
  const PieceWidget({
    super.key,
    required this.piece,
    required this.cell,
    this.opacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: piece.width * cell,
      height: piece.height * cell,
      child: CustomPaint(painter: _PiecePainter(piece, opacity)),
    );
  }
}

class _PiecePainter extends CustomPainter {
  final BlockPiece piece;
  final double opacity;
  _PiecePainter(this.piece, this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / piece.width;
    for (final c in piece.cells) {
      final rect = Rect.fromLTWH(c.col * cell, c.row * cell, cell, cell);
      BatikTile.paint(canvas, rect, piece.color, opacity: opacity);
    }
  }

  @override
  bool shouldRepaint(covariant _PiecePainter old) =>
      old.piece != piece || old.opacity != opacity;
}
