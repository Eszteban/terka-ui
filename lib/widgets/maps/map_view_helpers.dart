part of 'map_view.dart';

extension _MapViewHelpers on _MapViewState {
  Color _vehicleColor(String mode) {
    switch (mode) {
      case 'RAIL':
      case 'SUBURBAN_RAILWAY':
      case 'TRAMTRAIN':
      case 'RAIL_REPLACEMENT_BUS':
        return Colors.blueAccent;
      case 'COACH':
        return Colors.deepPurple;
      case 'SUBWAY':
      case 'TRAM':
      case 'TROLLEYBUS':
      case 'BUS':
      case 'FERRY':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Color _parseRouteColor(String rawHex, {required String mode}) {
    final hex = rawHex.trim().replaceAll('#', '').toUpperCase();
    if (_MapViewState._fallbackWhiteHexColors.contains(hex)) {
      return hex == 'FEFEFE' ? const Color(0xFFFEFEFE) : Colors.white;
    }
    final normalized = switch (hex.length) {
      3 => '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}',
      6 => hex,
      8 => hex.substring(2),
      _ => '',
    };
    if (normalized.isEmpty) {
      return _vehicleColor(mode);
    }

    final value = int.tryParse(normalized, radix: 16);
    if (value == null) {
      return _vehicleColor(mode);
    }
    return Color(0xFF000000 | value);
  }

  Color _parseTextColor(String rawHex) {
    final hex = rawHex.trim().replaceAll('#', '').toUpperCase();
    final normalized = switch (hex.length) {
      3 => '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}',
      6 => hex,
      8 => hex.substring(2),
      _ => '',
    };
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) {
      return Colors.white;
    }
    return Color(0xFF000000 | value);
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
