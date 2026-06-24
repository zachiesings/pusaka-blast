import 'package:flutter/material.dart';
import 'constants.dart';
import 'motion.dart';

/// Premium "Pusaka Keraton" theme — Plus Jakarta Sans + warm batik/sogan tokens.
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
    textTheme: base.textTheme
        .apply(fontFamily: font, bodyColor: Palette.cream, displayColor: Palette.cream)
        .copyWith(
          headlineLarge: Typo.h1.copyWith(color: Palette.cream),
          headlineMedium: Typo.h1.copyWith(color: Palette.cream, fontSize: 20),
          titleLarge: Typo.h1.copyWith(color: Palette.cream, fontSize: 18),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: Palette.cream,
      titleTextStyle: TextStyle(
          fontFamily: 'Cinzel', fontWeight: FontWeight.w700, fontSize: 19,
          letterSpacing: 1.5, color: Palette.cream),
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
