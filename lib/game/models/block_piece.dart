import 'package:flutter/material.dart';
import 'cell.dart';

/// An immutable polyomino piece. [cells] are normalised so the bounding box's
/// top-left corner is (0,0). A piece never rotates at runtime (classic Block
/// Blast) — rotation variants are separate catalog entries instead.
@immutable
class BlockPiece {
  final int shapeId;          // index into the shape catalog (for analytics)
  final List<Cell> cells;     // occupied local coordinates
  final Color color;

  const BlockPiece({
    required this.shapeId,
    required this.cells,
    required this.color,
  });

  int get size => cells.length;

  int get width {
    var max = 0;
    for (final c in cells) {
      if (c.col > max) max = c.col;
    }
    return max + 1;
  }

  int get height {
    var max = 0;
    for (final c in cells) {
      if (c.row > max) max = c.row;
    }
    return max + 1;
  }

  BlockPiece withColor(Color c) =>
      BlockPiece(shapeId: shapeId, cells: cells, color: c);
}
