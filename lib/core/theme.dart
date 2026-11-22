import 'package:flutter/material.dart';

class C {
  static const bg = Color(0xFF0B0A14);
  static const surface = Color(0xFF15132A);
  static const purple = Color(0xFF8B5CF6);
  static const cyan = Color(0xFF22D3EE);
  static const pink = Color(0xFFF472B6);
  static const gold = Color(0xFFFBBF24);
  static const green = Color(0xFF34D399);
  static const red = Color(0xFFF87171);
  static const text = Color(0xFFF4F3FF);
  static const muted = Color(0xFF9A98B8);
  static const brand = LinearGradient(
    colors: [purple, cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: C.bg,
      colorScheme: const ColorScheme.dark(
        primary: C.purple,
        secondary: C.cyan,
        surface: C.surface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: C.surface,
        indicatorColor: C.purple.withValues(alpha: 0.35),
        labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
