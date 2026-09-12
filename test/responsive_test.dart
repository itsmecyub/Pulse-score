import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pulse_score/ads/ads_boot.dart';
import 'package:pulse_score/core/theme/app_theme.dart';
import 'package:pulse_score/data/local/preferences.dart';
import 'package:pulse_score/data/repositories/football_repository.dart';
import 'package:pulse_score/features/shell/home_shell.dart';
import 'package:pulse_score/state/app_state.dart';
import 'package:pulse_score/state/matches_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/mock_backend.dart';

/// Every screen, at the extremes of the screen sizes the app ships to.
///
/// A RenderFlex overflow, an unbounded constraint or a failed assertion
/// anywhere in these trees throws, so the pump itself is the assertion. The
/// sizes are logical pixels, portrait — the only orientation the app allows.
const _sizes = <String, Size>{
  // The smallest display iOS 15 still runs on: iPhone SE (1st/2nd/3rd gen).
  'iPhone SE': Size(320, 568),
  // The narrowest Android phone worth supporting at minSdk 24.
  'small Android': Size(360, 640),
  'iPhone 16e': Size(390, 844),
  'iPhone 17 Pro Max': Size(440, 956),
  // iPad portrait, where the app is widest.
  'iPad 11-inch': Size(834, 1194),
  'iPad Pro 13-inch': Size(1032, 1376),
};

Future<Widget> _app() async {
  SharedPreferences.setMockInitialValues({
    'flutter.language_code': 'en',
    'flutter.onboarding_complete': true,
    'flutter.notifications_asked': true,
  });
  final preferences = await Preferences.load();
  seedAds();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppState(preferences)),
      Provider<FootballRepository>(create: (_) => mockRepository()),
      ChangeNotifierProxyProvider<FootballRepository, MatchesState>(
        create: (context) => MatchesState(context.read<FootballRepository>()),
        update: (_, repo, previous) => previous ?? MatchesState(repo),
      ),
    ],
    child: MaterialApp(theme: AppTheme.build(), home: const HomeShell()),
  );
}

/// The live dot pulses forever, so the tree never reaches quiescence and
/// `pumpAndSettle` would time out. Advance a fixed number of frames instead.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  _sizes.forEach((name, size) {
    testWidgets('every tab lays out on $name', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(await _app());
      await _settle(tester);
      expect(tester.takeException(), isNull, reason: 'Live tab on $name');

      for (final tab in ['Schedule', 'Explore', 'Pinned', 'Settings']) {
        await tester.tap(find.text(tab), warnIfMissed: false);
        await _settle(tester);
        expect(tester.takeException(), isNull, reason: '$tab tab on $name');
      }
    });
  });
}
