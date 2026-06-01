import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart';
import 'package:html_unescape/html_unescape.dart';


class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});
  

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  static const String _rssUrl = 'https://www.mavcsoport.hu/mavinform/rss.xml';
  late final Future<List<_NewsItem>> _newsFuture = _fetchNews();
  final unescape = HtmlUnescape();

  Future<List<_NewsItem>> _fetchNews() async {
    final response = await http.get(Uri.parse(_rssUrl));
    if (response.statusCode != 200) {
      throw Exception('Nem sikerült betölteni a híreket.');
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
          return _NewsItem(title: title, link: link);
        })
        .whereType<_NewsItem>()
        .toList();
  }

  Future<void> _openLink(String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null) {
      return;
    }

    final isLaunched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!isLaunched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A hír linkje nem nyitható meg.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return FutureBuilder<List<_NewsItem>>(
      future: _newsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('Hiba történt a hírek betöltése közben.'),
          );
        }

        final items = snapshot.data ?? const <_NewsItem>[];
        if (items.isEmpty) {
          return const Center(child: Text('Nincsenek elérhető hírek.'));
        }

        final list = ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              title: Text(unescape.convert(item.title)),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _openLink(item.link),
            );
          },
        );

        if (!isDesktop) {
          return Card(child: list);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MÁV Hírek',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text('Kattints egy címre a cikk megnyitásához.'),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Card(
                    child: list,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NewsItem {
  final String title;
  final String link;

  const _NewsItem({required this.title, required this.link});
}
