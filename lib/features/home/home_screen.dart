import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/motion.dart';
import '../../game/game_mode.dart';
import '../../game/wave.dart';
import '../../game/achievements.dart';
import '../../game/skins.dart';
import '../../state/app_state.dart';
import '../../state/game_controller.dart';
import '../../widgets/batik.dart';
import '../../widgets/banner_ad.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/home_decor.dart';
import '../../widgets/roaming_mascot.dart';
import '../game/widgets/game_backdrop.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/effects.dart';
import '../game/game_screen.dart';
import '../settings/settings_screen.dart';
import '../about/about_screen.dart';
import '../shop/shop_screen.dart';
import '../achievements/achievements_screen.dart';
import '../adventure/adventure_map_screen.dart';

/// The home is a 3-tab shell — Beranda (quick play + heralds), Petualangan (the
/// 20-wave map) and Profil (stats + menus) — so it's a living hub, not one page.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  int _tab = 0;
  late final AnimationController _tabAnim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 340))
        ..value = 1;

  void _selectTab(int i) {
    if (i == _tab) return;
    setState(() => _tab = i);
    _tabAnim.forward(from: 0);
  }

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

  @override
  void dispose() {
    _tabAnim.dispose();
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
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: TabSwapTransition(
        animation: _tabAnim,
        child: IndexedStack(
          index: _tab,
          children: [
            _BerandaTab(onOpenAdventure: () => _selectTab(1)),
            const AdventureMapScreen(embedded: true),
            const _ProfilTab(),
          ],
        ),
      ),
      bottomNavigationBar: _NavBar(index: _tab, onTap: _selectTab),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _NavBar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.panel.withOpacity(0.0), Palette.bg0.withOpacity(0.96)],
        ),
      ),
      padding: const EdgeInsets.only(top: 6),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.transparent,
          indicatorColor: Palette.gold.withOpacity(0.22),
          labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: s.contains(WidgetState.selected) ? Palette.gold : Palette.cream.withOpacity(0.6),
              )),
        ),
        child: NavigationBar(
          height: 64,
          backgroundColor: Colors.transparent,
          selectedIndex: index,
          onDestinationSelected: onTap,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined, color: Palette.goldSoft),
                selectedIcon: Icon(Icons.home_rounded, color: Palette.gold),
                label: 'Beranda'),
            NavigationDestination(
                icon: Icon(Icons.map_outlined, color: Palette.goldSoft),
                selectedIcon: Icon(Icons.map_rounded, color: Palette.gold),
                label: 'Petualangan'),
            NavigationDestination(
                icon: Icon(Icons.person_outline_rounded, color: Palette.goldSoft),
                selectedIcon: Icon(Icons.person_rounded, color: Palette.gold),
                label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Beranda tab — animated hero, quick play, campaign herald, strolling mascot.
// ===========================================================================
class _BerandaTab extends StatefulWidget {
  final VoidCallback onOpenAdventure;
  const _BerandaTab({required this.onOpenAdventure});

  @override
  State<_BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<_BerandaTab> {
  BlastMode _mode = BlastMode.klasik;

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
    if (mounted) app.startHomeMusic();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return BatikBackground(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: GameBackdrop()),
          const Positioned.fill(child: SparkleField(count: 24)),
          const Positioned(top: 0, left: 0, right: 0, child: PendopoRoof()),
          // strolling character along the lower third
          const Positioned(left: 0, right: 0, bottom: 78, height: 110,
              child: IgnorePointer(child: RoamingMascot(size: 64, period: 18))),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  _TopBar(
                    coins: app.coins,
                    streak: app.dailyStreak,
                    music: app.music,
                    onMusic: () => app.setMusic(!app.music),
                  ),
                  const SizedBox(height: 2),
                  const _HeroMascot(),
                  const SizedBox(height: 2),
                  const ShimmerSweep(
                    child: GoldTitle('PUSAKA BLAST', size: 40, letterSpacing: 3),
                  ),
                  const SizedBox(height: 8),
                  const _OrnamentDivider(),
                  const SizedBox(height: 6),
                  Text('Teka-teki balok rasa Nusantara',
                      style: TextStyle(
                          color: Palette.cream.withOpacity(0.6),
                          letterSpacing: 0.5,
                          fontSize: 13)),
                  const SizedBox(height: 18),
                  _StatRow(best: app.highScore, coins: app.coins),
                  const SizedBox(height: 16),
                  _AdventureHerald(
                    unlocked: app.campaignUnlocked,
                    stars: app.totalStars,
                    complete: app.campaignComplete,
                    onTap: widget.onOpenAdventure,
                  ),
                  const SizedBox(height: 16),
                  // Quick-play card
                  SoftCard(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      children: [
                        Row(
                          children: BlastMode.values.map((m) {
                            final sel = _mode == m;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _mode = m),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: sel ? Palette.gold : Palette.bg1.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(16),
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
                        const SizedBox(height: 8),
                        Text(_mode.desc,
                            style: TextStyle(color: Palette.cream.withOpacity(0.55), fontSize: 12)),
                        const SizedBox(height: 12),
                        GradientButton(
                          label: 'MAIN',
                          icon: Icons.play_arrow_rounded,
                          height: 60,
                          fontSize: 20,
                          onTap: () => _play(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniButton(
                          icon: Icons.palette_rounded,
                          label: 'Toko',
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ShopScreen())),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniButton(
                          icon: Icons.emoji_events_rounded,
                          label: 'Pencapaian',
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AchievementsScreen())),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Center(child: BannerAdBar()),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A gently floating hero mascot that waves to the player on its own clock.
class _HeroMascot extends StatefulWidget {
  const _HeroMascot();
  @override
  State<_HeroMascot> createState() => _HeroMascotState();
}

class _HeroMascotState extends State<_HeroMascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 4200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        // wave/cheer in the last quarter of every cycle; idle otherwise
        final cheering = _c.value > 0.75;
        return MascotView(
          size: 150,
          mood: cheering ? MascotMood.cheer : MascotMood.idle,
        );
      },
    );
  }
}

/// The campaign call-to-action herald on Beranda.
class _AdventureHerald extends StatelessWidget {
  final int unlocked, stars;
  final bool complete;
  final VoidCallback onTap;
  const _AdventureHerald({
    required this.unlocked,
    required this.stars,
    required this.complete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cur = WaveCatalog.byIndex(unlocked.clamp(1, WaveCatalog.count));
    final accent = cur.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent.withOpacity(0.32), Palette.panel.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Palette.gold.withOpacity(0.45), width: 1.2),
          boxShadow: Palette.glow(accent, blur: 22, a: 0.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: Palette.brand,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: Palette.glow(Palette.gold, blur: 14, a: 0.3),
                  ),
                  child: Icon(complete ? Icons.workspace_premium_rounded : cur.goal.icon,
                      color: Palette.ink, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(complete ? 'PETUALANGAN' : 'LANJUTKAN',
                          style: TextStyle(
                              color: accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2)),
                      const SizedBox(height: 2),
                      Text(complete ? 'Nusantara Tuntas' : cur.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Palette.cream, fontSize: 18, fontWeight: FontWeight.w900)),
                      Text(complete ? 'Semua pusaka diraih' : '${cur.region} • ${cur.goal.label(cur.target)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Palette.cream.withOpacity(0.6), fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Palette.gold, size: 28),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (unlocked - 1) / WaveCatalog.count,
                      minHeight: 6,
                      backgroundColor: Palette.bg1.withOpacity(0.7),
                      color: Palette.gold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.star_rounded, color: Palette.gold, size: 15),
                const SizedBox(width: 3),
                Text('$stars',
                    style: const TextStyle(
                        color: Palette.gold, fontWeight: FontWeight.w900, fontSize: 13)),
                const SizedBox(width: 8),
                Text('${(unlocked - 1).clamp(0, WaveCatalog.count)}/${WaveCatalog.count}',
                    style: TextStyle(
                        color: Palette.cream.withOpacity(0.7),
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Top utility bar on Beranda — coins, login streak, and the music toggle.
class _TopBar extends StatelessWidget {
  final int coins, streak;
  final bool music;
  final VoidCallback onMusic;
  const _TopBar({
    required this.coins,
    required this.streak,
    required this.music,
    required this.onMusic,
  });

  @override
  Widget build(BuildContext context) {
    Widget pill(IconData icon, String label, Color c) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Palette.panel.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.withOpacity(0.35)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: c, size: 17),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 13)),
          ]),
        );
    return Row(
      children: [
        pill(Icons.monetization_on_rounded, '$coins', Palette.gold),
        const SizedBox(width: 8),
        if (streak > 0) pill(Icons.local_fire_department_rounded, '${streak}h', Palette.coral),
        const Spacer(),
        GestureDetector(
          onTap: onMusic,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Palette.panel.withOpacity(0.7),
              shape: BoxShape.circle,
              border: Border.all(color: Palette.gold.withOpacity(0.35)),
            ),
            child: Icon(music ? Icons.music_note_rounded : Icons.music_off_rounded,
                color: music ? Palette.gold : Palette.goldSoft, size: 20),
          ),
        ),
      ],
    );
  }
}

