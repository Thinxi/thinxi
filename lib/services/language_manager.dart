import 'package:flutter/material.dart';

class LanguageManager extends ChangeNotifier {
  String _languageCode = 'en';

  String get currentLang => _languageCode;

  void setLanguage(String lang) {
    _languageCode = lang;
    notifyListeners();
  }
}
