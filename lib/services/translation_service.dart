import 'package:translator/translator.dart';

class TranslationService {
  static final GoogleTranslator _translator = GoogleTranslator();
  static final Map<String, String> _cache = {};

  static Future<String> t(String key, String lang) async {
    final cacheKey = '$key-$lang';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final translation = await _translator.translate(key, to: lang);
    _cache[cacheKey] = translation.text;
    return translation.text;
  }
}
