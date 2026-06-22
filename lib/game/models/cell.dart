import 'package:flutter/foundation.dart';

/// Integer board coordinate. `col` = x (0..gridSize-1), `row` = y.
@immutable
class Cell {
  final int col;
  final int row;
  const Cell(this.col, this.row);

  Cell shift(int dc, int dr) => Cell(col + dc, row + dr);

  @override
  bool operator ==(Object other) =>
      other is Cell && other.col == col && other.row == row;

  @override
  int get hashCode => col * 31 + row;

  @override
  String toString() => '($col,$row)';
}
