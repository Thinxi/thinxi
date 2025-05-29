import 'package:flutter/material.dart';

class LanguageManager with ChangeNotifier {
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;

  void setLanguage(String langCode) {
    _currentLanguage = langCode;
    notifyListeners();
  }

  bool isEnglish() {
    return _currentLanguage == 'en';
  }

  bool isPersian() {
    return _currentLanguage == 'fa';
  }
}
