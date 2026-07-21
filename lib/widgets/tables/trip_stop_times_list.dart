import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../utils/trip_details_utils.dart';
import '../../theme/app_texts.dart';
import '../realtime_time_text.dart';
import '../alerts_section.dart';
import '../../models/trip_stop_time.dart';

class TripStopTimesList extends StatelessWidget {
  final List<TripStopTime> stopTimes;
  final String serviceDay;
  final void Function({
    required String stopId,
    required String stopName,
    required LatLng? initialStopPoint,
  }) onStopTap;

  const TripStopTimesList({
    super.key,
    required this.stopTimes,
    required this.serviceDay,
    required this.onStopTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 64,
        columns: [
          DataColumn(label: Text(AppTexts.tripStopColumn)),
          DataColumn(label: Text(AppTexts.stopTimeLabel), numeric: true),
        ],
        rows: stopTimes.map((stopTime) {
          final stop = stopTime.stop;
          final stopName = TripDetailsUtils.plainText(stop.name);
          final stopId = stop.id;
          final platformCode = stop.platformCode;
          final passedStop = TripDetailsUtils.isPassedStop(stopTime, serviceDay);

          final alertsList = stop.alerts;
          final hasAlerts = alertsList != null && alertsList.any((a) {
            if (a is! Map) return false;
            final header = a['alertHeaderText']?.toString().trim() ?? '';
            final desc = a['alertDescriptionText']?.toString().trim() ?? '';
            return header.isNotEmpty || desc.isNotEmpty;
          });

          final LatLng? point = (stop.lat != null && stop.lon != null)
              ? LatLng(stop.lat!, stop.lon!)
              : null;

          final scheduledArr = stopTime.scheduledArrival;
          final arrDelay = stopTime.arrivalDelay;
          final realtimeArr = (scheduledArr != null && arrDelay != null)
              ? scheduledArr + arrDelay
              : stopTime.realtimeArrival;

          final scheduledDep = stopTime.scheduledDeparture;
          final depDelay = stopTime.departureDelay;
          final realtimeDep = (scheduledDep != null && depDelay != null)
              ? scheduledDep + depDelay
              : stopTime.realtimeDeparture;

          final isRealtime = stopTime.isRealtime;

          final isSameTime =
              realtimeArr != null &&
              realtimeDep != null &&
              realtimeArr == realtimeDep &&
              scheduledArr == scheduledDep;

          final String? customTooltipMsg = (scheduledArr != null && scheduledDep != null && scheduledArr != scheduledDep)
              ? AppTexts.tripScheduledTimeRange(
                  TripDetailsUtils.formatEpoch(scheduledArr, serviceDay),
                  TripDetailsUtils.formatEpoch(scheduledDep, serviceDay),
                )
              : null;

          final String? restrictionText = stopTime.pickupType?.toUpperCase() == 'NONE'
              ? AppTexts.alightingOnly
              : stopTime.dropoffType?.toUpperCase() == 'NONE'
                  ? AppTexts.boardingOnly
                  : null;

          Widget timeCell;
          if (realtimeArr == null && realtimeDep == null) {
            timeCell = const Text('-');
          } else if (realtimeArr == null) {
            timeCell = RealtimeTimeText(
              scheduled: scheduledDep,
              realtime: realtimeDep,
              delay: depDelay,
              isRealtime: isRealtime,
              passedStop: passedStop,
              serviceDay: serviceDay,
              tooltipType: 'departure',
              customTooltip: customTooltipMsg,
            );
          } else if (realtimeDep == null) {
            timeCell = RealtimeTimeText(
              scheduled: scheduledArr,
              realtime: realtimeArr,
              delay: arrDelay,
              isRealtime: isRealtime,
              passedStop: passedStop,
              serviceDay: serviceDay,
              tooltipType: 'alignment',
              customTooltip: customTooltipMsg,
            );
          } else if (isSameTime) {
            timeCell = RealtimeTimeText(
              scheduled: scheduledDep,
              realtime: realtimeDep,
              delay: depDelay,
              isRealtime: isRealtime,
              passedStop: passedStop,
              serviceDay: serviceDay,
              customTooltip: customTooltipMsg,
            );
          } else {
            timeCell = Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                RealtimeTimeText(
                  scheduled: scheduledArr,
                  realtime: realtimeArr,
                  delay: arrDelay,
                  isRealtime: isRealtime,
                  passedStop: passedStop,
                  serviceDay: serviceDay,
                  suffix: '-',
                  tooltipType: 'arrival',
                  customTooltip: customTooltipMsg,
                ),
                const SizedBox(height: 2),
                RealtimeTimeText(
                  scheduled: scheduledDep,
                  realtime: realtimeDep,
                  delay: depDelay,
                  isRealtime: isRealtime,
                  passedStop: passedStop,
                  serviceDay: serviceDay,
                  suffix: '',
                  tooltipType: 'departure',
                  customTooltip: customTooltipMsg,
                ),
              ],
            );
          }

          return DataRow(
            cells: [
              DataCell(
                Builder(
                  builder: (context) {
                    final stopWidget = stopId.isNotEmpty
                        ? InkWell(
                            onTap: () => onStopTap(
                              stopId: stopId,
                              stopName: stopName,
                              initialStopPoint: point,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    stopName,
                                    style: const TextStyle(
                                      decoration: TextDecoration.underline,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (platformCode.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      platformCode,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  stopName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (platformCode.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    platformCode,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );

                    final contentWidget = restrictionText != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              stopWidget,
                              const SizedBox(height: 2),
                              Text(
                                restrictionText,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : stopWidget;

                    return SizedBox(
                      width: 240,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: contentWidget,
                          ),
                          if (hasAlerts) ...[
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () {
                                _showStopAlertsDialog(context, stopName, alertsList);
                              },
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                                size: 18,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              DataCell(timeCell),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showStopAlertsDialog(
    BuildContext context,
    String stopName,
    List<dynamic> alerts,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            stopName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: AlertsSection(alerts: alerts),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
