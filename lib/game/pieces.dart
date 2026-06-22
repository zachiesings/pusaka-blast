import 'dart:math';
import 'models/cell.dart';
import 'models/block_piece.dart';
import 'core_colors.dart';

/// Catalog of polyomino shapes (Block-Blast style). Each shape is a list of
/// (col,row) pairs, already normalised to a (0,0) top-left bounding box.
/// Rotation variants are listed explicitly because pieces don't rotate at play.
class PieceCatalog {
  PieceCatalog._();

  static const List<List<List<int>>> _shapes = <List<List<int>>>[
    // 1x1
    [ [0,0] ],
    // dominoes
    [ [0,0],[1,0] ],
    [ [0,0],[0,1] ],
    // trominoes — line
    [ [0,0],[1,0],[2,0] ],
    [ [0,0],[0,1],[0,2] ],
    // trominoes — L corners (4 rotations)
    [ [0,0],[1,0],[0,1] ],
    [ [0,0],[1,0],[1,1] ],
    [ [1,0],[0,1],[1,1] ],
    [ [0,0],[0,1],[1,1] ],
    // 2x2 square
    [ [0,0],[1,0],[0,1],[1,1] ],
    // tetromino — I
    [ [0,0],[1,0],[2,0],[3,0] ],
    [ [0,0],[0,1],[0,2],[0,3] ],
    // tetromino — L / J (4 useful rotations)
    [ [0,0],[0,1],[0,2],[1,2] ],
    [ [0,0],[1,0],[2,0],[0,1] ],
    [ [0,0],[1,0],[1,1],[1,2] ],
    [ [2,0],[0,1],[1,1],[2,1] ],
    // tetromino — T
    [ [0,0],[1,0],[2,0],[1,1] ],
    [ [1,0],[0,1],[1,1],[1,2] ],
    // tetromino — S / Z
    [ [1,0],[2,0],[0,1],[1,1] ],
    [ [0,0],[1,0],[1,1],[2,1] ],
    // pentomino lines
    [ [0,0],[1,0],[2,0],[3,0],[4,0] ],
    [ [0,0],[0,1],[0,2],[0,3],[0,4] ],
    // 3x3 square (the board-pressure piece)
    [ [0,0],[1,0],[2,0],[0,1],[1,1],[2,1],[0,2],[1,2],[2,2] ],
    // plus
    [ [1,0],[0,1],[1,1],[2,1],[1,2] ],
    // big L corner (5 cells)
    [ [0,0],[0,1],[0,2],[1,2],[2,2] ],
    [ [0,0],[1,0],[2,0],[2,1],[2,2] ],
  ];

  /// Relative spawn weights — smaller pieces appear more often so the board
  /// stays playable; the 3x3 and pentominoes are rare pressure pieces.
  static const List<int> _weights = <int>[
    2,                 // 1x1
    4,4,               // dominoes
    4,4,               // tromino lines
    4,4,4,4,           // tromino corners
    4,                 // 2x2
    3,3,               // I tetromino
    3,3,3,3,           // L/J
    3,3,               // T
    3,3,               // S/Z
    1,1,               // pentomino lines
    1,                 // 3x3
    2,                 // plus
    2,2,               // big L corners
  ];

  static BlockPiece buildPiece(int shapeId, {required Random rng}) {
    final raw = _shapes[shapeId];
    final cells = raw.map((p) => Cell(p[0], p[1])).toList(growable: false);
    final color = CoreColors.blockColors[rng.nextInt(CoreColors.blockColors.length)];
    return BlockPiece(shapeId: shapeId, cells: cells, color: color);
  }

  /// Weighted-random shape id.
  static int _pickShape(Random rng) {
    final total = _weights.fold<int>(0, (a, b) => a + b);
    var r = rng.nextInt(total);
    for (var i = 0; i < _weights.length; i++) {
      r -= _weights[i];
      if (r < 0) return i;
    }
    return 0;
  }

  /// Generate [count] fresh pieces for the tray.
  static List<BlockPiece> generateTray(int count, Random rng) =>
      List<BlockPiece>.generate(count, (_) => buildPiece(_pickShape(rng), rng: rng));
}
