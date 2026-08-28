import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/news_item.dart';
import '../repositories/news_repository.dart';
import '../injection_container.dart';
import 'package:terka/theme/app_texts.dart';
import '../utils/layout_provider.dart';
import '../widgets/layout/desktop_sidebar_wrapper.dart';
import 'package:terka/theme/app_tokens.dart';
import 'package:terka/theme/terka_semantic_colors.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<NewsItem>> _newsFuture = sl<NewsRepository>().fetchNews();

  Future<void> _refresh() async {
    setState(() {
      _newsFuture = sl<NewsRepository>().fetchNews();
    });
    try {
      await _newsFuture;
    } catch (_) {}
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        final isLaunched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!isLaunched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppTexts.newsLinkOpenFailed)),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppTexts.newsLinkOpenFailed)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = LayoutProvider.isDesktop(context, breakpoint: 600);
    final semantic = context.semanticColors;

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
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppTexts.newsLoadError,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(AppTexts.isHungarian ? 'Újrapróbálkozás' : 'Retry'),
                  ),
                ],
              ),
            ),
          );
        } else if (items.isEmpty) {
          content = Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppTexts.newsEmpty),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(AppTexts.isHungarian ? 'Frissítés' : 'Refresh'),
                ),
              ],
            ),
          );
        } else {
          content = RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                child: Material(
                  color: colorScheme.surfaceContainerLowest,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  shadowColor: isDark ? null : AppColors.black.withValues(alpha: 0.03),
                  elevation: isDark ? 0 : 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppSpacing.lg),
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
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: AppSpacing.xs),
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
                                padding: const EdgeInsets.only(top: AppSpacing.sm),
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
                      color: colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    onTap: () => _openLink(item.link),
                  ),
                ),
              );
            },
          ),
        );
      }

        Widget displayWidget = content;
        if (AppTexts.isEnglish) {
          displayWidget = Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: semantic.alertWarningContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: semantic.alertWarning.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.g_translate_rounded,
                        color: semantic.alertWarning,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          AppTexts.newsLanguageWarning,
                          style: TextStyle(
                            color: semantic.onAlertWarningContainer,
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
          return Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: displayWidget),
                ],
              ),
            ),
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
            const SizedBox(height: AppSpacing.xs),
            Text(AppTexts.newsInstruction),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: displayWidget,
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
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                    boxShadow: isDark ? null : [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.03),
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
                            const SizedBox(height: AppSpacing.sm),
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
                      const SizedBox(width: AppSpacing.lg),
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
