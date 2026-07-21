import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/news_item.dart';
import '../repositories/news_repository.dart';
import '../injection_container.dart';
import '../theme/app_texts.dart';
import '../utils/layout_provider.dart';
import '../widgets/layout/screen_header.dart';
import '../widgets/layout/desktop_sidebar_wrapper.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late final Future<List<NewsItem>> _newsFuture = sl<NewsRepository>().fetchNews();

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
    final isDesktop = LayoutProvider.isDesktop(context, breakpoint: 600);

    return FutureBuilder<List<NewsItem>>(
      future: _newsFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final hasError = snapshot.hasError;
        final items = snapshot.data ?? const <NewsItem>[];

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
                      item.title,
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

        return DesktopSidebarWrapper(
          child: Column(
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
        ));
      },
    );
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
