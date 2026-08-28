import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // A márka alapköve (Material 3 Seed)
  static const Color seed = Color(0xFF8D4B20);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // Standard Material színreferenciák (legacy támogatás)
  static const MaterialColor grey = Colors.grey;
  static const MaterialColor red = Colors.red;
  static const MaterialColor green = Colors.green;
  static const MaterialColor blue = Colors.blue;
  static const MaterialColor orange = Colors.orange;
  static const MaterialColor amber = Colors.amber;
  static const MaterialColor teal = Colors.teal;
  static const MaterialColor deepPurple = Colors.deepPurple;

  // --- VILÁGOS MÓD FELÜLETI SZÍNEK (Light Mode Surface Tokens) ---
  static const Color lightScaffoldBackground = Color(0xFFF8F1E8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainer = Color(0xFFF1E0CF);
  static const Color lightSurfaceContainerHigh = Color(0xFFEBE0D2);
  static const Color lightSurfaceContainerHighest = Color(0xFFE5D5C3);
  static const Color lightOnSurface = Color(0xFF201A17);
  static const Color lightOnSurfaceVariant = Color(0xFF52443C);
  static const Color lightOutline = Color(0xFF84746A);
  static const Color lightOutlineVariant = Color(0xFFD7C2B4);

  // --- PRÉMIUM SÖTÉT MÓD FELÜLETI SZÍNEK (Dark Mode Surface Tokens) ---
  // Mély éjfekete-antracit hibrid, minimális meleg tónussal
  static const Color darkScaffoldBackground = Color(0xFF110F0E);
  static const Color darkSurface = Color(0xFF161413);
  static const Color darkSurfaceContainerLowest = Color(0xFF1A1615); // Kártyák háttérszíne
  static const Color darkSurfaceContainer = Color(0xFF201C1A);
  static const Color darkSurfaceContainerHigh = Color(0xFF26201E); // Gombok / emelt elemek
  static const Color darkSurfaceContainerHighest = Color(0xFF322B28);
  static const Color darkOnSurface = Color(0xFFEFEAE6); // Tiszta szövegszín
  static const Color darkOnSurfaceVariant = Color(0xFFD6C3B7);
  static const Color darkOutline = Color(0xFF9F8D83);
  static const Color darkOutlineVariant = Color(0xFF52443C);

  // Dinamikus elérés kontextus alapján
  static bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color getScaffoldBackground(BuildContext context) =>
      _isDarkMode(context) ? darkScaffoldBackground : lightScaffoldBackground;

  static Color getSurface(BuildContext context) =>
      _isDarkMode(context) ? darkSurface : lightSurface;

  static Color getSurfaceVariant(BuildContext context) =>
      _isDarkMode(context) ? darkSurfaceContainerHigh : lightSurfaceContainerHigh;
}

class AppFontSizes {
  const AppFontSizes._();

  static const double body = 15;
  static const double title = 18;
  static const double sectionTitle = 24;
  static const double drawerHeader = 28;
}

class AppSpacing {
  const AppSpacing._();

  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 36;
  static const double touchTarget = 48;
  static const double dropdownOffset = 40;
  static const double formMaxWidth = 500;
}