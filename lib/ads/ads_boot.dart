import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../const.dart';
import 'ads_tuning.dart';
import 'src/multi_ads_factory.dart';

/// Empty config: every format falls through to `NoAds`. Also what tests seed
/// [gAds] with, since it needs no I/O.
const kEmptyAdsConfig =
    '{"ads":{"admob":{},"applovin":{},"settings":{"banners":[],"inters":[],'
    '"nativees":[],"rewards":[],"openads":""}}}';

/// Reads the ads config and brings [gAds] up.
///
/// Prefers the remote config when [Constants.jsonConfigUrl] is set, so ad units
/// can change without an app update; otherwise the bundled `weather.json` is
/// used. Never throws: ads must not be able to stop the app from starting.
bool _booted = false;
Future<void>? _bootFuture;

/// Completes once the config has loaded and the first round of ads has been
/// fetched.
///
/// The splash only waits a few seconds for [bootAds] before moving on, so on a
/// cold first launch the app-open ad is usually still in flight when the first
/// screen appears. Anything that wants to *show* an ad waits on this instead of
/// firing on the first frame, which would find nothing loaded.
Future<void> adsReady() => _bootFuture ?? Future<void>.value();

/// Sets [gAds] from [json] without any I/O, and stops [bootAds] from going to
/// the network afterwards. Widget tests run in a fake-async zone where a real
/// HTTP or asset read never completes.
@visibleForTesting
void seedAds([String json = kEmptyAdsConfig]) {
  adsTuning = AdsTuning.fromConfig(json);
  gAds = MultiAds(json);
  isInterShowed = false;
  _booted = true;
  _bootFuture = Future<void>.value();
}

Future<void> bootAds() {
  if (_booted) return Future<void>.value();
  return _bootFuture ??= _boot();
}

Future<void> _boot() async {
  String jsonData = kEmptyAdsConfig;

  if (Constants.jsonConfigUrl.isNotEmpty) {
    try {
      final response = await http.get(Uri.parse(Constants.jsonConfigUrl));
      if (response.statusCode == 200) {
        json.decode(response.body);
        jsonData = response.body;
      } else {
        jsonData = await _bundled();
      }
    } catch (_) {
      jsonData = await _bundled();
    }
  } else {
    jsonData = await _bundled();
  }

  adsTuning = AdsTuning.fromConfig(jsonData);
  try {
    gAds = MultiAds(jsonData);
    await gAds.init();
    await gAds.loadAds();
  } catch (_) {
    gAds = MultiAds(kEmptyAdsConfig);
  }
  isInterShowed = false;
  _booted = true;
}

Future<String> _bundled() async {
  try {
    final raw = await rootBundle.loadString(Constants.jsonConfigAsset);
    json.decode(raw);
    return raw;
  } catch (_) {
    return kEmptyAdsConfig;
  }
}
