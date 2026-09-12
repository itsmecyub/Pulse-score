import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_score/ads/ads_tuning.dart';

/// The config as it actually ships: no `tuning` block at all.
const _withoutTuning = '''
{"ads":{"admob":{"openAdsIds":"unit/open"},"settings":{"banners":"admob"}}}
''';

String _withTuning(String tuning) =>
    '{"ads":{"admob":{},"settings":{},"tuning":$tuning}}';

void main() {
  group('a config with no tuning block', () {
    test('keeps the behaviour the ads module shipped with', () {
      final t = AdsTuning.fromConfig(_withoutTuning);
      expect(t.interClicks, 2, reason: 'an interstitial every second tap');
      expect(t.openOnStart, isTrue);
      expect(t.openOnResume, isTrue);
      expect(t.bannerEnabled, isTrue);
    });

    test('survives anything that is not a usable config', () {
      for (final raw in ['', 'not json', '[]', '{}', '{"ads":"nope"}']) {
        final t = AdsTuning.fromConfig(raw);
        expect(t.interClicks, 2, reason: 'fell back for: $raw');
        expect(t.bannerEnabled, isTrue);
      }
    });
  });

  group('the tuning block', () {
    test('changes how often an interstitial appears', () {
      expect(AdsTuning.fromConfig(_withTuning('{"inter_clicks":5}')).interClicks,
          5);
      // Values arrive as strings from a hand-edited config just as often.
      expect(AdsTuning.fromConfig(_withTuning('{"inter_clicks":"3"}'))
          .interClicks, 3);
    });

    test('switches the app-open and banner placements off', () {
      final t = AdsTuning.fromConfig(_withTuning(
          '{"open_on_start":false,"open_on_resume":"0","banner":"no"}'));
      expect(t.openOnStart, isFalse);
      expect(t.openOnResume, isFalse);
      expect(t.bannerEnabled, isFalse);
    });

    test('takes each key on its own, leaving the rest at their defaults', () {
      final t = AdsTuning.fromConfig(_withTuning('{"banner":false}'));
      expect(t.bannerEnabled, isFalse);
      expect(t.interClicks, 2);
      expect(t.openOnStart, isTrue);
    });

    test('ignores a blank or unreadable value rather than turning ads off', () {
      final t = AdsTuning.fromConfig(
          _withTuning('{"banner":"","inter_clicks":"abc"}'));
      expect(t.bannerEnabled, isTrue);
      expect(t.interClicks, 2);
    });
  });

  test('zero clicks stops interstitials entirely', () {
    expect(AdsTuning.fromConfig(_withTuning('{"inter_clicks":0}')).interClicks,
        0);
  });
}
