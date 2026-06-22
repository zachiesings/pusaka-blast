import 'package:flutter/material.dart';
import '../state/app_state.dart';

/// An achievement whose status is derived live from persisted stats (no extra
/// state to keep in sync). [met] reads AppState.
class Achievement {
  final String title;
  final String desc;
  final IconData icon;
  final bool Function(AppState) met;
  const Achievement(this.title, this.desc, this.icon, this.met);
}

const List<Achievement> kAchievements = [
  Achievement('Langkah Pertama', 'Capai skor 100', Icons.flag_rounded,
      _s100),
  Achievement('Penyusun Ulung', 'Capai skor 1.000', Icons.auto_awesome_rounded,
      _s1000),
  Achievement('Sang Maestro', 'Capai skor 5.000', Icons.workspace_premium_rounded,
      _s5000),
  Achievement('Sultan Koin', 'Kumpulkan 200 koin', Icons.monetization_on_rounded,
      _c200),
  Achievement('Kolektor Batik', 'Miliki 2+ skin', Icons.palette_rounded,
      _skins2),
  Achievement('Pecinta Keraton', 'Miliki semua skin', Icons.diamond_rounded,
      _skins4),
  Achievement('Rajin Mampir', 'Login 3 hari beruntun', Icons.local_fire_department_rounded,
      _streak3),
  Achievement('Setia Nusantara', 'Login 7 hari beruntun', Icons.emoji_events_rounded,
      _streak7),
];

bool _s100(AppState a) => a.highScore >= 100;
bool _s1000(AppState a) => a.highScore >= 1000;
bool _s5000(AppState a) => a.highScore >= 5000;
bool _c200(AppState a) => a.coins >= 200;
bool _skins2(AppState a) => a.unlockedSkinCount >= 2;
bool _skins4(AppState a) => a.unlockedSkinCount >= 4;
bool _streak3(AppState a) => a.dailyStreak >= 3;
bool _streak7(AppState a) => a.dailyStreak >= 7;
