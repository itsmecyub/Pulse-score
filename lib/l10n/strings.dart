import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'translations.dart';

/// Resolves a UI key for the active language, falling back to English.
class Strings {
  const Strings(this.code);

  final String code;

  String call(String key) =>
      kTranslations[code]?[key] ?? kTranslations['en']![key] ?? key;

  bool get isRtl => code == 'ar';

  TextDirection get direction =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;
}

extension StringsX on BuildContext {
  /// `context.s('tab_live')` — watches the locale so switching language
  /// rebuilds every screen holding a reference.
  String s(String key) => Strings(watch<AppState>().languageCode)(key);

  Strings get strings => Strings(watch<AppState>().languageCode);
}
