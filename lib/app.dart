import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_screen.dart';
import 'theme/app_tokens.dart';
import 'theme/app_texts.dart';

class TerkaApp extends StatefulWidget {
  const TerkaApp({super.key});

  @override
  State<TerkaApp> createState() => _TerkaAppState();
}

class _TerkaAppState extends State<TerkaApp> {
  static const String _themeModePreferenceKey = 'theme_mode';
  static const String _languagePreferenceKey = 'language';

  ThemeMode _themeMode = ThemeMode.system;
  AppLanguage _language = AppLanguage.hu;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final rawLang = prefs.getString(_languagePreferenceKey);
    if (rawLang == 'en') {
      setState(() {
        _language = AppLanguage.en;
        AppTexts.setLanguage(AppLanguage.en);
      });
    } else {
      setState(() {
        _language = AppLanguage.hu;
        AppTexts.setLanguage(AppLanguage.hu);
      });
    }
  }

  Future<void> _setLanguage(AppLanguage lang) async {
    if (_language == lang) {
      return;
    }
    setState(() {
      _language = lang;
      AppTexts.setLanguage(lang);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languagePreferenceKey, lang == AppLanguage.en ? 'en' : 'hu');
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

    setState(() {
      _themeMode = resolvedMode;
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }

    setState(() {
      _themeMode = mode;
    });

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

    return MaterialApp(
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
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      home: MainScreen(
        selectedThemeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
        selectedLanguage: _language,
        onLanguageChanged: _setLanguage,
      ),
    );
  }
}

