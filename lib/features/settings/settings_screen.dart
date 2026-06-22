import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../state/app_state.dart';
import '../../widgets/batik.dart';
import '../../widgets/soft_card.dart';
import '../stats/stats_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: BatikBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SoftCard(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Column(
                  children: [
                    _toggle(Icons.music_note_rounded, 'Musik', 'BGM gamelan di beranda',
                        app.music, app.setMusic),
                    _divider(),
                    _toggle(Icons.volume_up_rounded, 'Suara', 'Efek saat menaruh & membersihkan baris',
                        app.sound, app.setSound),
                    _divider(),
                    _toggle(Icons.vibration_rounded, 'Getaran', 'Umpan-balik getar (haptic)',
                        app.haptics, app.setHaptics),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SoftCard(
                glow: Palette.gold,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: Palette.gold),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cara Bermain',
                              style: TextStyle(
                                  color: Palette.cream, fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(
                              'Seret balok ke papan 8×8. Penuhi satu baris atau kolom untuk '
                              'membersihkannya. Bersihkan beberapa sekaligus untuk COMBO!',
                              style: TextStyle(color: Palette.cream.withOpacity(0.6), height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StatsScreen())),
                child: SoftCard(
                  child: Row(
                    children: [
                      const Icon(Icons.bar_chart_rounded, color: Palette.gold),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text('Statistik',
                            style: TextStyle(
                                color: Palette.cream, fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Palette.cream.withOpacity(0.5)),
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

  Widget _divider() => Divider(color: Palette.gold.withOpacity(0.12), height: 1, indent: 16, endIndent: 16);

  Widget _toggle(IconData icon, String title, String sub, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: Palette.gold,
        activeTrackColor: Palette.goldSoft,
        secondary: Icon(icon, color: Palette.gold),
        title: Text(title,
            style: const TextStyle(color: Palette.cream, fontWeight: FontWeight.w700)),
        subtitle: Text(sub, style: TextStyle(color: Palette.cream.withOpacity(0.5), fontSize: 12)),
      );
}
