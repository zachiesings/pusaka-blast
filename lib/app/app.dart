import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../features/splash/splash_screen.dart';

class PusakaBlastApp extends StatelessWidget {
  final AppState appState;
  const PusakaBlastApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: MaterialApp(
        title: 'Pusaka Blast',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const SplashScreen(),
      ),
    );
  }
}
