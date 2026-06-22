import 'package:flutter/material.dart';

/// Batik-inspired block colors, kept in the game layer so piece generation has
/// no dependency on the UI/theme layer. Mirrors `Palette.blockColors`.
class CoreColors {
  CoreColors._();

  static const List<Color> blockColors = <Color>[
    Color(0xFF7A3B2E), // bata — terracotta red
    Color(0xFF1F4E5F), // indigo nila
    Color(0xFFB5832E), // sogan kuning
    Color(0xFF4A6B3A), // daun — leaf green
    Color(0xFF6E3B5C), // anggur — plum
    Color(0xFF2E5E6E), // teal pesisir
    Color(0xFFA84B2A), // tembaga — copper
  ];
}
