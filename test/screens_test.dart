import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pulse_score/core/theme/app_theme.dart';
import 'package:pulse_score/data/local/preferences.dart';
import 'package:pulse_score/data/repositories/football_repository.dart';
import 'package:pulse_score/ads/ads_boot.dart';
import 'package:pulse_score/features/match/match_detail_screen.dart';
import 'package:pulse_score/features/premium/paywall_screen.dart';
import 'package:pulse_score/features/shell/home_shell.dart';
import 'package:pulse_score/state/app_state.dart';
import 'package:pulse_score/state/matches_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/mock_backend.dart';

/// Screen-level smoke tests.
///
/// These run in demo mode (no API key in the test environment), so every screen
/// gets real, populated data without touching the network. The point is not the
/// assertions so much as the pump itself: a RenderFlex overflow, an unbounded
/// constraint or a null deref anywhere in these trees fails the test.
Future<Widget> _app({Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues({
    'flutter.language_code': 'en',
    'flutter.onboarding_complete': true,
    'flutter.notifications_asked': true,
    ...prefs,
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

/// The live-match dot pulses forever by design, so the widget tree never
/// reaches quiescence and `pumpAndSettle` would time out. Advance a fixed
/// number of frames instead — enough for async loads and route transitions.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  // A tall surface keeps the carousels and grids from being clipped into
  // "overflow" failures that a real phone would simply scroll.
  const surface = Size(430, 1400);

  testWidgets('every tab renders without layout errors', (tester) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _app());
    await settle(tester);

    // Live tab landed with the recorded fixtures.
    expect(find.text('LIVE NOW  ·  3'), findsOneWidget);
    expect(find.text('IF Brommapojkarna'), findsWidgets);

    for (final tab in ['Schedule', 'Explore', 'Pinned', 'Settings']) {
      await tester.tap(find.text(tab));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: '$tab tab threw');
    }
  });

  testWidgets('Explore lists the big leagues, all unlocked', (tester) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _app());
    await settle(tester);
    await tester.tap(find.text('Explore'));
    await settle(tester);

    expect(find.text('TOP LEAGUES'), findsOneWidget);
    for (final league in [
      'Premier League',
      'La Liga',
      'Serie A',
      'Bundesliga',
      'Ligue 1',
      'Champions League',
    ]) {
      expect(find.text(league), findsOneWidget, reason: '$league missing');
    }

    // Nothing secondary is promoted any more.
    expect(find.text('MORE LEAGUES'), findsNothing);
    expect(find.text('V-League'), findsNothing);

    // Every league card ends in a chevron; a gated one would show a padlock
    // instead. Six leagues, six chevrons, so none is locked.
    expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(6));
    expect(
      find.byIcon(Icons.lock_rounded),
      findsOneWidget,
      reason: 'the only padlock left belongs to the premium news feed',
    );
  });

  testWidgets('Pinned shows the empty state until something is pinned',
      (tester) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _app());
    await settle(tester);
    await tester.tap(find.text('Pinned'));
    await settle(tester);

    expect(find.text('No pinned teams'), findsOneWidget);
    expect(find.text('[EMPTY]'), findsOneWidget);
  });

  testWidgets('Settings reflects the stored language and league',
      (tester) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _app());
    await settle(tester);
    await tester.tap(find.text('Settings'));
    await settle(tester);

    expect(find.text('Upgrade to Premium'), findsOneWidget);
    expect(find.text('Premier League'), findsOneWidget);
    expect(find.text('v1.1.6'), findsOneWidget);
  });

  testWidgets('match detail renders a live fixture with its events',
      (tester) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    SharedPreferences.setMockInitialValues({});
    final preferences = await Preferences.load();
    final repo = mockRepository();
    seedAds();
    // A real in-play match from the recorded live payload; it carries events.
    final fixture = (await repo.liveFixtures()).data.first;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState(preferences)),
          Provider<FootballRepository>(create: (_) => repo),
            ],
        child: MaterialApp(
          theme: AppTheme.build(),
          home: MatchDetailScreen(fixture: fixture),
        ),
      ),
    );
    await settle(tester);

    expect(find.text('IF Brommapojkarna'), findsWidgets);
    expect(find.text('EVENTS'), findsOneWidget);
    expect(find.text('Anton Kurochkin'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('paywall grants the entitlement and updates in place',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await Preferences.load();
    final app = AppState(preferences);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          theme: AppTheme.build(),
          home: const PaywallScreen(),
        ),
      ),
    );
    await settle(tester);

    expect(app.isPremium, isFalse);
    await tester.tap(find.text('Unlock Premium'));
    await settle(tester);

    expect(app.isPremium, isTrue);
    expect(find.text('Premium active'), findsOneWidget);
  });

  testWidgets('free tier stops at the pin limit and offers the paywall',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState(await Preferences.load());

    for (var i = 0; i < AppState.freePinLimit; i++) {
      expect(await app.toggleTeamPin(i), isTrue);
    }
    // The next one is refused rather than silently ignored.
    expect(await app.toggleTeamPin(99), isFalse);
    expect(app.pinnedTeamIds.length, AppState.freePinLimit);

    await app.setPremium(true);
    expect(await app.toggleTeamPin(99), isTrue);
  });
}
