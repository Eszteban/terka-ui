import 'package:flutter/material.dart';
import '../../../utils/stop_details_utils.dart';
import '../../../widgets/departure_card.dart';
import 'package:terka/theme/app_tokens.dart';

class StopDetailsTimesList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final DateTime now;
  final String emptyMessage;
  final bool isArrivalView;
  final void Function({
    required String tripId,
    required String serviceDay,
  })? onOpenTripDetails;

  const StopDetailsTimesList({
    super.key,
    required this.items,
    required this.now,
    required this.emptyMessage,
    this.isArrivalView = false,
    this.onOpenTripDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      shrinkWrap: true,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final departure = items[index];
        final trip = departure['trip'];
        final tripId = trip is Map ? trip['gtfsId']?.toString() ?? '' : '';
        final serviceDay = StopDetailsUtils.serviceDayToYmd(
          StopDetailsUtils.asNum(departure['serviceDay']),
        );
        final canOpenTrip = tripId.trim().isNotEmpty && serviceDay.isNotEmpty;
        return DepartureCard(
          departure: departure,
          now: now,
          isArrivalView: isArrivalView,
          onTap: canOpenTrip && onOpenTripDetails != null
              ? () => onOpenTripDetails!(
                    tripId: tripId,
                    serviceDay: serviceDay,
                  )
              : null,
        );
      },
    );
  }
}
