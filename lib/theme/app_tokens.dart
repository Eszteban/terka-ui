import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // A márka alapköve (Material 3 Seed)
  static const Color seed = Color(0xFF8D4B20);
  static const Color white = Color(0xFFFFFFFF);

  // --- VILÁGOS MÓD (Light Mode Tokens) ---
  static const Color lightScaffoldBackground = Color(0xFFF8F1E8);
  static const Color lightNavbarBackground = Color(0xFFF1E0CF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEFE5DA);

  // --- PRÉMIUM SÖTÉT MÓD (Dark Mode Tokens) ---
  // A korábbi barna helyett egy mély, éjfekete-antracit hibrid, minimális meleg tónussal
  static const Color darkScaffoldBackground = Color(0xFF110F0E); 
  static const Color darkSurface = Color(0xFF1A1615); // A kártyák háttérszíne (finoman kiemelkedik)
  static const Color darkSurfaceVariant = Color(0xFF26201E); // Még egy réteggel feljebb (pl. gombok)
  static const Color darkOnSurface = Color(0xFFEFEAE6); // Tiszta, de nem vakító szövegszín

  // --- DRAWER GRADIENT ---
  static const Color drawerGradientStart = Color(0xFF3E2723);
  static const Color drawerGradientMiddle = Color(0xFF6D3E1F);
  static const Color drawerGradientEnd = Color(0xFF8D4B20);

  // --- VEHICLE CARD TOKENS ---
  static const Color darkVehicleCardBackground = Color(0xFF161413);
  static const Color darkVehicleCardActionText = Color(0xFFD6A280);
  static const Color lightVehicleCardBackground = Color(0xFFFFFFFF);
  static const Color lightVehicleCardActionText = seed;

  static Color getVehicleCardBackground(BuildContext context) =>
      _isDarkMode(context) ? darkVehicleCardBackground : lightVehicleCardBackground;

  static Color getVehicleCardActionText(BuildContext context) =>
      _isDarkMode(context) ? darkVehicleCardActionText : lightVehicleCardActionText;

  // Dinamikus elérés kontextus alapján (Így a widgetjeidben nem kell if-ezni!)
  static bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color getScaffoldBackground(BuildContext context) =>
      _isDarkMode(context) ? darkScaffoldBackground : lightScaffoldBackground;

  static Color getSurface(BuildContext context) =>
      _isDarkMode(context) ? darkSurface : lightSurface;

  static Color getSurfaceVariant(BuildContext context) =>
      _isDarkMode(context) ? darkSurfaceVariant : lightSurfaceVariant;
}

class AppFontSizes {
  const AppFontSizes._();

  // Megnöveltük a kontrasztot a címek és a törzsszöveg között
  static const double body = 15;
  static const double title = 18;
  static const double sectionTitle = 24; // 22-ről 24-re, hogy jobban üssön
  static const double drawerHeader = 28; // Nagyobb, magazin-szerűbb címsor
}

class AppSpacing {
  const AppSpacing._();

  // A Material 3 a "levegősebb" tereket szereti. 
  // Megemeltük a közepes és nagy térközöket, hogy ne legyen zsúfolt a UI.
  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;     // 6 -> 8
  static const double md = 12;    // 8 -> 12 (Ez a kártyák belső paddingja)
  static const double lg = 16;    // 12 -> 16 (Kártyák közötti távolság)
  static const double xl = 24;    // 16 -> 24 (Képernyő széle margó!)
  static const double xxl = 36;   // 24 -> 36
  static const double touchTarget = 48;
  static const double dropdownOffset = 40;
  static const double formMaxWidth = 500;
}