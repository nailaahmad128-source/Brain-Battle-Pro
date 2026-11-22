import 'package:flutter/widgets.dart';
import 'strings.dart';

export 'strings.dart' show kLanguages;

/// Native display name of a language code (for the language picker).
String langName(String code) =>
    kLanguages.firstWhere((l) => l.$1 == code, orElse: () => kLanguages.first).$2;

/// Looks up [key] (English text) in [code]'s table; falls back to English.
/// `{name}` placeholders are replaced from [args].
String trFor(String code, String key, [Map<String, Object>? args]) {
  var s = kStrings[code]?[key] ?? key;
  if (args != null) {
    args.forEach((k, v) {
      s = s.replaceAll('{$k}', '$v');
    });
  }
  return s;
}

extension TrContext on BuildContext {
  /// Translated text. Depends on the app locale, so widgets using it rebuild
  /// automatically when the user switches language.
  String tr(String key, [Map<String, Object>? args]) =>
      trFor(Localizations.localeOf(this).languageCode, key, args);
}
