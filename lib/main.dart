import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'core/constants.dart';
import 'services/ads/ads_service.dart';
import 'services/ads/google_mobile_ads_service.dart';
import 'services/audio/audio_service.dart';
import 'services/storage/prefs.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await Prefs.create();
  final AdsService ads = K.adsEnabled ? GoogleMobileAdsService() : StubAdsService();
  final audio = AudioService();
  final appState = AppState(prefs, ads, audio);

  runApp(PusakaBlastApp(appState: appState));
}