/// A small carved batik divider — a gold rule with a centre diamond.
class _OrnamentDivider extends StatelessWidget {
  const _OrnamentDivider();
  @override
  Widget build(BuildContext context) {
    Widget rule() => Container(
          width: 52,
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [Palette.gold.withOpacity(0), Palette.gold.withOpacity(0.7)]),
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        rule(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.diamond_rounded, color: Palette.gold, size: 12),
        ),
        Transform.flip(flipX: true, child: rule()),
      ],
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MiniButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Palette.gold,
        side: BorderSide(color: Palette.gold.withOpacity(0.7)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final int best, coins;
  const _StatRow({required this.best, required this.coins});

  @override
  Widget build(BuildContext context) {
    Widget card(IconData icon, String label, String value, Color c) => Expanded(
          child: SoftCard(
            glow: c,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(children: [
              Icon(icon, color: c, size: 24),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(color: c, fontSize: 22, fontWeight: FontWeight.w800)),
              Text(label.toUpperCase(),
                  style: TextStyle(
                      color: Palette.cream.withOpacity(0.55),
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        );
    return Row(
      children: [
        card(Icons.emoji_events_rounded, 'Terbaik', '$best', Palette.gold),
        const SizedBox(width: 14),
        card(Icons.monetization_on_rounded, 'Koin', '$coins', Palette.coral),
      ],
    );
  }
}

// ===========================================================================
// Profil tab — lifetime stats + menu shortcuts.
// ===========================================================================
class _ProfilTab extends StatelessWidget {
  const _ProfilTab();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final achDone = kAchievements.where((a) => a.met(app)).length;
    final rows = <(IconData, String, String)>[
      (Icons.emoji_events_rounded, 'Skor Tertinggi', '${app.highScore}'),
      (Icons.map_rounded, 'Wave Selesai', '${app.wavesCleared}/${WaveCatalog.count}'),
      (Icons.star_rounded, 'Total Bintang', '${app.totalStars}/${WaveCatalog.count * 3}'),
      (Icons.sports_esports_rounded, 'Total Main', '${app.gamesPlayed}'),
      (Icons.grid_on_rounded, 'Baris Dibersihkan', '${app.totalLines}'),
      (Icons.palette_rounded, 'Skin Dimiliki', '${app.unlockedSkinCount}/${SkinCatalog.all.length}'),
      (Icons.workspace_premium_rounded, 'Pencapaian', '$achDone/${kAchievements.length}'),
      (Icons.local_fire_department_rounded, 'Login Beruntun', '${app.dailyStreak} hari'),
    ];
    return BatikBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          children: [
            const Center(child: GoldTitle('Profil', size: 26)),
            const SizedBox(height: 16),
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
                              color: Palette.gold, fontSize: 18, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _MiniButton(
                    icon: Icons.settings_rounded,
                    label: 'Pengaturan',
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniButton(
                    icon: Icons.info_outline_rounded,
                    label: 'Tentang',
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AboutScreen())),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
