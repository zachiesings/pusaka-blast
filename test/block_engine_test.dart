import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusaka_blast/game/engine/block_engine.dart';
import 'package:pusaka_blast/game/models/block_piece.dart';
import 'package:pusaka_blast/game/models/cell.dart';

BlockPiece line(int len) => BlockPiece(
      shapeId: 0,
      color: const Color(0xFF7A3B2E),
      cells: List.generate(len, (i) => Cell(i, 0)),
    );

BlockPiece vline(int len) => BlockPiece(
      shapeId: 0,
      color: const Color(0xFF1F4E5F),
      cells: List.generate(len, (i) => Cell(0, i)),
    );

void main() {
  group('BlockEngine', () {
    test('placing a piece fills the right cells', () {
      final e = BlockEngine(size: 8);
      final r = e.place(line(3), 0, 0);
      expect(r.placed, true);
      expect(e.isFilled(0, 0), true);
      expect(e.isFilled(2, 0), true);
      expect(e.isFilled(3, 0), false);
      expect(r.gained, 3); // 3 cells, no clear
    });

    test('cannot place overlapping or out of bounds', () {
      final e = BlockEngine(size: 8);
      e.place(line(1), 0, 0);
      expect(e.canPlace(line(1), 0, 0), false); // occupied
      expect(e.canPlace(line(3), 6, 0), false); // would run off the right edge
      expect(e.canPlace(line(2), 6, 0), true);
    });

    test('filling a full row clears it', () {
      final e = BlockEngine(size: 8);
      // Fill columns 0..6, then drop the last cell to complete row 0.
      e.place(line(7), 0, 0);
      final r = e.place(line(1), 7, 0);
      expect(r.linesCleared, 1);
      for (var c = 0; c < 8; c++) {
        expect(e.isFilled(c, 0), false); // whole row cleared
      }
      expect(r.gained, greaterThan(1)); // placement + clear bonus
    });

    test('row + column clear simultaneously counts as 2 lines', () {
      final e = BlockEngine(size: 8);
      // Fill row 0 cols 1..7 and column 0 rows 1..7, then the corner (0,0)
      // completes both the row and the column at once.
      e.place(BlockPiece(shapeId: 0, color: const Color(0xFFB5832E),
          cells: List.generate(7, (i) => Cell(i + 1, 0))), 0, 0);
      e.place(BlockPiece(shapeId: 0, color: const Color(0xFFB5832E),
          cells: List.generate(7, (i) => Cell(0, i + 1))), 0, 0);
      final r = e.place(line(1), 0, 0);
      expect(r.linesCleared, 2);
    });

    test('hasAnyPlacement detects a full board as game over', () {
      final e = BlockEngine(size: 8);
      // Fill the entire board.
      for (var row = 0; row < 8; row++) {
        // place 8 singles per row without triggering clears by leaving via
        // direct fill — use a full-width line that clears, so instead fill
        // manually through serialize.
      }
      e.deserialize(List<int>.filled(64, 0xFF000000));
      expect(e.hasAnyPlacement(line(1)), false);
      expect(e.hasAnyPlacement(vline(2)), false);
    });
  });
}
