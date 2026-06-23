import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pusaka_blast/services/ads/ads_service.dart';
import 'package:pusaka_blast/services/audio/audio_service.dart';
import 'package:pusaka_blast/services/storage/prefs.dart';
import 'package:pusaka_blast/state/app_state.dart';
import 'package:pusaka_blast/features/adventure/adventure_map_screen.dart';

void main() {
  testWidgets('adventure map fills the screen and scrolls', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({});
    final prefs = await Prefs.create();
    final app = AppState(prefs, StubAdsService(), AudioService());

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AppState>.value(
          value: app,
          child: const AdventureMapScreen(embedded: true),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    final logical = tester.view.physicalSize / tester.view.devicePixelRatio;
    final scroll = find.byType(Scrollable);
    expect(scroll, findsWidgets);
    final scSize = tester.getSize(scroll.first);
    debugPrint('SURFACE=$logical  SCROLLABLE=$scSize');
    // The scrollable viewport must fill most of the screen height.
    expect(scSize.height, greaterThan(logical.height * 0.7),
        reason: 'map viewport collapsed to ${scSize.height} of ${logical.height}');
  });
}
