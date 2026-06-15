import 'package:flutter/material.dart';
import '../utils/trip_details_utils.dart';
import '../theme/app_texts.dart';

class RealtimeTimeText extends StatelessWidget {
  final num? scheduled;
  final num? realtime;
  final num? delay;
  final bool isRealtime;
  final bool passedStop;
  final String serviceDay;
  final String? suffix;
  final String tooltipType;
  final String? customTooltip;

  const RealtimeTimeText({
    super.key,
    required this.scheduled,
    required this.realtime,
    required this.delay,
    required this.isRealtime,
    required this.passedStop,
    required this.serviceDay,
    this.suffix,
    this.tooltipType = 'combined',
    this.customTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseTextColor = colorScheme.onSurface;
    final mutedTextColor = colorScheme.onSurfaceVariant;
    final scheduledText = TripDetailsUtils.formatEpoch(scheduled, serviceDay);
    final realtimeText = TripDetailsUtils.formatEpoch(realtime, serviceDay);

    Color color;
    if (passedStop) {
      color = mutedTextColor;
    } else if (!isRealtime) {
      color = baseTextColor;
    } else if (scheduled == realtime || scheduled == null || realtime == null) {
      color = Colors.green;
    } else {
      color = (delay ?? 0) > 0
          ? Colors.red
          : (delay ?? 0) < 0
              ? Colors.blue
              : baseTextColor;
    }

    final mainText = suffix != null ? '$realtimeText $suffix' : realtimeText;

    final timeWidget = Text(
      mainText,
      style: TextStyle(color: color, fontWeight: FontWeight.w700),
    );

    if (customTooltip != null) {
      return Tooltip(
        message: customTooltip!,
        triggerMode: TooltipTriggerMode.longPress,
        child: timeWidget,
      );
    }

    if (scheduled != null) {
      final String msg;
      if (tooltipType == 'arrival') {
        msg = AppTexts.tripScheduledArrival(scheduledText);
      } else if (tooltipType == 'departure') {
        msg = AppTexts.tripScheduledDeparture(scheduledText);
      } else {
        msg = AppTexts.tripScheduledTime(scheduledText);
      }

      return Tooltip(
        message: msg,
        triggerMode: TooltipTriggerMode.longPress,
        child: timeWidget,
      );
    }

    return timeWidget;
  }
}
