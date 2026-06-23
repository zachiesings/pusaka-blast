import 'package:flutter/material.dart';
import 'constants.dart';
import 'motion.dart';

/// Premium "Neon Grid" theme — Plus Jakarta Sans + dark cyber-arcade tokens.
ThemeData buildTheme() {
  const font = 'Jakarta';
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: Palette.bg0,
    pageTransitionsTheme: pendopoPageTransitionsTheme,
    colorScheme: base.colorScheme.copyWith(
      primary: Palette.gold,
      secondary: Palette.coral,
      surface: Palette.panel,
      onPrimary: Palette.ink,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: font,
      bodyColor: Palette.cream,
      displayColor: Palette.cream,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: Palette.cream,
      titleTextStyle: TextStyle(
          fontFamily: 'Jakarta', fontWeight: FontWeight.w800, fontSize: 18,
          letterSpacing: 2, color: Palette.cream),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Palette.gold,
        foregroundColor: Palette.ink,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(fontFamily: font, fontWeight: FontWeight.w800, fontSize: 16),
      ),
    ),
  );
}
