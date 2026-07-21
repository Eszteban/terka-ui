import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:html_unescape/html_unescape.dart';
import '../models/news_item.dart';
import 'package:terka/theme/app_texts.dart';
import 'news_repository.dart';
import '../constants/search_api.dart';

class RssNewsRepository implements NewsRepository {
  final _unescape = HtmlUnescape();

  @override
  Future<List<NewsItem>> fetchNews() async {
    final response = await http.get(Uri.parse(rssApiUrl));
    if (response.statusCode != 200) {
      throw Exception(AppTexts.newsLoadFailed);
    }

    final document = XmlDocument.parse(response.body);
    final items = document.findAllElements('item');

    return items
        .map((item) {
          final title = item.getElement('title')?.innerText.trim() ?? '';
          final link = item.getElement('link')?.innerText.trim() ?? '';
          if (title.isEmpty || link.isEmpty) {
            return null;
          }
          final pubDateStr = item.getElement('pubDate')?.innerText.trim() ?? '';
          final pubDate = pubDateStr.isNotEmpty ? _parseRssDate(pubDateStr) : null;
          return NewsItem(
            title: _unescape.convert(title),
            link: link,
            pubDate: pubDate,
            rawPubDate: pubDateStr.isNotEmpty ? pubDateStr : null,
          );
        })
        .whereType<NewsItem>()
        .toList();
  }

  DateTime? _parseRssDate(String dateStr) {
    try {
      var cleanStr = dateStr.trim();
      if (cleanStr.contains(',')) {
        cleanStr = cleanStr.split(',')[1].trim();
      }
      final parts = cleanStr.split(RegExp(r'\s+'));
      if (parts.length < 4) return null;
      final day = int.tryParse(parts[0]);
      final monthStr = parts[1].toLowerCase();
      final year = int.tryParse(parts[2]);
      final timeParts = parts[3].split(':');
      if (day == null || year == null || timeParts.length < 2) return null;
      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);
      if (hour == null || minute == null) return null;

      final months = {
        'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
        'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
      };
      final month = months[monthStr];
      if (month == null) return null;

      var offsetHours = 0;
      var offsetMinutes = 0;
      var isNegativeOffset = false;
      if (parts.length >= 5) {
        final tz = parts[4];
        if (tz.startsWith('+') || tz.startsWith('-')) {
          isNegativeOffset = tz.startsWith('-');
          final cleanTz = tz.substring(1);
          if (cleanTz.length >= 4) {
            offsetHours = int.tryParse(cleanTz.substring(0, 2)) ?? 0;
            offsetMinutes = int.tryParse(cleanTz.substring(2, 4)) ?? 0;
          }
        }
      }
      var dt = DateTime.utc(year, month, day, hour, minute);
      if (offsetHours != 0 || offsetMinutes != 0) {
        final offsetDuration = Duration(hours: offsetHours, minutes: offsetMinutes);
        dt = isNegativeOffset ? dt.add(offsetDuration) : dt.subtract(offsetDuration);
      }
      return dt.toLocal();
    } catch (_) {
      return null;
    }
  }
}
