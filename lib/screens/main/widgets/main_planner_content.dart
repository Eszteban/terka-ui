import 'package:flutter/material.dart';
import '../../../theme/app_texts.dart';
import '../../../models/ticket_item.dart';
import '../../../widgets/forms/route_plan_form.dart';
import '../../../widgets/tables/dummy_table.dart';
import '../../../widgets/maps/route_map_data.dart';
import 'main_plan_loading_view.dart';
import 'main_selected_map_card.dart';

class MainPlannerContent extends StatelessWidget {
  final bool isDesktop;
  final bool isPlanLoading;
  final bool showTable;
  final bool hasPlannerResultsPayload;
  final String planResponseText;
  final bool hasDesktopMapSelection;
  final bool canLoadMore;
  final bool isLoadingMore;
  final Future<void> Function() onLoadMore;
  final bool ticketWatch;
  final List<TicketItem> tickets;
  final ValueChanged<SelectedItineraryMapPayload> onShowOnMap;
  final Function(RouteMapData, RouteVehicleMarker?)? onShowTripOnMap;

  // Form properties:
  final TextEditingController fromController;
  final TextEditingController toController;
  final DateTime? selectedDate;
  final double transfers;
  final double maxWalk;
  final Set<String> selectedTransportModes;
  final ValueChanged<PlanSearchResult> onSearch;
  final ValueChanged<bool> onLoadingChanged;
  final VoidCallback onPickDate;
  final ValueChanged<double> onTransfersChanged;
  final ValueChanged<double> onMaxWalkChanged;
  final ValueChanged<String> onTransportModeToggle;
  final ValueChanged<bool> onTicketWatchChanged;

  const MainPlannerContent({
    super.key,
    required this.isDesktop,
    required this.isPlanLoading,
    required this.showTable,
    required this.hasPlannerResultsPayload,
    required this.planResponseText,
    required this.hasDesktopMapSelection,
    required this.canLoadMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.ticketWatch,
    required this.tickets,
    required this.onShowOnMap,
    required this.onShowTripOnMap,
    required this.fromController,
    required this.toController,
    required this.selectedDate,
    required this.transfers,
    required this.maxWalk,
    required this.selectedTransportModes,
    required this.onSearch,
    required this.onLoadingChanged,
    required this.onPickDate,
    required this.onTransfersChanged,
    required this.onMaxWalkChanged,
    required this.onTransportModeToggle,
    required this.onTicketWatchChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isPlanLoading) {
      return const MainPlanLoadingView();
    }

    if (showTable && hasPlannerResultsPayload) {
      return DummyTable(
        responseText: planResponseText.isEmpty
            ? AppTexts.mainDefaultPlanResponse
            : planResponseText,
        desktopInlineMapMode: isDesktop,
        hasDesktopMapSelection: hasDesktopMapSelection,
        canLoadMore: canLoadMore,
        isLoadingMore: isLoadingMore,
        onLoadMore: onLoadMore,
        ticketWatch: ticketWatch,
        tickets: tickets,
        onShowOnMap: (payload) {
          if (isDesktop) {
            onShowOnMap(payload);
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SelectedItineraryMapScreen(payload: payload),
            ),
          );
        },
        onShowTripOnMap: isDesktop ? onShowTripOnMap : null,
      );
    }

    return RoutePlanForm(
      fromController: fromController,
      toController: toController,
      selectedDate: selectedDate,
      transfers: transfers,
      maxWalk: maxWalk,
      selectedTransportModes: selectedTransportModes,
      ticketWatch: ticketWatch,
      onSearch: onSearch,
      onLoadingChanged: onLoadingChanged,
      onPickDate: onPickDate,
      onTransfersChanged: onTransfersChanged,
      onMaxWalkChanged: onMaxWalkChanged,
      onTransportModeToggle: onTransportModeToggle,
      onTicketWatchChanged: onTicketWatchChanged,
    );
  }
}
