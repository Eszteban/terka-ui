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
          final pubDateStr = item.getElement('pubDate')?.innerText.trim() ?? '';
          final pubDate = pubDateStr.isNotEmpty ? _parseRssDate(pubDateStr) : null;
          return _NewsItem(
            title: title,
            link: link,
            pubDate: pubDate,
            rawPubDate: pubDateStr.isNotEmpty ? pubDateStr : null,
          );
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
                    subtitle: item.pubDate != null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDateTime(item.pubDate!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : (item.rawPubDate != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  item.rawPubDate!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                  ),
                                ),
                              )
                            : null),
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

        Widget displayWidget = content;
        if (AppTexts.isEnglish) {
          displayWidget = Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: isDark ? 0.3 : 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.g_translate_rounded,
                        color: isDark ? Colors.amber[200] : Colors.amber[800],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppTexts.newsLanguageWarning,
                          style: TextStyle(
                            color: isDark ? Colors.amber[100] : Colors.amber[900],
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(child: content),
            ],
          );
        }

        if (!isDesktop) {
          return Card(
            elevation: isDark ? 0 : 2,
            shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            shape: bentoShape,
            color: isDark ? const Color(0xFF1A1615) : Colors.white,
            child: displayWidget,
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
                    child: displayWidget,
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
  final DateTime? pubDate;
  final String? rawPubDate;

  const _NewsItem({
    required this.title,
    required this.link,
    this.pubDate,
    this.rawPubDate,
  });
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

String _formatDateTime(DateTime dt) {
  final year = dt.year;
  final month = dt.month.toString().padLeft(2, '0');
  final day = dt.day.toString().padLeft(2, '0');
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  if (AppTexts.isHungarian) {
    return '$year. $month. $day. $hour:$minute';
  } else {
    return '$day/$month/$year $hour:$minute';
  }
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
