import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../game/achievements.dart';
import '../../game/skins.dart';
import '../../state/app_state.dart';
import '../../widgets/batik.dart';
import '../../widgets/soft_card.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final achDone = kAchievements.where((a) => a.met(app)).length;
    final rows = <(IconData, String, String)>[
      (Icons.emoji_events_rounded, 'Skor Tertinggi', '${app.highScore}'),
      (Icons.sports_esports_rounded, 'Total Main', '${app.gamesPlayed}'),
      (Icons.grid_on_rounded, 'Baris Dibersihkan', '${app.totalLines}'),
      (Icons.monetization_on_rounded, 'Koin', '${app.coins}'),
      (Icons.palette_rounded, 'Skin Dimiliki', '${app.unlockedSkinCount}/${SkinCatalog.all.length}'),
      (Icons.workspace_premium_rounded, 'Pencapaian', '$achDone/${kAchievements.length}'),
      (Icons.local_fire_department_rounded, 'Login Beruntun', '${app.dailyStreak} hari'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: BatikBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              for (final r in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SoftCard(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: Palette.brand,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(r.$1, color: Palette.ink, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(r.$2,
                              style: const TextStyle(
                                  color: Palette.cream, fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                        Text(r.$3,
                            style: const TextStyle(
                                color: Palette.gold, fontSize: 20, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
