import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _colorKey = 'primary_theme_color';
  
  // Default Kiosly Green: 0xFF1B5E20
  Color _primaryColor = const Color(0xFF1B5E20);

  Color get primaryColor => _primaryColor;

  ThemeProvider() {
    _loadThemeColor();
  }

  Future<void> _loadThemeColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorVal = prefs.getInt(_colorKey);
    if (colorVal != null) {
      _primaryColor = Color(colorVal);
      notifyListeners();
    }
  }

  Future<void> setThemeColor(Color color) async {
    _primaryColor = color;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorKey, color.value);
  }
}
