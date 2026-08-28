import 'package:flutter_test/flutter_test.dart';
import 'package:terka/core/config/app_config.dart';

void main() {
  group('AppConfig Carto tile URLs', () {
    test('cartoSubdomains contains a, b, c, d', () {
      expect(AppConfig.cartoSubdomains, equals(['a', 'b', 'c', 'd']));
    });

    test('default URLs do not contain key parameter when cartoApiKey is empty', () {
      if (AppConfig.cartoApiKey.isEmpty) {
        expect(AppConfig.cartoDarkTileUrl,
            equals('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png'));
        expect(AppConfig.cartoLightTileUrl,
            equals('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png'));
        expect(AppConfig.cartoTileCheckUrl,
            equals('https://a.basemaps.cartocdn.com/dark_all/0/0/0.png'));
      }
    });

    test('getCartoTileUrl selects the correct style based on isDark flag', () {
      expect(AppConfig.getCartoTileUrl(isDark: true), equals(AppConfig.cartoDarkTileUrl));
      expect(AppConfig.getCartoTileUrl(isDark: false), equals(AppConfig.cartoLightTileUrl));
    });

    test('buildCartoTileUrl preserves base URL when API key is empty', () {
      if (AppConfig.cartoApiKey.isEmpty) {
        const testUrl = 'https://example.com/tiles/{z}/{x}/{y}.png';
        expect(AppConfig.buildCartoTileUrl(testUrl), equals(testUrl));
      }
    });

    test('tile URLs contain ?key= when cartoApiKey is present', () {
      if (AppConfig.cartoApiKey.isNotEmpty) {
        expect(AppConfig.cartoDarkTileUrl,
            equals('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png?key=${AppConfig.cartoApiKey}'));
        expect(AppConfig.cartoLightTileUrl,
            equals('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png?key=${AppConfig.cartoApiKey}'));
        expect(AppConfig.cartoTileCheckUrl,
            equals('https://a.basemaps.cartocdn.com/dark_all/0/0/0.png?key=${AppConfig.cartoApiKey}'));
      }
    });
  });
}
