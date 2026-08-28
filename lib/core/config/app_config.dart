/// Alkalmazás szintű konfigurációk és fordítási idejű környezeti változók kezelése.
class AppConfig {
  AppConfig._();

  /// A Carto alaptérképhez használt API kulcs fordítási idejű környezeti változóból.
  static const String cartoApiKey = String.fromEnvironment(
    'CARTO_API_KEY',
    defaultValue: '',
  );

  /// A Carto csempeszerverek aldomainjei terheléselosztáshoz.
  static const List<String> cartoSubdomains = ['a', 'b', 'c', 'd'];

  /// Carto Dark Matter csempe sablon URL.
  static const String _cartoDarkBaseUrl =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png';

  /// Carto Positron (világos) csempe sablon URL.
  static const String _cartoLightBaseUrl =
      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png';

  /// Carto csempe elérhetőség teszteléshez használt alap URL.
  static const String _cartoTileCheckBaseUrl =
      'https://a.basemaps.cartocdn.com/dark_all/0/0/0.png';

  /// Ha van megadva [cartoApiKey], hozzáfűzi a `?key=$cartoApiKey` paramétert az URL-hez.
  /// Ha nincs megadva, az eredeti URL-t adja vissza változatlanul.
  static String buildCartoTileUrl(String baseUrl) {
    if (cartoApiKey.trim().isNotEmpty) {
      final separator = baseUrl.contains('?') ? '&' : '?';
      return '$baseUrl${separator}key=$cartoApiKey';
    }
    return baseUrl;
  }

  /// Carto Dark Matter csempe URL (kulccsal ellátva, ha elérhető).
  static String get cartoDarkTileUrl => buildCartoTileUrl(_cartoDarkBaseUrl);

  /// Carto Positron csempe URL (kulccsal ellátva, ha elérhető).
  static String get cartoLightTileUrl => buildCartoTileUrl(_cartoLightBaseUrl);

  /// Téma szerinti Carto csempe URL lekérdezése.
  static String getCartoTileUrl({required bool isDark}) {
    return isDark ? cartoDarkTileUrl : cartoLightTileUrl;
  }

  /// Csempe-elérhetőség teszt URL (kulccsal ellátva, ha elérhető).
  static String get cartoTileCheckUrl =>
      buildCartoTileUrl(_cartoTileCheckBaseUrl);
}
