import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../utils/trip_details_utils.dart';
import '../../theme/app_texts.dart';
import '../realtime_time_text.dart';
import '../alerts_section.dart';

class StopTimesDataTable extends StatelessWidget {
  final List<Map<String, dynamic>> stopTimes;
  final String serviceDay;
  final void Function({
    required String stopId,
    required String stopName,
    required LatLng? initialStopPoint,
  }) onStopTap;

  const StopTimesDataTable({
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
        columns: [
          DataColumn(label: Text(AppTexts.tripStopColumn)),
          DataColumn(label: Text(AppTexts.stopTimeLabel), numeric: true),
        ],
        rows: stopTimes.map((stopTime) {
          final stop = stopTime['stop'];
          final stopName = TripDetailsUtils.plainText(
            stop is Map ? (stop['name']?.toString() ?? '-') : '-',
          );
          final stopId = stop is Map
              ? (stop['id']?.toString().trim() ?? '')
              : '';
          final passedStop = TripDetailsUtils.isPassedStop(stopTime, serviceDay);

          final alertsList = stop is Map ? stop['alerts'] as List? : null;
          final hasAlerts = alertsList != null && alertsList.any((a) {
            if (a is! Map) return false;
            final header = a['alertHeaderText']?.toString().trim() ?? '';
            final desc = a['alertDescriptionText']?.toString().trim() ?? '';
            return header.isNotEmpty || desc.isNotEmpty;
          });

          LatLng? point;
          if (stop is Map && stop['lat'] is num && stop['lon'] is num) {
            point = LatLng(
              (stop['lat'] as num).toDouble(),
              (stop['lon'] as num).toDouble(),
            );
          }

          final scheduledArr = TripDetailsUtils.asNum(stopTime['scheduledArrival']);
          final realtimeArr = TripDetailsUtils.asNum(stopTime['realtimeArrival']);
          final arrDelay = TripDetailsUtils.asNum(stopTime['arrivalDelay']);

          final scheduledDep = TripDetailsUtils.asNum(stopTime['scheduledDeparture']);
          final realtimeDep = TripDetailsUtils.asNum(stopTime['realtimeDeparture']);
          final depDelay = TripDetailsUtils.asNum(stopTime['departureDelay']);

          final isRealtime = stopTime['realtime'] == true;

          final isSameTime =
              realtimeArr != null &&
              realtimeDep != null &&
              realtimeArr == realtimeDep &&
              scheduledArr == scheduledDep;

          final String? customTooltipMsg;
          if (scheduledArr != null && scheduledDep != null && scheduledArr != scheduledDep) {
            customTooltipMsg = AppTexts.tripScheduledTimeRange(
              TripDetailsUtils.formatEpoch(scheduledArr, serviceDay),
              TripDetailsUtils.formatEpoch(scheduledDep, serviceDay),
            );
          } else {
            customTooltipMsg = null;
          }

          Widget timeCell;
          if (realtimeArr == null && realtimeDep == null) {
            timeCell = const Text('-');
          } else if (realtimeArr == null) {
            // First stop: show only departure
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
            // Last stop: show only arrival
            timeCell = RealtimeTimeText(
              scheduled: scheduledArr,
              realtime: realtimeArr,
              delay: arrDelay,
              isRealtime: isRealtime,
              passedStop: passedStop,
              serviceDay: serviceDay,
              tooltipType: 'arrival',
              customTooltip: customTooltipMsg,
            );
          } else if (isSameTime) {
            // Arrival and departure are equal
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
            // Arrival and departure differ: show stacked
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
                    return SizedBox(
                      width: 240,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: stopId.isNotEmpty
                                ? InkWell(
                                    onTap: () => onStopTap(
                                      stopId: stopId,
                                      stopName: stopName,
                                      initialStopPoint: point,
                                    ),
                                    child: Text(
                                      stopName,
                                      style: const TextStyle(
                                        decoration: TextDecoration.underline,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                : Text(
                                    stopName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
