// App Store screenshot capture (iPhone 6.9"). Renders REAL gameplay screens
// with a deterministically-seeded controller, so every shot shows the app in
// use (fixes Guideline 2.3.3). Driven from CI via `flutter drive` against the
// driver in test_driver/integration_test.dart, which writes the PNGs to disk.
//
// NOTE: we use pump(Duration) and never pumpAndSettle — the animated backdrop
// and the idle mascot loop forever, so pumpAndSettle would time out. After each
// capture we replace the tree with an empty widget and dispose the controller
// so no animation outlives the test. Each test has a hard timeout so a stall
// fails fast instead of hanging the whole job.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pusaka_blast/core/constants.dart';
import 'package:pusaka_blast/core/theme.dart';
import 'package:pusaka_blast/game/game_mode.dart';
import 'package:pusaka_blast/services/ads/ads_service.dart';
import 'package:pusaka_blast/services/audio/audio_service.dart';
import 'package:pusaka_blast/services/storage/prefs.dart';
import 'package:pusaka_blast/state/app_state.dart';
import 'package:pusaka_blast/state/game_controller.dart';
import 'package:pusaka_blast/features/game/game_screen.dart';
import 'package:pusaka_blast/features/adventure/adventure_map_screen.dart';

const _perTest = Timeout(Duration(seconds: 120));

Future<AppState> _makeApp() async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'pb_first_run': false, // suppress the how-to overlay so gameplay is visible
    'pb_coins': 1480,
    'pb_high_score': 9200,
    'pb_sound': false, // keep CI quiet
    'pb_music': false,
  });
  final prefs = await Prefs.create();
  return AppState(prefs, StubAdsService(), AudioService());
}

/// A believable mid-game 8x8 board (row-major colour ints, -1 = empty) with a
/// bottom row one cell short of clearing.
List<int> _showcaseBoard() {
  final c = Palette.blockColors;
  final b = List<int>.filled(64, -1);
  void set(int col, int row, int ci) => b[row * 8 + col] = c[ci % c.length].value;
  for (var col = 0; col < 7; col++) {
    set(col, 7, col); // bottom row: 7/8 filled → about to clear
  }
  set(0, 6, 1); set(1, 6, 1); set(2, 6, 3);
  set(4, 6, 4); set(5, 6, 4); set(6, 6, 2);
  set(0, 5, 2); set(1, 5, 2);
  set(5, 5, 5); set(6, 5, 5); set(7, 5, 5);
  set(3, 4, 6); set(4, 4, 6);
  return b;
}

Widget _wrapGame(AppState app, GameController gc) => MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: app),
        ChangeNotifierProvider<GameController>.value(value: gc),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const GameScreen(),
      ),
    );

Future<void> _shoot(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  Widget app,
  String name,
) async {
  await tester.pumpWidget(app);
  await tester.pump(const Duration(milliseconds: 450));
  await binding.convertFlutterSurfaceToImage();
  await tester.pump(const Duration(milliseconds: 16));
  await binding.takeScreenshot(name);
}

Future<void> _captureGame(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  AppState app,
  GameController gc,
  String name,
) async {
  await _shoot(tester, binding, _wrapGame(app, gc), name);
  await tester.pumpWidget(const SizedBox.shrink()); // tear down before disposing
  gc.dispose();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('blast_01_board', (tester) async {
    final app = await _makeApp();
    final gc = GameController(app, mode: BlastMode.klasik)..newGame();
    gc.engine.deserialize(_showcaseBoard());
    gc.score = 8420;
    gc.combo = 3;
    gc.maxCombo = 5;
    await _captureGame(tester, binding, app, gc, 'blast_01_board');
  }, timeout: _perTest);

  testWidgets('blast_02_berkah', (tester) async {
    final app = await _makeApp();
    final gc = GameController(app, mode: BlastMode.klasik)..newGame();
    gc.engine.deserialize(_showcaseBoard());
    gc.score = 13950;
    gc.combo = 6;
    gc.maxCombo = 6;
    gc.berkahMeter = 1.0;
    gc.berkahClears = 3; // Berkah Keraton (x2) active → HUD lights up
    await _captureGame(tester, binding, app, gc, 'blast_02_berkah');
  }, timeout: _perTest);

  testWidgets('blast_03_adventure', (tester) async {
    final app = await _makeApp();
    final w = MultiProvider(
      providers: [ChangeNotifierProvider<AppState>.value(value: app)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const AdventureMapScreen(),
      ),
    );
    await _shoot(tester, binding, w, 'blast_03_adventure');
    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: _perTest);
}
