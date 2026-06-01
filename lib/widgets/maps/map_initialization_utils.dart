import 'package:http/http.dart' as http;

Future<bool> canLoadMapTiles() async {
  try {
    final response = await http
        .get(Uri.parse('https://a.basemaps.cartocdn.com/dark_all/0/0/0.png'))
        .timeout(const Duration(seconds: 6));
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}
