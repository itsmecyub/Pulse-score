import 'dart:ui';

import 'package:pulse_score/ads/src/multi_ads_factory.dart';

import 'core/theme/app_colors.dart';

class Constants {
  /// Direct-download link to the ads config on Drive, the same way the other
  /// apps are wired: ad units and the per-format network choice can change
  /// without shipping an update.
  static const jsonConfigUrl =
      'https://drive.google.com/uc?export=download&id=1zLBTp68QNViNfGQTDy79WaiATEdMLOul';

  /// Bundled copy, used only when the remote config cannot be reached.
  static const jsonConfigAsset = 'assets/weather.json';

  static Color mainColor = AppColors.green;
}

late MultiAds gAds;
late bool isInterShowed;
