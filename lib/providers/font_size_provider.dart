import 'package:flutter/material.dart';

class FontSizeProvider extends ChangeNotifier {
  // Default values
  double _fontSize = 16.0;
  String _fontSizeName = 'Medium';

  // Getters
  double get fontSize => _fontSize;
  String get fontSizeName => _fontSizeName;

  // Method to update font size
  void updateFontSize(double size, String name) {
    _fontSize = size;
    _fontSizeName = name;
    notifyListeners(); // Notify all listeners about the change
  }
}