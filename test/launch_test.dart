import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_score/ads/ads_boot.dart';
import 'package:pulse_score/app.dart';
import 'package:pulse_score/core/widgets/pulse_logo.dart';
import 'package:pulse_score/data/local/preferences.dart';
import 'package:pulse_score/features/language/language_screen.dart';
import 'package:pulse_score/features/shell/home_shell.dart';
import 'package:pulse_score/features/splash/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/mock_backend.dart';

/// Launch sequence: logo first, then the app.
Future<Preferences> _prefs({bool firstRun = false}) async {
  SharedPreferences.setMockInitialValues(
    firstRun
        ? {}
        : {
            'flutter.language_code': 'en',
            'flutter.onboarding_complete': true,
            'flutter.notifications_asked': true,
          },
  );
  return Preferences.load();
}

void main() {
  // The splash boots the ads module, which reads its config over the network.
  // Seeding it keeps that I/O out of the fake-async zone these tests run in.
  setUp(seedAds);

  testWidgets('opens on the logo, then lands on the Live tab', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(PulseScoreApp(preferences: await _prefs(), repository: mockRepository()));
    await tester.pump();

    // First frame is the branded splash, not the app.
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(PulseLogo), findsOneWidget);
    expect(find.byType(HomeShell), findsNothing);

    // Still holding partway through the dwell.
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(SplashScreen), findsOneWidget);

    // Past the dwell and the crossfade, the shell is up on Live.
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('Live'), findsOneWidget);
  });

  testWidgets('scores are already loaded when the splash lifts',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(PulseScoreApp(preferences: await _prefs(), repository: mockRepository()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump(const Duration(milliseconds: 600));

    // The splash prefetches, so the first painted frame of the Live tab shows
    // real fixtures rather than loading skeletons.
    expect(find.text('LIVE NOW  ·  3'), findsOneWidget);
    expect(find.text('IF Brommapojkarna'), findsWidgets);
  });

  testWidgets('a first run still gets the language picker after the logo',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      PulseScoreApp(
        preferences: await _prefs(firstRun: true),
        repository: mockRepository(),
      ),
    );
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(LanguageScreen), findsOneWidget);
    expect(find.byType(HomeShell), findsNothing);
  });
}
