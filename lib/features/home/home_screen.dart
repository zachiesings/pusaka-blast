import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../game/game_mode.dart';
import '../../state/app_state.dart';
import '../../state/game_controller.dart';
import '../../widgets/batik.dart';
import '../../widgets/banner_ad.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';
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
  BlastMode _mode = BlastMode.klasik;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().startHomeMusic();
      _maybeShowDaily();
    });
  }

  void _maybeShowDaily() {
    final app = context.read<AppState>();
    if (!app.dailyClaimable) return;
    final (coins, streak) = app.claimDaily();
    if (coins <= 0) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Palette.panel, Palette.bg1],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Palette.gold.withOpacity(0.45), width: 1.5),
            boxShadow: Palette.glow(Palette.gold, blur: 40, a: 0.4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.card_giftcard_rounded, color: Palette.gold, size: 56),
              const SizedBox(height: 10),
              const GoldTitle('Hadiah Harian', size: 24),
              const SizedBox(height: 8),
              Text('Hari ke-$streak beruntun 🔥',
                  style: const TextStyle(color: Palette.cream, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.monetization_on, color: Palette.gold, size: 30),
                const SizedBox(width: 8),
                Text('+$coins',
                    style: const TextStyle(
                        color: Palette.gold, fontSize: 34, fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                    label: 'Ambil!',
                    height: 52,
                    onTap: () => Navigator.of(context).pop()),
              ),
            ],
          ),
        ),
      ),
    );
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
          create: (_) => GameController(app, mode: _mode)..newGame(),
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
                const GoldTitle('PUSAKA BLAST', size: 36, letterSpacing: 2),
                const SizedBox(height: 4),
                Text('Teka-teki balok rasa Nusantara',
                    style: TextStyle(color: Palette.cream.withOpacity(0.6), letterSpacing: 0.5)),
                const Spacer(),
                _StatRow(best: app.highScore, coins: app.coins),
                const Spacer(),
                // Mode selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: BlastMode.values.map((m) {
                    final sel = _mode == m;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: GestureDetector(
                        onTap: () => setState(() => _mode = m),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            color: sel ? Palette.gold : Palette.panel.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: sel ? Palette.gold : Palette.gold.withOpacity(0.25)),
                          ),
                          child: Text(m.label,
                              style: TextStyle(
                                  color: sel ? Palette.ink : Palette.cream,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
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
    Widget card(IconData icon, String label, String value, Color c) => SoftCard(
          glow: c,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          child: Column(children: [
            Icon(icon, color: c, size: 26),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: c, fontSize: 24, fontWeight: FontWeight.w800)),
            Text(label.toUpperCase(),
                style: TextStyle(
                    color: Palette.cream.withOpacity(0.55),
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700)),
          ]),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        card(Icons.emoji_events_rounded, 'Terbaik', '$best', Palette.gold),
        card(Icons.monetization_on_rounded, 'Koin', '$coins', Palette.coral),
      ],
    );
  }
}
