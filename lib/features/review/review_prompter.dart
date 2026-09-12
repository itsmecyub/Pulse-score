import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../state/app_state.dart';

/// The platform's own "rate this app" dialog.
///
/// Behind an interface purely so the once-only logic can be tested without a
/// plugin channel — widget tests have no host to answer it.
abstract class ReviewLauncher {
  /// Whether the platform can show the dialog at all. False on a device with
  /// no App Store / Play Store, and in tests.
  Future<bool> isAvailable();

  /// Ask the OS to show its rating dialog. Returns false when the platform
  /// could not even be asked.
  Future<bool> requestReview();
}

/// iOS: our own StoreKit call, through a channel in AppDelegate.swift.
///
/// `in_app_review` resolves the window scene with `connectedScenes.first`, and
/// `connectedScenes` is a Set — `first` is whatever the hash order yields,
/// which is often a background scene. StoreKit then does nothing at all: no
/// dialog, no error, and the Dart call still completes normally. That is
/// exactly the failure this replaces, so on iOS we pick the foreground-active
/// scene ourselves.
///
/// Everywhere else the plugin is fine, and Android's In-App Review has no
/// equivalent problem.
class StoreKitReviewLauncher implements ReviewLauncher {
  const StoreKitReviewLauncher();

  static const _channel = MethodChannel('pulsescore/review');

  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<bool> requestReview() async {
    if (Platform.isIOS) {
      final shown = await _channel.invokeMethod<bool>('requestReview');
      return shown ?? false;
    }
    await InAppReview.instance.requestReview();
    return true;
  }
}

/// Decides whether to ask for a review, and asks at most once per install.
///
/// Two things worth knowing about the platform dialog:
///
///  * iOS decides whether to actually draw it. It is rate limited (a handful of
///    times a year) and simply does nothing when it declines, with no callback
///    and no error. So "we asked" is the only signal available.
///  * The stars and Submit are handled entirely by iOS. Tapping Submit posts
///    the rating; it does not navigate anywhere, and the app is never told what
///    the user chose.
class ReviewPrompter {
  const ReviewPrompter({
    this.launcher = const StoreKitReviewLauncher(),
  });

  final ReviewLauncher launcher;

  /// How long after the main screen appears to wait before asking, so the
  /// prompt lands on a populated screen rather than over a loading one.
  static const settleDelay = Duration(seconds: 3);

  /// Shows the prompt if this device has never been asked.
  ///
  /// Returns true when a request was actually made. Marks the flag first, so a
  /// crash or a fast app switch straight after cannot cause a second ask.
  Future<bool> maybePrompt(AppState app) async {
    if (app.hasShownReviewPrompt) return false;

    // Only ask once the user is past first-run and into the app proper.
    if (!app.onboardingComplete) return false;

    try {
      if (!await launcher.isAvailable()) return false;

      await app.markReviewPromptShown();
      return await launcher.requestReview();
    } catch (e) {
      // A store that will not talk to us is not worth bothering the user over,
      // and never worth crashing a launch.
      debugPrint('[PulseScore] review prompt unavailable: $e');
      return false;
    }
  }
}
