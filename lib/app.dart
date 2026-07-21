import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'screens/main/main_screen.dart';
import 'theme/app_tokens.dart';
import 'utils/layout_provider.dart';
import 'theme/app_texts.dart';

enum AppLayoutMode { mobile, automatic, tablet }

class TerkaApp extends StatefulWidget {
  const TerkaApp({super.key});

  @override
  State<TerkaApp> createState() => _TerkaAppState();
}

const bool forceTabletLayout = bool.fromEnvironment('FORCE_TABLET_LAYOUT', defaultValue: false);

class _TerkaAppState extends State<TerkaApp> {
  static const String _themeModePreferenceKey = 'theme_mode';
  static const String _languagePreferenceKey = 'language';
  static const String _layoutModePreferenceKey = 'layout_mode';

  final ValueNotifier<ThemeMode> _themeMode = ValueNotifier(ThemeMode.system);
  final ValueNotifier<AppLanguage> _language = ValueNotifier(AppLanguage.hu);
  final ValueNotifier<AppLayoutMode> _layoutMode = ValueNotifier(forceTabletLayout ? AppLayoutMode.tablet : AppLayoutMode.automatic);

  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _loadLanguage();
    _loadLayoutMode();
    _router = AppRouter.createRouter(
      themeModeNotifier: _themeMode,
      onThemeModeChanged: _setThemeMode,
      languageNotifier: _language,
      onLanguageChanged: _setLanguage,
      layoutModeNotifier: _layoutMode,
      onLayoutModeChanged: _setLayoutMode,
    );
  }

  @override
  void dispose() {
    _themeMode.dispose();
    _language.dispose();
    _layoutMode.dispose();
    super.dispose();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final rawLang = prefs.getString(_languagePreferenceKey);
    if (rawLang == 'en') {
      _language.value = AppLanguage.en;
      AppTexts.setLanguage(AppLanguage.en);
    } else {
      _language.value = AppLanguage.hu;
      AppTexts.setLanguage(AppLanguage.hu);
    }
  }

  Future<void> _setLanguage(AppLanguage lang) async {
    if (_language.value == lang) {
      return;
    }
    _language.value = lang;
    AppTexts.setLanguage(lang);
    
    // We still need to rebuild TerkaApp for localization updates
    setState(() {});
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languagePreferenceKey, lang == AppLanguage.en ? 'en' : 'hu');
  }

  Future<void> _loadLayoutMode() async {
    if (forceTabletLayout) return;
    
    final prefs = await SharedPreferences.getInstance();
    final rawMode = prefs.getString(_layoutModePreferenceKey);
    if (rawMode == null) {
      return;
    }

    final resolvedMode = _layoutModeFromString(rawMode);
    if (!mounted) {
      return;
    }

    _layoutMode.value = resolvedMode;
  }

  Future<void> _setLayoutMode(AppLayoutMode mode) async {
    if (forceTabletLayout) return;
    
    if (_layoutMode.value == mode) {
      return;
    }

    _layoutMode.value = mode;
    // Layout changes might need app-level rebuilds
    setState(() {});

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_layoutModePreferenceKey, _layoutModeToString(mode));
  }

  AppLayoutMode _layoutModeFromString(String value) {
    switch (value) {
      case 'mobile':
        return AppLayoutMode.mobile;
      case 'tablet':
        return AppLayoutMode.tablet;
      case 'automatic':
      default:
        return AppLayoutMode.automatic;
    }
  }

  String _layoutModeToString(AppLayoutMode mode) {
    switch (mode) {
      case AppLayoutMode.mobile:
        return 'mobile';
      case AppLayoutMode.tablet:
        return 'tablet';
      case AppLayoutMode.automatic:
        return 'automatic';
    }
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final rawMode = prefs.getString(_themeModePreferenceKey);
    if (rawMode == null) {
      return;
    }

    final resolvedMode = _themeModeFromString(rawMode);
    if (!mounted) {
      return;
    }

    _themeMode.value = resolvedMode;
    // Trigger MaterialApp rebuild for theme
    setState(() {});
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    if (_themeMode.value == mode) {
      return;
    }

    _themeMode.value = mode;
    // Trigger MaterialApp rebuild for theme
    setState(() {});

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModePreferenceKey, _themeModeToString(mode));
  }

  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.light,
    );
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
    );

    return MaterialApp.router(
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        scaffoldBackgroundColor: lightColorScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: lightColorScheme.surfaceContainer,
          foregroundColor: lightColorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: lightColorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: lightColorScheme.outlineVariant),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: lightColorScheme.surfaceContainerLowest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: lightColorScheme.primary, width: 1.6),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: lightColorScheme.surfaceContainer,
          indicatorColor: lightColorScheme.secondaryContainer,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontWeight:
                  states.contains(WidgetState.selected)
                      ? FontWeight.w700
                      : FontWeight.w500,
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        scaffoldBackgroundColor: darkColorScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: darkColorScheme.surfaceContainer,
          foregroundColor: darkColorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: darkColorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: darkColorScheme.outlineVariant),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkColorScheme.surfaceContainerLowest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: darkColorScheme.primary, width: 1.6),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: darkColorScheme.surfaceContainer,
          indicatorColor: darkColorScheme.secondaryContainer,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontWeight:
                  states.contains(WidgetState.selected)
                      ? FontWeight.w700
                      : FontWeight.w500,
            ),
          ),
        ),
      ),
      themeMode: _themeMode.value,
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeInOut,
      locale: _language.value == AppLanguage.hu
          ? const Locale('hu')
          : const Locale('en'),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return LayoutProvider(
          mode: _layoutMode.value,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

