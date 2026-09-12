import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pulse_score/data/local/preferences.dart';
import 'package:pulse_score/features/review/review_prompt_host.dart';
import 'package:pulse_score/features/review/review_prompter.dart';
import 'package:pulse_score/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for StoreKit, which has no host to answer it in a test.
class _FakeLauncher implements ReviewLauncher {
  _FakeLauncher({this.available = true, this.throws = false});

  final bool available;
  final bool throws;
  int requests = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> requestReview() async {
    if (throws) throw StateError('store unavailable');
    requests++;
    return true;
  }
}

Future<AppState> _state({
  bool onboarded = true,
  bool alreadyShown = false,
}) async {
  SharedPreferences.setMockInitialValues({
    'flutter.language_code': 'en',
    'flutter.onboarding_complete': onboarded,
    'flutter.notifications_asked': true,
    if (alreadyShown) 'flutter.has_shown_review_prompt': true,
  });
  return AppState(await Preferences.load());
}

void main() {
  group('ReviewPrompter', () {
    test('asks once, then never again', () async {
      final launcher = _FakeLauncher();
      final prompter = ReviewPrompter(launcher: launcher);
      final app = await _state();

      expect(await prompter.maybePrompt(app), isTrue);
      expect(launcher.requests, 1);
      expect(app.hasShownReviewPrompt, isTrue);

      // Same session, and again as if the app had been reopened.
      expect(await prompter.maybePrompt(app), isFalse);
      expect(await prompter.maybePrompt(app), isFalse);
      expect(launcher.requests, 1);
    });

    test('stays quiet after a restart, because the flag is persisted',
        () async {
      final launcher = _FakeLauncher();
      final prompter = ReviewPrompter(launcher: launcher);

      await prompter.maybePrompt(await _state());
      expect(launcher.requests, 1);

      // A fresh AppState over the same stored preferences is what a relaunch
      // looks like.
      final relaunched = AppState(await Preferences.load());
      expect(relaunched.hasShownReviewPrompt, isTrue);
      expect(await prompter.maybePrompt(relaunched), isFalse);
      expect(launcher.requests, 1);
    });

    test('does not ask during first run', () async {
      final launcher = _FakeLauncher();
      final app = await _state(onboarded: false);

      expect(await ReviewPrompter(launcher: launcher).maybePrompt(app), isFalse);
      expect(launcher.requests, 0);
      expect(app.hasShownReviewPrompt, isFalse,
          reason: 'an ask that never happened must not burn the one chance');
    });

    test('does not ask when the store is unavailable, and keeps the chance',
        () async {
      final launcher = _FakeLauncher(available: false);
      final app = await _state();

      expect(await ReviewPrompter(launcher: launcher).maybePrompt(app), isFalse);
      expect(app.hasShownReviewPrompt, isFalse);
    });

    test('a throwing store neither crashes nor re-asks', () async {
      final launcher = _FakeLauncher(throws: true);
      final app = await _state();

      // The flag is set before the request, so a store that blows up mid-call
      // cannot cause a second prompt on the next launch.
      expect(await ReviewPrompter(launcher: launcher).maybePrompt(app), isFalse);
      expect(app.hasShownReviewPrompt, isTrue);
    });
  });

  group('ReviewPromptHost', () {
    testWidgets('asks only after the screen has settled', (tester) async {
      final launcher = _FakeLauncher();
      final app = await _state();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: app,
          child: MaterialApp(
            home: ReviewPromptHost(
              prompter: ReviewPrompter(launcher: launcher),
              child: const Scaffold(body: Text('main screen')),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(launcher.requests, 0, reason: 'not on the very first frame');

      await tester.pump(ReviewPrompter.settleDelay);
      await tester.pump();
      expect(launcher.requests, 1);
    });

    testWidgets('does not fire if the screen goes away first', (tester) async {
      final launcher = _FakeLauncher();
      final app = await _state();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: app,
          child: MaterialApp(
            home: ReviewPromptHost(
              prompter: ReviewPrompter(launcher: launcher),
              child: const Scaffold(body: Text('main screen')),
            ),
          ),
        ),
      );
      await tester.pump();

      // Navigate away before the delay elapses.
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: app,
          child: const MaterialApp(home: Scaffold(body: Text('gone'))),
        ),
      );
      await tester.pump(ReviewPrompter.settleDelay);
      await tester.pump();

      expect(launcher.requests, 0);
      expect(app.hasShownReviewPrompt, isFalse);
    });
  });
}
