import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';
import 'data/local/preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemOverlay);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Preferences come off disk in a few milliseconds. The native launch screen
  // (painted the same navy as the app) covers that gap, so there is no white
  // flash and no second runApp — the Flutter splash then takes over seamlessly.
  final preferences = await Preferences.load();

  runApp(PulseScoreApp(preferences: preferences));
}
