import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/local/preferences.dart';
import 'data/repositories/football_repository.dart';
import 'features/language/language_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/permissions/notification_screen.dart';
import 'features/shell/home_shell.dart';
import 'features/splash/splash_screen.dart';
import 'l10n/app_locales.dart';
import 'state/app_state.dart';
import 'state/matches_state.dart';

class PulseScoreApp extends StatelessWidget {
  const PulseScoreApp({super.key, required this.preferences});

  final Preferences preferences;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState(preferences)),
        Provider<FootballRepository>(
          create: (_) => FootballRepository(),
          dispose: (_, repo) => repo.dispose(),
        ),
        ChangeNotifierProxyProvider<FootballRepository, MatchesState>(
          create: (context) =>
              MatchesState(context.read<FootballRepository>()),
          update: (_, repo, previous) => previous ?? MatchesState(repo),
        ),
      ],
      child: Consumer<AppState>(
        builder: (context, app, _) {
          return MaterialApp(
            title: 'PulseScore',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.build(),
            themeMode: ThemeMode.dark,
            locale: Locale(app.languageCode),
            supportedLocales: kSupportedLocales.map((l) => l.locale),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // Every locale we ship copy for resolves to itself; anything else
            // (a device set to a language we don't translate) lands on English
            // rather than the first supported locale, which is Vietnamese.
            localeResolutionCallback: (deviceLocale, supported) {
              final wanted = Locale(app.languageCode);
              return supported.contains(wanted) ? wanted : const Locale('en');
            },
            builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
              value: AppTheme.systemOverlay,
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.35,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
            home: const _SplashGate(child: _RootRouter()),
          );
        },
      ),
    );
  }
}

/// Holds the logo on screen at launch, then crossfades into the app.
///
/// The splash does real work rather than just stalling: it kicks off the first
/// live-scores fetch, so the Live tab arrives already populated instead of
/// showing skeleton rows. It waits for whichever finishes last — the minimum
/// dwell or the fetch — but never longer than [_maxWait], so a slow network
/// can't hold the user on a logo.
class _SplashGate extends StatefulWidget {
  const _SplashGate({required this.child});

  final Widget child;

  /// Long enough for the mark to register, short enough not to feel like a wait.
  static const _dwell = Duration(milliseconds: 1700);
  static const _maxWait = Duration(seconds: 5);
  static const _fade = Duration(milliseconds: 450);

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // After the first frame, not during it: load() flips to a loading state and
    // notifies synchronously, which would be a setState-during-build if called
    // while this widget is still mounting.
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final matches = context.read<MatchesState>();

    await Future.wait([
      Future<void>.delayed(_SplashGate._dwell),
      // The repository already degrades to demo data rather than throwing, but
      // the splash must not depend on that contract holding.
      matches.load().catchError((_) {}),
    ]).timeout(_SplashGate._maxWait, onTimeout: () => const []);

    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: _SplashGate._fade,
      // The default layout builder stacks children under *loose* constraints,
      // which collapses a full-screen child (the splash centres itself with
      // Spacers and needs a bounded height). Expand instead.
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: [
          ...previous,
          ?current,
        ],
      ),
      child: _ready
          ? KeyedSubtree(key: const ValueKey('app'), child: widget.child)
          : const SplashScreen(key: ValueKey('splash')),
    );
  }
}

/// Decides which first-run step (if any) stands between launch and the app.
///
/// Kept as a single widget switching on [AppState] rather than a named-route
/// stack: each step's completion flag is persisted, so the correct screen is a
/// pure function of state and the flow survives a cold start mid-onboarding.
class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    if (!app.languageChosen) {
      return LanguageScreen(
        isFirstRun: true,
        onDone: () => app.setLanguage(app.languageCode),
      );
    }

    if (!app.onboardingComplete) {
      return OnboardingScreen(onFinished: app.completeOnboarding);
    }

    if (!app.notificationsAsked) {
      return NotificationPermissionScreen(
        onEnable: () => app.recordNotificationChoice(true),
        onSkip: () => app.recordNotificationChoice(false),
      );
    }

    return const HomeShell();
  }
}
