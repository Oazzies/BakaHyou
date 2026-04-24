import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  Map<String, dynamic> _languageData = {};
  String _currentLanguage = 'en';

  Future<void> init() async {
    try {
      final jsonString = await rootBundle.loadString('assets/lang/languages.json');
      _languageData = json.decode(jsonString);
      // Set to English by default if not set
      _currentLanguage = _languageData.containsKey('en') ? 'en' : _languageData.keys.first;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading localization data: $e');
    }
  }

  void setLanguage(String langCode) {
    if (_languageData.containsKey(langCode)) {
      _currentLanguage = langCode;
      notifyListeners();
    }
  }

  String get currentLanguage => _currentLanguage;

  Map<String, dynamic> get currentLanguageData => _languageData[_currentLanguage] ?? {};

  List<Map<String, dynamic>> getLanguages() {
    return _languageData.entries.map((e) {
      return {
        'code': e.key,
        'name': e.value['name'] ?? e.key,
        'translators': List<String>.from(e.value['translators'] ?? []),
      };
    }).toList();
  }

  String translate(String key) {
    if (_languageData.isEmpty || !_languageData.containsKey(_currentLanguage)) {
      return key; // Fallback to key
    }
    
    final strings = _languageData[_currentLanguage]['strings'] as Map<String, dynamic>?;
    return strings?[key] ?? key;
  }
}
