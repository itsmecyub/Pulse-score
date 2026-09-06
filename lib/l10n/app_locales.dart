import 'package:flutter/widgets.dart';

/// A language offered on the first-run picker.
class AppLocaleOption {
  const AppLocaleOption({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.flag,
  });

  /// Language subtag ("pt" for the Brazilian entry).
  final String code;

  /// Rendered large, in the language's own script.
  final String nativeName;

  /// Rendered small underneath, in mono.
  final String englishName;

  final String flag;

  Locale get locale => Locale(code);
}

/// Order matters — this is the exact order of the picker.
const kSupportedLocales = <AppLocaleOption>[
  AppLocaleOption(code: 'vi', nativeName: 'Tiếng Việt', englishName: 'Vietnamese', flag: '🇻🇳'),
  AppLocaleOption(code: 'hi', nativeName: 'हिन्दी', englishName: 'Hindi', flag: '🇮🇳'),
  AppLocaleOption(code: 'en', nativeName: 'English', englishName: 'English', flag: '🇺🇸'),
  AppLocaleOption(code: 'pt', nativeName: 'Português', englishName: 'Brazil', flag: '🇧🇷'),
  AppLocaleOption(code: 'es', nativeName: 'Español', englishName: 'Spanish', flag: '🇪🇸'),
  AppLocaleOption(code: 'fr', nativeName: 'Français', englishName: 'French', flag: '🇫🇷'),
  AppLocaleOption(code: 'id', nativeName: 'Bahasa Indonesia', englishName: 'Indonesian', flag: '🇮🇩'),
  AppLocaleOption(code: 'ko', nativeName: '한국어', englishName: 'Korean', flag: '🇰🇷'),
  AppLocaleOption(code: 'ja', nativeName: '日本語', englishName: 'Japanese', flag: '🇯🇵'),
  AppLocaleOption(code: 'zh', nativeName: '中文', englishName: 'Chinese', flag: '🇨🇳'),
  AppLocaleOption(code: 'th', nativeName: 'ไทย', englishName: 'Thai', flag: '🇹🇭'),
  AppLocaleOption(code: 'tr', nativeName: 'Türkçe', englishName: 'Turkish', flag: '🇹🇷'),
  AppLocaleOption(code: 'de', nativeName: 'Deutsch', englishName: 'German', flag: '🇩🇪'),
  AppLocaleOption(code: 'ar', nativeName: 'العربية', englishName: 'Arabic', flag: '🇸🇦'),
];

AppLocaleOption localeOptionFor(String code) => kSupportedLocales.firstWhere(
      (l) => l.code == code,
      orElse: () => kSupportedLocales[2],
    );
