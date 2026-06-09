import 'package:flutter/material.dart';

class ThemeController {
  ThemeController._();

  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    ThemeMode.system,
  );

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static void toggle() {
    if (themeMode.value == ThemeMode.dark) {
      themeMode.value = ThemeMode.light;
    } else {
      themeMode.value = ThemeMode.dark;
    }
  }
}
