import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krishikranti/core/dynamic_translation_service.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? languageCode = prefs.getString('language_code');
      debugPrint('[LanguageService] Loaded locale from preferences: $languageCode');
      if (languageCode != null) {
        _instance._locale = Locale(languageCode);
        // Sync translation service safely in background
        _instance._syncTranslation(languageCode);
      }
    } catch (e) {
      debugPrint('[LanguageService] Error initializing locale: $e');
    }
  }

  Future<void> _syncTranslation(String languageCode) async {
    try {
      debugPrint('[LanguageService] Syncing translation service with: $languageCode');
      await DynamicTranslationService().onLocaleChanged(languageCode);
    } catch (e) {
      debugPrint('[LanguageService] Error syncing translation: $e');
    }
  }

  Future<void> setLocale(String languageCode) async {
    if (_locale.languageCode == languageCode) return;

    _locale = Locale(languageCode);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', languageCode);
      // Sync translation service safely in background
      _syncTranslation(languageCode);
    } catch (e) {
      debugPrint('[LanguageService] Error saving locale: $e');
    }
  }
}
