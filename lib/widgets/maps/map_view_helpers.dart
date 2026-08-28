part of 'map_view.dart';

extension _MapViewHelpers on _MapViewState {
  Color _vehicleColor(String mode) {
    return TransitColorResolver.fallbackColorForMode(mode);
  }

  Color _parseRouteColor(String rawHex, {required String mode}) {
    final hex = rawHex.trim().replaceAll('#', '').toUpperCase();
    if (_MapViewState._fallbackWhiteHexColors.contains(hex)) {
      return hex == 'FEFEFE' ? const Color(0xFFFEFEFE) : AppColors.white;
    }
    return TransitColorResolver.resolveRouteColor(
      rawHex: rawHex,
      mode: mode,
      fallback: _vehicleColor(mode),
    );
  }

  Color _parseTextColor(String rawHex) {
    return ColorUtils.parseHex(rawHex, fallback: AppColors.white);
  }

  String _normalizedStopGroupName(String name) {
    return _plainTextFromHtml(name).trim().toLowerCase();
  }

  bool _containsSpanMarkup(String value) {
    return containsSpanMarkup(value);
  }

  String _todayServiceDate() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  String _plainTextFromHtml(String input) {
    return plainTextFromHtml(input);
  }
}
