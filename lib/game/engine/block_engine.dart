import 'package:flutter/material.dart';
import '../models/cell.dart';
import '../models/block_piece.dart';

/// Result of attempting to place a piece on the board.
class PlaceResult {
  final bool placed;
  final int linesCleared;      // rows + cols cleared this move
  final int gained;            // score added by this move (placement + clears)
  final List<Cell> filledCells;   // cells the piece occupied (for pop-in FX)
  final List<Cell> clearedCells;  // cells removed by line clears (for clear FX)

  const PlaceResult({
    required this.placed,
    this.linesCleared = 0,
    this.gained = 0,
    this.filledCells = const [],
    this.clearedCells = const [],
  });

  static const PlaceResult invalid = PlaceResult(placed: false);
}

/// Pure board logic for the 8x8 Block-Blast grid. Holds only the grid of colors
/// (null = empty); scoring/combo state lives in the controller so this class is
/// trivially testable.
class BlockEngine {
  final int size;
  late List<List<Color?>> _grid;

  BlockEngine({this.size = 8}) {
    reset();
  }

  void reset() {
    _grid = List.generate(size, (_) => List<Color?>.filled(size, null));
  }

  Color? cellColor(int col, int row) => _grid[row][col];
  bool isFilled(int col, int row) => _grid[row][col] != null;

  /// Snapshot for persistence/restore (row-major color ints, -1 empty).
  List<int> serialize() {
    final out = <int>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        out.add(_grid[r][c]?.value ?? -1);
      }
    }
    return out;
  }

  void deserialize(List<int> data) {
    if (data.length != size * size) return;
    var i = 0;
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final v = data[i++];
        _grid[r][c] = v < 0 ? null : Color(v);
      }
    }
  }

  /// Can [piece] be placed with its (0,0) cell at board (col,row)?
  bool canPlace(BlockPiece piece, int col, int row) {
    for (final c in piece.cells) {
      final bc = col + c.col, br = row + c.row;
      if (bc < 0 || bc >= size || br < 0 || br >= size) return false;
      if (_grid[br][bc] != null) return false;
    }
    return true;
  }

  /// Is there ANY board position where [piece] fits? (game-over detection)
  bool hasAnyPlacement(BlockPiece piece) {
    for (var r = 0; r <= size - piece.height; r++) {
      for (var c = 0; c <= size - piece.width; c++) {
        if (canPlace(piece, c, r)) return true;
      }
    }
    return false;
  }

  /// Place [piece] (caller must have checked [canPlace]) and resolve any full
  /// rows/columns. [comboMultiplier] scales the clear bonus.
  PlaceResult place(BlockPiece piece, int col, int row, {int comboMultiplier = 1}) {
    if (!canPlace(piece, col, row)) return PlaceResult.invalid;

    final filled = <Cell>[];
    for (final c in piece.cells) {
      final bc = col + c.col, br = row + c.row;
      _grid[br][bc] = piece.color;
      filled.add(Cell(bc, br));
    }

    // Detect full rows and columns BEFORE mutating, so simultaneous clears count.
    final fullRows = <int>[];
    for (var r = 0; r < size; r++) {
      if (List.generate(size, (c) => _grid[r][c] != null).every((x) => x)) {
        fullRows.add(r);
      }
    }
    final fullCols = <int>[];
    for (var c = 0; c < size; c++) {
      if (List.generate(size, (r) => _grid[r][c] != null).every((x) => x)) {
        fullCols.add(c);
      }
    }

    final cleared = <Cell>{};
    for (final r in fullRows) {
      for (var c = 0; c < size; c++) {
        cleared.add(Cell(c, r));
      }
    }
    for (final c in fullCols) {
      for (var r = 0; r < size; r++) {
        cleared.add(Cell(c, r));
      }
    }
    for (final cell in cleared) {
      _grid[cell.row][cell.col] = null;
    }

    final lines = fullRows.length + fullCols.length;
    // Scoring: +1 per placed cell, +10 per cleared line, escalating bonus for
    // multi-line clears, all scaled by the current combo multiplier.
    final placeScore = piece.size;
    final clearScore = lines == 0 ? 0 : (10 * lines + 10 * lines * (lines - 1)) * comboMultiplier;

    return PlaceResult(
      placed: true,
      linesCleared: lines,
      gained: placeScore + clearScore,
      filledCells: filled,
      clearedCells: cleared.toList(growable: false),
    );
  }
}
