import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';

class VehicleInfoCard extends StatelessWidget {
  final String lineLabel;
  final bool lineLabelUsesSpanFont;
  final String tripNumberLabel;
  final String tripHeadsignLabel;
  final String serviceLabel;
  final String modelLabel;
  final int? arrivalDelaySeconds;
  final String? nextStopName;
  final Color markerColor;
  final Color markerTextColor;
  final VoidCallback? onTap;

  static const String _spanFontFamily = 'MNR2007';
  static const double _spanFontScale = 28 / 16;

  const VehicleInfoCard({
    super.key,
    required this.lineLabel,
    required this.lineLabelUsesSpanFont,
    required this.tripNumberLabel,
    required this.tripHeadsignLabel,
    required this.serviceLabel,
    required this.modelLabel,
    required this.arrivalDelaySeconds,
    required this.nextStopName,
    required this.markerColor,
    required this.markerTextColor,
    this.onTap,
  });

  String _formatDelayValue(int? delaySeconds) {
    if (delaySeconds == null) return 'n/a';
    if (delaySeconds.abs() < 60) return '0p';
    final minutes = (delaySeconds / 60).round();
    if (minutes > 0) return '+$minutes' 'p';
    return '${minutes}p';
  }

  Color _delayColor(int? delaySeconds) {
    if (delaySeconds == null) return Colors.grey;
    final minutes = (delaySeconds / 60).round();
    if (minutes > 0) return Colors.redAccent;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final nextStop = (nextStopName ?? tripHeadsignLabel).trim();
    final nextStopPart = nextStop.isNotEmpty ? 'köv: $nextStop' : 'köv: -';
    
    final delayString = _formatDelayValue(arrivalDelaySeconds);
    final delayColor = _delayColor(arrivalDelaySeconds);

    final cardContent = Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.getVehicleCardBackground(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: lineLabelUsesSpanFont
                    ? const EdgeInsets.symmetric(horizontal: 0, vertical: 0)
                    : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: markerColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  lineLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: markerTextColor,
                    fontSize: lineLabelUsesSpanFont
                        ? 14 * _spanFontScale
                        : 14,
                    fontFamily: lineLabelUsesSpanFont
                        ? _spanFontFamily
                        : null,
                    leadingDistribution: lineLabelUsesSpanFont
                        ? TextLeadingDistribution.even
                        : null,
                    height: lineLabelUsesSpanFont ? 1.0 : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tripNumberLabel,
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (tripHeadsignLabel.isNotEmpty) ...[
            Text(
              tripHeadsignLabel,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          Text(
            '$serviceLabel\n$modelLabel',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.5)
                  : Colors.black.withOpacity(0.5),
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Text('késés: ', style: TextStyle(color: colorScheme.onSurface)),
              Text(
                delayString,
                style: TextStyle(color: delayColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text(nextStopPart, style: TextStyle(color: colorScheme.onSurface)),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: onTap != null
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: cardContent,
            )
          : cardContent,
    );
  }
}
