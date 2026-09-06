import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pulse_score/core/theme/app_theme.dart';
import 'package:pulse_score/data/local/preferences.dart';
import 'package:pulse_score/data/local/sample_data.dart';
import 'package:pulse_score/data/repositories/football_repository.dart';
import 'package:pulse_score/features/match/match_detail_screen.dart';
import 'package:pulse_score/features/premium/paywall_screen.dart';
import 'package:pulse_score/features/shell/home_shell.dart';
import 'package:pulse_score/state/app_state.dart';
import 'package:pulse_score/state/matches_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppState(preferences)),
      Provider<FootballRepository>(create: (_) => FootballRepository()),
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

    // Live tab landed with demo fixtures.
    expect(find.text('LIVE NOW  ·  6'), findsOneWidget);
    expect(find.text('Everton'), findsWidgets);

    for (final tab in ['Schedule', 'Explore', 'Pinned', 'Settings']) {
      await tester.tap(find.text(tab));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: '$tab tab threw');
    }
  });

  testWidgets('Explore lists both league sections', (tester) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _app());
    await settle(tester);
    await tester.tap(find.text('Explore'));
    await settle(tester);

    expect(find.text('TOP LEAGUES'), findsOneWidget);
    expect(find.text('MORE LEAGUES'), findsOneWidget);
    expect(find.text('Premier League'), findsOneWidget);
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
    expect(find.text('V-League'), findsOneWidget);
    expect(find.text('v1.1.6'), findsOneWidget);
  });

  testWidgets('match detail renders a live fixture with its events',
      (tester) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    SharedPreferences.setMockInitialValues({});
    final preferences = await Preferences.load();
    // Boca vs River — the demo fixture that carries a goal, a card and a penalty.
    final fixture = SampleData.live().firstWhere((f) => f.id == 900005);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState(preferences)),
          Provider<FootballRepository>(create: (_) => FootballRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.build(),
          home: MatchDetailScreen(fixture: fixture),
        ),
      ),
    );
    await settle(tester);

    expect(find.text('1 - 1'), findsOneWidget);
    expect(find.text('E. Cavani'), findsOneWidget);
    expect(find.text('EVENTS'), findsOneWidget);
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
