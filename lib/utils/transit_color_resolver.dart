import 'package:flutter/material.dart';

/// Általános színszámítási és hex-konverziós segédosztály.
class ColorUtils {
  const ColorUtils._();

  /// Biztonságos hex színbeolvasás.
  /// Támogatja a 3, 6 és 8 karakteres hex formátumokat (# jellel vagy anélkül).
  static Color? tryParseHex(String? rawHex) {
    if (rawHex == null) return null;
    final hex = rawHex.trim().replaceAll('#', '').toUpperCase();
    if (hex.isEmpty) return null;

    final normalized = switch (hex.length) {
      3 => '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}',
      6 => hex,
      8 => hex.substring(2),
      _ => null,
    };

    if (normalized == null) return null;
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return null;

    return Color(0xFF000000 | value);
  }

  /// Hex szín beolvasása alapértelmezett fallback színnel.
  static Color parseHex(
    String? rawHex, {
    Color fallback = const Color(0xFF8D4B20),
  }) {
    return tryParseHex(rawHex) ?? fallback;
  }

  /// Ellenőrzi, hogy egy szín fehér vagy közel fehér-e.
  static bool isNearWhite(Color color) {
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);
    return (r >= 250 && g >= 250 && b >= 250) || color.computeLuminance() > 0.92;
  }

  /// Optimális, nagy kontrasztú szövegszín (fekete/fehér) egy háttérszínhez.
  static Color contrastTextColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.45
        ? const Color(0xFF110F0E)
        : const Color(0xFFFFFFFF);
  }
}

/// A járat badge (jelvény) stílusát leíró adatosztály.
class TransitBadgeStyle {
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  const TransitBadgeStyle({
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });
}

/// Központosított tranzit-, vonal- és járatszín feloldó segédosztály.
class TransitColorResolver {
  const TransitColorResolver._();

  /// Fallback szín közlekedési mód (GTFS mode) szerint.
  static Color fallbackColorForMode(String? mode) {
    switch (mode?.toUpperCase()) {
      case 'RAIL':
      case 'SUBURBAN_RAILWAY':
      case 'TRAMTRAIN':
      case 'RAIL_REPLACEMENT_BUS':
        return const Color(0xFF1976D2); // Kék
      case 'COACH':
        return const Color(0xFF7B1FA2); // Lila
      case 'SUBWAY':
      case 'TRAM':
      case 'TROLLEYBUS':
      case 'BUS':
      case 'FERRY':
        return const Color(0xFF00897B); // Teal
      default:
        return const Color(0xFF757575); // Szürke
    }
  }

  /// Járat színének feloldása hex szövegből vagy közlekedési módból.
  static Color resolveRouteColor({
    String? rawHex,
    String? mode,
    Color? fallback,
  }) {
    if (rawHex != null && rawHex.trim().isNotEmpty) {
      final parsed = ColorUtils.tryParseHex(rawHex);
      if (parsed != null) return parsed;
    }
    if (mode != null && mode.isNotEmpty) {
      return fallbackColorForMode(mode);
    }
    return fallback ?? const Color(0xFF1976D2);
  }

  /// Járat jelvény (badge) színeinek és kontrasztjának feloldása téma szerint.
  static TransitBadgeStyle resolveBadgeStyle(
    Color routeColor, {
    required bool isDark,
  }) {
    if (ColorUtils.isNearWhite(routeColor)) {
      if (isDark) {
        return const TransitBadgeStyle(
          backgroundColor: Color(0xFF26201E),
          textColor: Color(0xFFEFEAE6),
          borderColor: Color(0xFF52443C),
        );
      } else {
        return const TransitBadgeStyle(
          backgroundColor: Color(0xFFFFFFFF),
          textColor: Color(0xFF201A17),
          borderColor: Color(0xFFD7C2B4),
        );
      }
    }

    final textColor = ColorUtils.contrastTextColor(routeColor);
    final borderColor = isDark
        ? Color.lerp(routeColor, Colors.white, 0.2)!
        : Color.lerp(routeColor, Colors.black, 0.15)!;

    return TransitBadgeStyle(
      backgroundColor: routeColor,
      textColor: textColor,
      borderColor: borderColor,
    );
  }

  /// Útvonaltervező szakasz (Leg) dobozának háttér- és keretszíne.
  static ({Color backgroundColor, Color borderColor, Color textColor}) resolveLegStyle({
    required Color routeColor,
    required bool isDark,
    bool isWalk = false,
  }) {
    if (isWalk) {
      final bg = isDark ? const Color(0xFF26201E) : const Color(0xFFEFE5DA);
      final border = isDark ? const Color(0xFF3E332E) : const Color(0xFFD7C2B4);
      final text = isDark ? const Color(0xFFD6C3B7) : const Color(0xFF52443C);
      return (backgroundColor: bg, borderColor: border, textColor: text);
    }

    final bg = isDark
        ? Color.lerp(const Color(0xFF161413), routeColor, 0.22)!
        : Color.lerp(const Color(0xFFFFFFFF), routeColor, 0.12)!;

    final border = isDark
        ? Color.lerp(const Color(0xFF1A1615), routeColor, 0.45)!
        : Color.lerp(const Color(0xFFEFE5DA), routeColor, 0.35)!;

    final text = isDark ? const Color(0xFFEFEAE6) : const Color(0xFF201A17);

    return (backgroundColor: bg, borderColor: border, textColor: text);
  }
}
