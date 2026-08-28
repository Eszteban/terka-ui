import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';

Future<bool> canLoadMapTiles() async {
  try {
    final response = await http
        .get(Uri.parse(AppConfig.cartoTileCheckUrl))
        .timeout(const Duration(seconds: 6));
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}

