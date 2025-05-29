// 📁 lib/services/app_localization.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:translator/translator.dart';
import 'language_manager.dart';

class AppLocalization {
  static final GoogleTranslator _translator = GoogleTranslator();
  static final Map<String, String> _cache = {};

  static Future<String> translate(String text, String lang) async {
    final cacheKey = '$text-$lang';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final translation = await _translator.translate(text, to: lang);
    _cache[cacheKey] = translation.text;
    return translation.text;
  }
}

/// Widget that shows translated text automatically
typedef TranslationTextBuilder = Widget Function(String translatedText);

class T extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TranslationTextBuilder? builder;

  const T(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageManager>(context).currentLang;

    return FutureBuilder<String>(
      future: AppLocalization.translate(text, lang),
      builder: (context, snapshot) {
        final translated = snapshot.data ?? text;
        if (builder != null) return builder!(translated);
        return Text(translated, style: style, textAlign: textAlign);
      },
    );
  }
}

/// Convenience function
textDirectionFromLang(String lang) {
  return (lang == 'fa' || lang == 'ar') ? TextDirection.rtl : TextDirection.ltr;
}

/// Wrapper to apply directionality
class DirectionalWrapper extends StatelessWidget {
  final Widget child;
  const DirectionalWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageManager>(context).currentLang;
    return Directionality(
      textDirection: textDirectionFromLang(lang),
      child: child,
    );
  }
}
