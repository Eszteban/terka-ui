import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart';
import 'package:html_unescape/html_unescape.dart';
import '../theme/app_texts.dart';

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
        SnackBar(content: Text(AppTexts.newsLinkOpenFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return FutureBuilder<List<_NewsItem>>(
      future: _newsFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final hasError = snapshot.hasError;
        final items = snapshot.data ?? const <_NewsItem>[];

        Widget content;
        if (isLoading) {
          content = const _NewsLoadingView();
        } else if (hasError) {
          content = Center(
            child: Text(AppTexts.newsLoadError),
          );
        } else if (items.isEmpty) {
          content = Center(child: Text(AppTexts.newsEmpty));
        } else {
          content = ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1615) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                    boxShadow: isDark ? null : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      unescape.convert(item.title),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: const Color(0xFF8D4B20).withValues(alpha: 0.5),
                    ),
                    onTap: () => _openLink(item.link),
                  ),
                ),
              );
            },
          );
        }

        final bentoShape = RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.4),
            width: 1,
          ),
        );

        if (!isDesktop) {
          return Card(
            elevation: isDark ? 0 : 2,
            shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            shape: bentoShape,
            color: isDark ? const Color(0xFF1A1615) : Colors.white,
            child: content,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTexts.newsTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(AppTexts.newsInstruction),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Card(
                    elevation: isDark ? 0 : 2,
                    shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    shape: bentoShape,
                    color: isDark ? const Color(0xFF1A1615) : Colors.white,
                    child: content,
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

class _NewsLoadingView extends StatefulWidget {
  const _NewsLoadingView();

  @override
  State<_NewsLoadingView> createState() => _NewsLoadingViewState();
}

class _NewsLoadingViewState extends State<_NewsLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final skeletonColor = isDark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.7);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.35 + (_controller.value * 0.4);
        return Opacity(
          opacity: opacity,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1615) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                    boxShadow: isDark ? null : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 14,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: skeletonColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 14,
                              width: 140,
                              decoration: BoxDecoration(
                                color: skeletonColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: skeletonColor,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
