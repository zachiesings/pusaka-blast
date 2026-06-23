import 'package:flutter/material.dart';

/// Batik-inspired block colors, kept in the game layer so piece generation has
/// no dependency on the UI/theme layer. Mirrors `Palette.blockColors`.
class CoreColors {
  CoreColors._();

  static const List<Color> blockColors = <Color>[
    Color(0xFF1FE3FF), // cyan
    Color(0xFFFF3DAE), // magenta
    Color(0xFF9DFF3D), // lime
    Color(0xFFB14DFF), // violet
    Color(0xFFFFD23D), // electric yellow
    Color(0xFFFF6B35), // neon orange
    Color(0xFF3D8BFF), // electric blue
  ];

  /// The palette currently in use (set from the selected batik skin). Defaults
  /// to the classic colors; updated by AppState when a skin is chosen.
  static List<Color> active = blockColors;
}
