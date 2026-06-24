import 'package:flutter/material.dart';

/// Batik-inspired block colors, kept in the game layer so piece generation has
/// no dependency on the UI/theme layer. Mirrors `Palette.blockColors`.
class CoreColors {
  CoreColors._();

  static const List<Color> blockColors = <Color>[
    Color(0xFF9A4A36), // sogan terracotta
    Color(0xFF1F4E5F), // indigo wedelan
    Color(0xFFC2912F), // prada gold
    Color(0xFF4A6B3A), // daun olive
    Color(0xFF6E3B5C), // plum keraton
    Color(0xFF2E5E6E), // teal pesisir
    Color(0xFFB5632A), // amber sogan
  ];

  /// The palette currently in use (set from the selected batik skin). Defaults
  /// to the classic colors; updated by AppState when a skin is chosen.
  static List<Color> active = blockColors;
}
