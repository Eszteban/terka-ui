import 'package:flutter/material.dart';
import '../../../theme/app_texts.dart';
import '../../../widgets/alerts_section.dart';
import 'stop_details_times_list.dart';
import 'stop_line_selector.dart';
import '../../../utils/stop_details_utils.dart';

class StopDetailsTabs extends StatelessWidget {
  final DateTime now;
  final bool hasPast;
  final List<Map<String, dynamic>> visibleArrivals;
  final List<Map<String, dynamic>> visibleDepartures;
  final DateTime selectedDate;
  final bool showPastDepartures;
  final Map<String, dynamic>? stop;
  final VoidCallback onPickDate;
  final VoidCallback onTogglePastDepartures;
  final void Function(int) onStepSelectedDate;
  final VoidCallback onGoToToday;
  final void Function({
    required String tripId,
    required String serviceDay,
  }) onOpenTripDetails;

  final Set<String> selectedLines;
  final List<Map<String, dynamic>> uniqueLines;
  final void Function(String line, bool selected) onLineSelected;
  final VoidCallback onClearLineSelection;

  const StopDetailsTabs({
    super.key,
    required this.now,
    required this.hasPast,
    required this.visibleArrivals,
    required this.visibleDepartures,
    required this.selectedDate,
    required this.showPastDepartures,
    required this.stop,
    required this.selectedLines,
    required this.uniqueLines,
    required this.onLineSelected,
    required this.onClearLineSelection,
    required this.onPickDate,
    required this.onTogglePastDepartures,
    required this.onStepSelectedDate,
    required this.onGoToToday,
    required this.onOpenTripDetails,
  });

  bool _isSameDate(DateTime a, DateTime b) {
    return StopDetailsUtils.isSameBudapestDay(a, b);
  }

  String _formatSelectedDate(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 1,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => onStepSelectedDate(-1),
                  tooltip: AppTexts.stopPrevDay,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(AppTexts.stopDateLabel(_formatSelectedDate(selectedDate))),
                  ),
                ),
                IconButton(
                  onPressed: () => onStepSelectedDate(1),
                  tooltip: AppTexts.stopNextDay,
                  icon: const Icon(Icons.chevron_right),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _isSameDate(selectedDate, DateTime.now())
                      ? null
                      : onGoToToday,
                  child: Text(AppTexts.stopToday),
                ),
              ],
            ),
          ),
          if (hasPast)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: onTogglePastDepartures,
                  child: Text(
                    showPastDepartures
                        ? AppTexts.stopHidePast
                        : AppTexts.stopShowPast,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AlertsSection(alerts: stop?['alerts']),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: StopLineSelector(
              uniqueLines: uniqueLines,
              selectedLines: selectedLines,
              onLineSelected: onLineSelected,
              onClearSelection: onClearLineSelection,
            ),
          ),
          TabBar(
            tabs: [
              Tab(text: AppTexts.stopArrivals),
              Tab(text: AppTexts.stopDepartures),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                StopDetailsTimesList(
                  items: visibleArrivals,
                  now: now,
                  emptyMessage: AppTexts.stopNoArrivals,
                  onOpenTripDetails: onOpenTripDetails,
                ),
                StopDetailsTimesList(
                  items: visibleDepartures,
                  now: now,
                  emptyMessage: AppTexts.stopNoDepartures,
                  onOpenTripDetails: onOpenTripDetails,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
