import 'dart:convert';
import 'dart:io';

void main() async {
  final query = '''
  query {
    route(id: "hkir:hkir_V-R-200-5980") {
      patterns {
        headsign
        trips {
          gtfsId
          tripHeadsign
          activeDates
        }
      }
    }
  }
  ''';
  final url = Uri.parse('https://mavplusz.hu/otp2-backend/otp/routers/default/index/graphql');
  final response = await HttpClient().postUrl(url);
  response.headers.add('Content-Type', 'application/json');
  response.headers.add('Dnt', '1');
  response.headers.add('Origin', 'https://mavplusz.hu');
  response.write(jsonEncode({'query': query}));
  final res = await response.close();
  final data = await res.transform(utf8.decoder).join();
  print(data);
}
