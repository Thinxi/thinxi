import 'package:translator/translator.dart';

class TranslationService {
  static final GoogleTranslator translator = GoogleTranslator();

  static Future<String> translate(String text, String targetLang) async {
    final translation = await translator.translate(text, to: targetLang);
    return translation.text;
  }
}
