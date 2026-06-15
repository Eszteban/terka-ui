import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html_unescape/html_unescape.dart';
import '../theme/app_texts.dart';

class AlertsSection extends StatelessWidget {
  final List<dynamic>? alerts;

  const AlertsSection({super.key, this.alerts});

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.tryParse(urlString);
    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.notification_important_rounded,
                color: isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00),
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                AppTexts.isHungarian ? 'Aktív figyelmeztetések' : 'Active Alerts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        ...validAlerts.map((dynamic a) {
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
                  children: _parseHtmlToTextSpans(
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
                      children: _parseHtmlToTextSpans(
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
                      onPressed: () => _launchUrl(url),
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
        }),
        const SizedBox(height: 8),
      ],
    );
  }
  List<InlineSpan> _parseHtmlToTextSpans(String htmlText, TextStyle baseStyle) {
    final unescape = HtmlUnescape();
    var text = unescape.convert(htmlText);

    // Replace line breaks with newlines
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

    // Strip anchor tags, keeping the link text if any, or replace them
    text = text.replaceAll(RegExp(r'<a[^>]*>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'</a>', caseSensitive: false), '');

    // Strip other common block/inline tags but keep their content
    text = text.replaceAll(RegExp(r'</?(p|div|span)[^>]*>', caseSensitive: false), '');

    final spans = <InlineSpan>[];
    final regExp = RegExp(r'<(strong|b)>(.*?)</\1>', caseSensitive: false, dotAll: true);

    int lastMatchEnd = 0;
    final matches = regExp.allMatches(text);

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }

      final innerText = match.group(2) ?? '';
      spans.add(TextSpan(
        text: innerText,
        style: baseStyle.copyWith(fontWeight: FontWeight.bold),
      ));

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return spans;
  }
}
