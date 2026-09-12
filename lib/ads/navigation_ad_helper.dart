import 'package:flutter/material.dart';

import '../const.dart';
import 'ads_tuning.dart';

/// Global click counter shared across every button in the app.
int _adClickCount = 0;

/// Call this on every meaningful button tap. An interstitial is shown on every
/// Nth click — `tuning.inter_clicks` in the config, 2 by default — so ads feel
/// natural and never fire on every single interaction.
void maybeShowInterstitialAd() {
  final every = adsTuning.interClicks;
  if (every <= 0) return;
  _adClickCount++;
  if (_adClickCount % every == 0) {
    gAds.interInstance.showInterstitialAd();
  }
}

/// Same cadence as [maybeShowInterstitialAd], but also navigates to the
/// next screen after (maybe) showing the ad.
Future<T?> showInterstitialThenPush<T>(
  BuildContext context,
  WidgetBuilder pageBuilder,
) {
  final navigator = Navigator.of(context);
  maybeShowInterstitialAd();
  return navigator.push<T>(MaterialPageRoute(builder: pageBuilder));
}
