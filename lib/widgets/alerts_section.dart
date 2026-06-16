import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html_unescape/html_unescape.dart';
import '../theme/app_texts.dart';

class AlertsSection extends StatelessWidget {
  final List<dynamic>? alerts;

  const AlertsSection({super.key, this.alerts});

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final url = Uri.tryParse(urlString);
    if (url != null) {
      try {
        final isLaunched = await launchUrl(url, mode: LaunchMode.externalApplication);
        if (!isLaunched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppTexts.newsLinkOpenFailed)),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppTexts.newsLinkOpenFailed)),
          );
        }
      }
    }
  }

  String _getTranslatedText(
    Map<String, dynamic> alert,
    String defaultText,
    String listFieldName,
  ) {
    final lang = AppTexts.language.name;
    final list = alert[listFieldName] as List?;
    if (list != null) {
      for (final dynamic item in list) {
        if (item is Map && item['language'] == lang) {
          final text = item['text']?.toString().trim() ?? '';
          if (text.isNotEmpty) {
            return text;
          }
        }
      }
    }
    return defaultText;
  }

  String _formatTimestamp(int? timestampSeconds) {
    if (timestampSeconds == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampSeconds * 1000).toLocal();
    final yyyy = dt.year.toString().padLeft(4, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd $hh:$min';
  }

  String _formatTimeRange(int? start, int? end) {
    final startStr = _formatTimestamp(start);
    final endStr = _formatTimestamp(end);
    if (startStr.isNotEmpty && endStr.isNotEmpty) {
      return AppTexts.alertTimeRange(startStr, endStr);
    } else if (startStr.isNotEmpty) {
      return AppTexts.alertStartTime(startStr);
    } else if (endStr.isNotEmpty) {
      return AppTexts.alertEndTime(endStr);
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final list = alerts;
    if (list == null || list.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final validAlerts = list.where((dynamic a) {
      if (a is! Map) return false;
      final header = a['alertHeaderText']?.toString().trim() ?? '';
      final desc = a['alertDescriptionText']?.toString().trim() ?? '';
      return header.isNotEmpty || desc.isNotEmpty;
    }).toList();

    if (validAlerts.isEmpty) {
      return const SizedBox.shrink();
    }

    final baseAlertColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: baseAlertColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      color: baseAlertColor.withValues(alpha: isDark ? 0.08 : 0.04),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: Icon(
            Icons.notification_important_rounded,
            color: baseAlertColor,
            size: 22,
          ),
          title: Text(
            '${AppTexts.isHungarian ? 'Aktív figyelmeztetések' : 'Active Alerts'} (${validAlerts.length})',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
              color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          children: validAlerts.map((dynamic a) {
            final alert = a as Map<String, dynamic>;
            final rawHeader = alert['alertHeaderText']?.toString().trim() ?? '';
            final rawDesc = alert['alertDescriptionText']?.toString().trim() ?? '';
            final rawUrl = alert['alertUrl']?.toString().trim() ?? '';

            final header = _getTranslatedText(alert, rawHeader, 'alertHeaderTextTranslations');
            final desc = _getTranslatedText(alert, rawDesc, 'alertDescriptionTextTranslations');
            final url = _getTranslatedText(alert, rawUrl, 'alertUrlTranslations');

            final severity = alert['alertSeverityLevel']?.toString().toUpperCase() ?? 'UNKNOWN';
            final start = alert['effectiveStartDate'] is num ? (alert['effectiveStartDate'] as num).toInt() : null;
            final end = alert['effectiveEndDate'] is num ? (alert['effectiveEndDate'] as num).toInt() : null;

            Color severityColor;
            IconData severityIcon;
            if (severity == 'SEVERE') {
              severityColor = isDark ? const Color(0xFFFF5252) : const Color(0xFFD32F2F);
              severityIcon = Icons.error_outline_rounded;
            } else if (severity == 'WARNING') {
              severityColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00);
              severityIcon = Icons.warning_amber_rounded;
            } else if (severity == 'INFO') {
              severityColor = isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
              severityIcon = Icons.info_outline_rounded;
            } else {
              severityColor = isDark ? const Color(0xFFB0BEC5) : const Color(0xFF607D8B);
              severityIcon = Icons.campaign_rounded;
            }

            final timeRangeStr = _formatTimeRange(start, end);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: severityColor.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              color: severityColor.withValues(alpha: isDark ? 0.08 : 0.04),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                leading: Icon(severityIcon, color: severityColor, size: 24),
                title: RichText(
                  text: TextSpan(
                    children: parseHtmlToTextSpans(
                      header.isNotEmpty ? header : AppTexts.alertDefaultHeader,
                      TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 14,
                        fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                      ),
                    ),
                  ),
                ),
                subtitle: timeRangeStr.isNotEmpty
                    ? Text(
                        timeRangeStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      )
                    : null,
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                expandedAlignment: Alignment.topLeft,
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (desc.isNotEmpty) ...[
                    RichText(
                      text: TextSpan(
                        children: parseHtmlToTextSpans(
                          desc,
                          TextStyle(
                            fontSize: 13.5,
                            height: 1.4,
                            color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                            fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (url.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _launchUrl(context, url),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: Text(
                          AppTexts.alertDetailsButton,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  static List<InlineSpan> parseHtmlToTextSpans(String htmlText, TextStyle baseStyle) {
    final unescape = HtmlUnescape();
    var text = unescape.convert(htmlText);

    // Replace line breaks with newlines
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

    // Clean up whitespace around block tags to avoid unwanted spacing/newlines
    text = text.replaceAllMapped(
      RegExp(r'<(ul|/ul|li|/li)>\s+', caseSensitive: false),
      (match) => '<${match.group(1)}>',
    );
    text = text.replaceAllMapped(
      RegExp(r'\s+<(ul|/ul|li|/li)>', caseSensitive: false),
      (match) => '<${match.group(1)}>',
    );

    // Tokenize tags and text
    final tagRegExp = RegExp(r'<(/?[a-zA-Z1-9]+)([^>]*)>');
    final tokens = <_HtmlToken>[];
    int lastEnd = 0;

    for (final match in tagRegExp.allMatches(text)) {
      if (match.start > lastEnd) {
        tokens.add(_HtmlToken.text(text.substring(lastEnd, match.start)));
      }
      var tagName = match.group(1)!;
      bool isClose = false;
      if (tagName.startsWith('/')) {
        isClose = true;
        tagName = tagName.substring(1);
      }
      tokens.add(_HtmlToken.tag(tagName.toLowerCase(), isClose));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      tokens.add(_HtmlToken.text(text.substring(lastEnd)));
    }

    final spans = <InlineSpan>[];

    // Track active styling properties manually to support combination of styles
    bool isBold = false;
    bool isItalic = false;

    // Helper to get current style based on active flags
    TextStyle getCurrentStyle() {
      var style = baseStyle;
      if (isBold) {
        style = style.copyWith(fontWeight: FontWeight.bold);
      }
      if (isItalic) {
        style = style.copyWith(fontStyle: FontStyle.italic);
      }
      return style;
    }

    for (final token in tokens) {
      if (token.isTag) {
        final name = token.name;
        if (token.isClose) {
          if (name == 'b' || name == 'strong') {
            isBold = false;
          } else if (name == 'i' || name == 'em') {
            isItalic = false;
          } else if (name == 'li') {
            spans.add(TextSpan(text: '\n', style: getCurrentStyle()));
          }
        } else {
          if (name == 'b' || name == 'strong') {
            isBold = true;
          } else if (name == 'i' || name == 'em') {
            isItalic = true;
          } else if (name == 'li') {
            // Check if we need a newline before bullet point
            bool needsNewline = false;
            if (spans.isNotEmpty) {
              final lastSpan = spans.last;
              if (lastSpan is TextSpan && lastSpan.text != null) {
                if (!lastSpan.text!.endsWith('\n')) {
                  needsNewline = true;
                }
              }
            }
            if (needsNewline) {
              spans.add(TextSpan(text: '\n', style: getCurrentStyle()));
            }
            spans.add(TextSpan(text: '• ', style: getCurrentStyle()));
          }
        }
      } else {
        spans.add(TextSpan(text: token.text, style: getCurrentStyle()));
      }
    }

    // Clean up trailing newline if any
    if (spans.isNotEmpty) {
      final lastSpan = spans.last;
      if (lastSpan is TextSpan && lastSpan.text != null) {
        if (lastSpan.text!.endsWith('\n')) {
          spans[spans.length - 1] = TextSpan(
            text: lastSpan.text!.substring(0, lastSpan.text!.length - 1),
            style: lastSpan.style,
          );
        }
      }
    }

    return spans;
  }
}

class _HtmlToken {
  final String text;
  final String name;
  final bool isTag;
  final bool isClose;

  _HtmlToken.text(this.text)
      : name = '',
        isTag = false,
        isClose = false;

  _HtmlToken.tag(this.name, this.isClose)
      : text = '',
        isTag = true;
}
