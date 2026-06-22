import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../state/app_state.dart';
import '../../state/game_controller.dart';
import '../../widgets/batik.dart';
import '../../widgets/banner_ad.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/mascot.dart';
import '../game/game_screen.dart';
import '../settings/settings_screen.dart';
import '../about/about_screen.dart';
import '../shop/shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().startHomeMusic();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final app = context.read<AppState>();
    if (state == AppLifecycleState.resumed) {
      app.startHomeMusic();
    } else if (state == AppLifecycleState.paused) {
      app.stopHomeMusic();
    }
  }

  Future<void> _play(BuildContext context) async {
    final app = context.read<AppState>();
    app.stopHomeMusic();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<GameController>(
          create: (_) => GameController(app)..newGame(),
          child: const GameScreen(),
        ),
      ),
    );
    app.startHomeMusic();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      body: BatikBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => app.setMusic(!app.music),
                    icon: Icon(app.music ? Icons.music_note : Icons.music_off,
                        color: app.music ? Palette.gold : Palette.goldSoft),
                  ),
                ),
                const Spacer(),
                // Animated mascot
                const MascotView(size: 150, mood: MascotMood.idle),
                const SizedBox(height: 8),
                const Text('PUSAKA BLAST',
                    style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Palette.cream)),
                const Text('Teka-teki balok rasa Nusantara',
                    style: TextStyle(color: Palette.goldSoft)),
                const Spacer(),
                _StatRow(best: app.highScore, coins: app.coins),
                const Spacer(),
                GradientButton(
                  label: 'MAIN',
                  icon: Icons.play_arrow_rounded,
                  height: 66,
                  fontSize: 20,
                  onTap: () => _play(context),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ShopScreen())),
                    icon: const Icon(Icons.palette),
                    label: const Text('Toko Batik'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Palette.gold,
                      side: const BorderSide(color: Palette.gold),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen())),
                        icon: const Icon(Icons.settings),
                        label: const Text('Pengaturan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Palette.cream,
                          side: const BorderSide(color: Palette.goldSoft),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AboutScreen())),
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Tentang'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Palette.cream,
                          side: const BorderSide(color: Palette.goldSoft),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
                const Center(child: BannerAdBar()),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final int best, coins;
  const _StatRow({required this.best, required this.coins});

  @override
  Widget build(BuildContext context) {
    Widget card(IconData icon, String label, String value, Color c) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            color: Palette.panel,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(children: [
            Icon(icon, color: c),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: c, fontSize: 22, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: Palette.goldSoft, fontSize: 12)),
          ]),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        card(Icons.emoji_events, 'Terbaik', '$best', Palette.cream),
        card(Icons.monetization_on, 'Koin', '$coins', Palette.gold),
      ],
    );
  }
}
