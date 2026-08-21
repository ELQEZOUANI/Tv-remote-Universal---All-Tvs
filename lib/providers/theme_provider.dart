import 'package:flutter/foundation.dart';

/// Manages the app-wide light/dark theme toggle.
class ThemeProvider extends ChangeNotifier {
  bool _isDark = false; // light mode is the app default

  bool get isDark => _isDark;

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
