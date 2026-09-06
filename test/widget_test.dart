import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pulse_score/core/theme/app_theme.dart';
import 'package:pulse_score/data/local/preferences.dart';
import 'package:pulse_score/features/language/language_screen.dart';
import 'package:pulse_score/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> _wrap(Widget child) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await Preferences.load();
  return ChangeNotifierProvider(
    create: (_) => AppState(prefs),
    child: MaterialApp(theme: AppTheme.build(), home: child),
  );
}

void main() {
  testWidgets('language picker lists every supported language', (tester) async {
    await tester.pumpWidget(
      await _wrap(LanguageScreen(isFirstRun: true, onDone: () {})),
    );

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Tiếng Việt'), findsOneWidget);
    expect(find.text('English'), findsWidgets);
  });

  testWidgets('choosing a language retranslates the screen', (tester) async {
    await tester.pumpWidget(
      await _wrap(LanguageScreen(isFirstRun: true, onDone: () {})),
    );

    await tester.tap(find.text('Tiếng Việt'));
    await tester.pumpAndSettle();

    // The header follows the selection immediately.
    expect(find.text('Ngôn ngữ'), findsOneWidget);
    expect(find.text('Language'), findsNothing);
  });

  testWidgets('confirming reports the choice back to the caller',
      (tester) async {
    var done = false;
    await tester.pumpWidget(
      await _wrap(LanguageScreen(isFirstRun: true, onDone: () => done = true)),
    );

    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    expect(done, isTrue);
  });
}
