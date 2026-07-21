import 'dart:async';
import 'package:flutter/material.dart';
import '../../../utils/stop_details_utils.dart';
import 'package:terka/theme/app_texts.dart';
import '../../../widgets/departure_card.dart';
import 'package:terka/theme/app_tokens.dart';

class StopDetailsSchedule extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Set<String> selectedLines;
  final List<Map<String, dynamic>> uniqueLines;
  final DateTime now;
  final void Function({
    required String tripId,
    required String serviceDay,
  })? onOpenTripDetails;

  const StopDetailsSchedule({
    super.key,
    required this.items,
    required this.selectedLines,
    required this.uniqueLines,
    required this.now,
    this.onOpenTripDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            AppTexts.stopNoDepartures,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
          ),
        ),
      );
    }

    // Group departures by hour (using local scheduled departure/arrival hour)
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final item in items) {
      final hasDeparture = StopDetailsUtils.asNum(item['scheduledDeparture']) != null ||
                           StopDetailsUtils.asNum(item['realtimeDeparture']) != null;
      final scheduledArrival = StopDetailsUtils.resolveDepartureTime(
        serviceDay: StopDetailsUtils.asNum(item['serviceDay']),
        secondsOfDay: StopDetailsUtils.asNum(item['scheduledArrival']),
      );
      final scheduledDeparture = StopDetailsUtils.resolveDepartureTime(
        serviceDay: StopDetailsUtils.asNum(item['serviceDay']),
        secondsOfDay: StopDetailsUtils.asNum(item['scheduledDeparture']),
      );
      final scheduled = hasDeparture ? scheduledDeparture : scheduledArrival;
      if (scheduled == null) continue;

      final hour = scheduled.hour;
      grouped.putIfAbsent(hour, () => []).add(item);
    }

    if (grouped.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            AppTexts.stopNoDepartures,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
          ),
        ),
      );
    }

    final sortedHours = grouped.keys.toList()..sort();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: sortedHours.length,
      shrinkWrap: true,
      separatorBuilder: (context, index) => Divider(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        height: 16,
      ),
      itemBuilder: (context, index) {
        final hour = sortedHours[index];
        final departuresInHour = grouped[hour]!;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 48,
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Text(
                  hour.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: departuresInHour.map((departure) {
                      final trip = departure['trip'];
                      final tripId = trip is Map ? trip['gtfsId']?.toString() ?? '' : '';
                      final serviceDay = StopDetailsUtils.serviceDayToYmd(
                        StopDetailsUtils.asNum(departure['serviceDay']),
                      );
                      final canOpenTrip = tripId.trim().isNotEmpty && serviceDay.isNotEmpty;

                      final openTrip = canOpenTrip && onOpenTripDetails != null
                          ? () => onOpenTripDetails!(
                                tripId: tripId,
                                serviceDay: serviceDay,
                              )
                          : null;

                      return _MinuteItem(
                        departure: departure,
                        isDark: isDark,
                        onTap: openTrip,
                        onLongPress: () {
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: 'Dismiss',
                            barrierColor: AppColors.black.withValues(alpha: 0.15),
                            transitionDuration: const Duration(milliseconds: 350),
                            pageBuilder: (context, anim1, anim2) {
                              return _TimetablePopup(
                                departure: departure,
                                now: now,
                                onTap: openTrip,
                              );
                            },
                            transitionBuilder: (context, anim1, anim2, child) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 1),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: anim1,
                                  curve: Curves.easeOutBack, // Bouncy pop transition!
                                )),
                                child: child,
                              );
                            },
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MinuteItem extends StatelessWidget {
  final Map<String, dynamic> departure;
  final bool isDark;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _MinuteItem({
    required this.departure,
    required this.isDark,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final trip = departure['trip'];

    final hasDeparture = StopDetailsUtils.asNum(departure['scheduledDeparture']) != null ||
                         StopDetailsUtils.asNum(departure['realtimeDeparture']) != null;
    final scheduledArrival = StopDetailsUtils.resolveDepartureTime(
      serviceDay: StopDetailsUtils.asNum(departure['serviceDay']),
      secondsOfDay: StopDetailsUtils.asNum(departure['scheduledArrival']),
    );
    final scheduledDeparture = StopDetailsUtils.resolveDepartureTime(
      serviceDay: StopDetailsUtils.asNum(departure['serviceDay']),
      secondsOfDay: StopDetailsUtils.asNum(departure['scheduledDeparture']),
    );
    final scheduled = hasDeparture ? scheduledDeparture : scheduledArrival;
    final minuteText = scheduled != null ? scheduled.minute.toString().padLeft(2, '0') : '--';

    final isWheelchair = trip is Map &&
        (trip['wheelchairAccessible']?.toString().toUpperCase() == 'POSSIBLE' ||
         trip['wheelchairAccessible']?.toString().toUpperCase() == 'ALLOWED');
    final isBike = trip is Map &&
        trip['bikesAllowed']?.toString().toUpperCase() == 'ALLOWED';

    final isRealtime = departure['realtime'] == true;
    Color? realtimeColor;
    if (isRealtime) {
      final delay = StopDetailsUtils.asNum(departure['departureDelay']) ?? 0;
      if (delay == 0) {
        realtimeColor = isDark ? AppColors.green.shade300 : AppColors.green.shade700;
      } else if (delay < 0) {
        realtimeColor = isDark ? AppColors.blue.shade300 : AppColors.blue.shade700;
      } else {
        realtimeColor = isDark ? AppColors.red.shade300 : AppColors.red.shade700;
      }
    }

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? AppColors.white.withValues(alpha: 0.12) : AppColors.black.withValues(alpha: 0.08),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isDark ? AppColors.white.withValues(alpha: 0.02) : AppColors.black.withValues(alpha: 0.01),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                minuteText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: realtimeColor,
                ),
              ),
              if (isWheelchair || isBike) ...[
                const SizedBox(width: AppSpacing.xs),
                if (isWheelchair)
                  Icon(
                    Icons.accessible,
                    size: 13,
                    color: isDark ? AppColors.blue.shade300 : AppColors.blue.shade700,
                  ),
                if (isBike) ...[
                  if (isWheelchair) const SizedBox(width: AppSpacing.none),
                  Icon(
                    Icons.directions_bike,
                    size: 13,
                    color: isDark ? AppColors.green.shade300 : AppColors.green.shade700,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TimetablePopup extends StatefulWidget {
  final Map<String, dynamic> departure;
  final DateTime now;
  final VoidCallback? onTap;

  const _TimetablePopup({
    required this.departure,
    required this.now,
    this.onTap,
  });

  @override
  State<_TimetablePopup> createState() => _TimetablePopupState();
}

class _TimetablePopupState extends State<_TimetablePopup> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: DepartureCard(
            departure: widget.departure,
            now: widget.now,
            onTap: widget.onTap != null
                ? () {
                    _timer?.cancel();
                    Navigator.of(context).maybePop();
                    widget.onTap!();
                  }
                : null,
          ),
        ),
      ),
    );
  }
}
