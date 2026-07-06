import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../utils/stop_details_utils.dart';
import '../../../widgets/maps/plan_map_view.dart';
import '../../../widgets/maps/route_map_data.dart';
import '../../../theme/app_texts.dart';
import '../../../widgets/alerts_section.dart';
import 'stop_details_times_list.dart';
import 'stop_line_selector.dart';
import 'stop_details_schedule.dart';

class StopDetailsMobileSheet extends StatefulWidget {
  static const double _mobileSheetMinSize = 0.2;
  static const double _mobileSheetInitialSize = 0.3;
  static const double _mobileSheetMaxSize = 0.92;
  static const double _mobileStopFocusZoom = 16;

  final Map<String, dynamic> stop;
  final LatLng? initialStopPoint;
  final String? initialStopName;
  final DateTime now;
  final bool hasPast;
  final List<Map<String, dynamic>> visibleArrivals;
  final List<Map<String, dynamic>> visibleDepartures;
  final DateTime selectedDate;
  final bool showPastDepartures;
  final VoidCallback onPickDate;
  final VoidCallback onTogglePastDepartures;
  final void Function(int) onStepSelectedDate;
  final VoidCallback onGoToToday;
  final void Function({required String tripId, required String serviceDay})
  onOpenTripDetails;

  final Set<String> selectedLines;
  final List<Map<String, dynamic>> uniqueLines;
  final void Function(String line, bool selected) onLineSelected;
  final VoidCallback onClearLineSelection;

  const StopDetailsMobileSheet({
    super.key,
    required this.stop,
    required this.initialStopPoint,
    required this.initialStopName,
    required this.now,
    required this.hasPast,
    required this.visibleArrivals,
    required this.visibleDepartures,
    required this.selectedDate,
    required this.showPastDepartures,
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

  @override
  State<StopDetailsMobileSheet> createState() => _StopDetailsMobileSheetState();
}

class _StopDetailsMobileSheetState extends State<StopDetailsMobileSheet> {
  int _mobileSelectedTabIndex = 1;

  bool _isSameDate(DateTime a, DateTime b) {
    return StopDetailsUtils.isSameBudapestDay(a, b);
  }

  String _formatSelectedDate(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  RouteMapData _buildStopMapRouteData(Map<String, dynamic> stop) {
    final point = StopDetailsUtils.stopPoint(stop) ?? widget.initialStopPoint;
    if (point == null) {
      return const RouteMapData(segments: [], stops: []);
    }

    final rawStopName =
        stop['name']?.toString() ?? widget.initialStopName ?? AppTexts.stops;
    final bearing = stop['bearing'] is num
        ? (stop['bearing'] as num).toDouble()
        : null;
    return RouteMapData(
      segments: const [],
      stops: [
        RouteStopMarker(
          point: point,
          label: StopDetailsUtils.plainText(rawStopName),
          type: RouteStopType.start,
          bearing: bearing,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeData = _buildStopMapRouteData(widget.stop);
    final screenHeight = MediaQuery.of(context).size.height;
    final controlsBottomInset =
        screenHeight * StopDetailsMobileSheet._mobileSheetInitialSize + 24;

    return Stack(
      children: [
        Positioned.fill(
          child: PlanMapView(
            routeData: routeData,
            controlsBottomInset: controlsBottomInset,
            fitPadding: EdgeInsets.fromLTRB(
              48,
              48,
              48,
              controlsBottomInset + 120,
            ),
            initialZoom: StopDetailsMobileSheet._mobileStopFocusZoom,
            singlePointZoom: StopDetailsMobileSheet._mobileStopFocusZoom,
            showStopLabels: false,
            useBaseMapStopIcon: true,
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: StopDetailsMobileSheet._mobileSheetInitialSize,
          minChildSize: StopDetailsMobileSheet._mobileSheetMinSize,
          maxChildSize: StopDetailsMobileSheet._mobileSheetMaxSize,
          snap: true,
          snapSizes: const [
            StopDetailsMobileSheet._mobileSheetInitialSize,
            0.6,
            StopDetailsMobileSheet._mobileSheetMaxSize,
          ],
          builder: (context, scrollController) {
            final colorScheme = Theme.of(context).colorScheme;
            return Material(
              elevation: 8,
              color: colorScheme.surface.withValues(alpha: 0.97),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildStopDetailsSheetList(
                sheetScrollController: scrollController,
                now: widget.now,
                hasPast: widget.hasPast,
                visibleArrivals: widget.visibleArrivals,
                visibleDepartures: widget.visibleDepartures,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStopDetailsSheetList({
    required ScrollController sheetScrollController,
    required DateTime now,
    required bool hasPast,
    required List<Map<String, dynamic>> visibleArrivals,
    required List<Map<String, dynamic>> visibleDepartures,
  }) {
    return Column(
      children: [
        SingleChildScrollView(
          controller: sheetScrollController,
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    AppTexts.stopSwipeInstruction,
                    style: Theme.of(context).textTheme.labelLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => widget.onStepSelectedDate(-1),
                      tooltip: AppTexts.stopPrevDay,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onPickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          AppTexts.stopDateLabel(
                            _formatSelectedDate(widget.selectedDate),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => widget.onStepSelectedDate(1),
                      tooltip: AppTexts.stopNextDay,
                      icon: const Icon(Icons.chevron_right),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed:
                          _isSameDate(widget.selectedDate, DateTime.now())
                          ? null
                          : widget.onGoToToday,
                      child: Text(AppTexts.stopToday),
                    ),
                  ],
                ),
                if (hasPast) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: widget.onTogglePastDepartures,
                      child: Text(
                        widget.showPastDepartures
                            ? AppTexts.stopHidePast
                            : AppTexts.stopShowPast,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                AlertsSection(alerts: widget.stop['alerts']),
                StopLineSelector(
                  uniqueLines: widget.uniqueLines,
                  selectedLines: widget.selectedLines,
                  onLineSelected: widget.onLineSelected,
                  onClearSelection: widget.onClearLineSelection,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(AppTexts.stopArrivals),
                        selected: _mobileSelectedTabIndex == 0,
                        onSelected: (_) {
                          setState(() {
                            _mobileSelectedTabIndex = 0;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: Text(AppTexts.stopDepartures),
                        selected: _mobileSelectedTabIndex == 1,
                        onSelected: (_) {
                          setState(() {
                            _mobileSelectedTabIndex = 1;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: Text(AppTexts.stopSchedule),
                        selected: _mobileSelectedTabIndex == 2,
                        onSelected: (_) {
                          setState(() {
                            _mobileSelectedTabIndex = 2;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        Expanded(
          child: _mobileSelectedTabIndex == 0
              ? StopDetailsTimesList(
                  items: visibleArrivals,
                  now: now,
                  emptyMessage: AppTexts.stopNoArrivals,
                  isArrivalView: true,
                  onOpenTripDetails: widget.onOpenTripDetails,
                )
              : _mobileSelectedTabIndex == 1
                  ? StopDetailsTimesList(
                      items: visibleDepartures,
                      now: now,
                      emptyMessage: AppTexts.stopNoDepartures,
                      isArrivalView: false,
                      onOpenTripDetails: widget.onOpenTripDetails,
                    )
                  : StopDetailsSchedule(
                      items: visibleDepartures,
                      selectedLines: widget.selectedLines,
                      uniqueLines: widget.uniqueLines,
                      now: now,
                      onOpenTripDetails: widget.onOpenTripDetails,
                    ),
        ),
      ],
    );
  }
}
