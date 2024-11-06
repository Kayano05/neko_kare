import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LanguageService {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  static const String _languageKey = 'selected_language';
  
  final List<Locale> supportedLocales = [
    const Locale('en'), // 英语
    const Locale('ja'), // 日语
    const Locale('de'), // 德语
    const Locale('zh'), // 中文
  ];

  Future<Locale> getSelectedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'zh';
    return Locale(languageCode);
  }

  Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }
} 