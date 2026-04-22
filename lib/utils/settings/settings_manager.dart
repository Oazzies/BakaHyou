import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

enum AppListStyle {
  comfortable,
  compact,
  minimalList,
  grid,
}

class SettingsManager extends ChangeNotifier {
  static final SettingsManager _instance = SettingsManager._internal();
  factory SettingsManager() => _instance;
  SettingsManager._internal();

  static const String _listStyleKey = '${AppConstants.prefixStorageKey}list_style_pref';

  AppListStyle _currentListStyle = AppListStyle.comfortable;
  AppListStyle get currentListStyle => _currentListStyle;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load List Style
    final listStyleIndex = prefs.getInt(_listStyleKey);
    if (listStyleIndex != null && listStyleIndex >= 0 && listStyleIndex < AppListStyle.values.length) {
      _currentListStyle = AppListStyle.values[listStyleIndex];
    }
    
    notifyListeners();
  }

  Future<void> setListStyle(AppListStyle style) async {
    if (_currentListStyle == style) return;
    
    _currentListStyle = style;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_listStyleKey, style.index);
    
    notifyListeners();
  }
}
