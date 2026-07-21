import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:terka/theme/app_texts.dart';
import 'package:terka/theme/app_tokens.dart';

class TripDetailsAdditionalInfo extends StatelessWidget {
  final Map<String, dynamic> trip;
  final String serviceDay;

  const TripDetailsAdditionalInfo({
    super.key,
    required this.trip,
    required this.serviceDay,
  });

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final url = Uri.tryParse(urlString);
    if (url != null) {
      try {
        final isLaunched = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        if (!isLaunched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppTexts.errorFailedToOpenLink(urlString))),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppTexts.errorFailedToOpenLink(urlString))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = trip['route'];
    final agency = route is Map ? route['agency'] : null;
    final agencyName = agency is Map ? agency['name']?.toString() : null;
    final agencyUrl = agency is Map ? agency['url']?.toString() : null;

    final serviceDescriptions = trip['serviceDescriptions'];
    String? serviceDescText;
    if (serviceDescriptions is List && serviceDescriptions.isNotEmpty) {
      serviceDescText = serviceDescriptions
          .map((sd) => sd is Map ? sd['description']?.toString() : sd?.toString())
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .join(', ');
    }

    final wheelchairAccessible = trip['wheelchairAccessible']?.toString().toUpperCase();
    final bikesAllowed = trip['bikesAllowed']?.toString().toUpperCase();

    final isWheelchair = wheelchairAccessible == 'POSSIBLE' || wheelchairAccessible == 'ALLOWED';
    final isWheelchairNot = wheelchairAccessible == 'NOT_ACCESSIBLE';

    final isBike = bikesAllowed == 'ALLOWED';
    final isBikeNot = bikesAllowed == 'NOT_ALLOWED';

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color greenColor = const Color(0xFF34C759);
    final Color redColor = const Color(0xFFFF3B30);
    final Color greyColor = colorScheme.outline;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.white.withValues(alpha: 0.08)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                AppTexts.tripAdditionalInfoTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Operator Row
          if (agencyName != null && agencyName.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.business_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13.5,
                          color: colorScheme.onSurface,
                          height: 1.3,
                        ),
                        children: [
                          TextSpan(text: AppTexts.tripServiceOperatedBy),
                          if (agencyUrl != null && agencyUrl.isNotEmpty) ...[
                            const TextSpan(text: ' '),
                            TextSpan(
                              text: agencyName,
                              style: TextStyle(
                                color: colorScheme.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _launchUrl(context, agencyUrl),
                            ),
                          ],
                          TextSpan(text: AppTexts.tripServiceOperatedSuffix),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Service Description Row
          if (serviceDescText != null && serviceDescText.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      AppTexts.tripRuns(serviceDescText),
                      style: TextStyle(
                        fontSize: 13.5,
                        color: colorScheme.onSurface,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Service Day Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.event,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${AppTexts.isHungarian ? "Kiválasztott nap:" : "Selected day:"} $serviceDay',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: colorScheme.onSurface,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Wheelchair Accessibility Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.accessible_rounded,
                  size: 18,
                  color: isWheelchair
                      ? greenColor
                      : isWheelchairNot
                          ? redColor
                          : greyColor,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    isWheelchair
                        ? AppTexts.tripWheelchairAccessible
                        : isWheelchairNot
                            ? AppTexts.tripWheelchairNotAccessible
                            : AppTexts.tripWheelchairNoInfo,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: colorScheme.onSurface,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bicycle Accessibility Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.pedal_bike_rounded,
                  size: 18,
                  color: isBike
                      ? greenColor
                      : isBikeNot
                          ? redColor
                          : greyColor,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    isBike
                        ? AppTexts.tripBikesAllowed
                        : isBikeNot
                            ? AppTexts.tripBikesNotAllowed
                            : AppTexts.tripBikesNoInfo,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: colorScheme.onSurface,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
