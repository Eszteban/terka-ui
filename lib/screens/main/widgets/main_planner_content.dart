import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../theme/app_texts.dart';
import '../../../models/ticket_item.dart';
import '../../../widgets/forms/route_plan_form.dart';
import '../../../widgets/tables/route_planner_results_view.dart';
import '../../../controllers/route_planner_cubit.dart';
import '../../../controllers/map_cubit.dart';
import '../../../controllers/navigation_cubit.dart';
import 'main_plan_loading_view.dart';
import 'main_selected_map_card.dart';

class MainPlannerContent extends StatelessWidget {
  final bool isDesktop;
  final bool ticketWatch;
  final List<TicketItem> tickets;
  final Function(String, String)? onOpenTripDetailsRequested;

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
    required this.ticketWatch,
    required this.tickets,
    this.onOpenTripDetailsRequested,
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
    return BlocBuilder<RoutePlannerCubit, RoutePlannerState>(
      builder: (context, plannerState) {
        if (plannerState.isPlanLoading) {
          return const MainPlanLoadingView();
        }

        return BlocBuilder<MapCubit, MapState>(
          builder: (context, mapState) {
            final showTable = context.read<NavigationCubit>().state.currentSection == MainSection.table;
            final hasPlannerResultsPayload = plannerState.planResponseJson != null ||
                plannerState.hasMeaningfulPlanResponse ||
                plannerState.planResponseText.isNotEmpty;

            if (showTable && hasPlannerResultsPayload) {
              final hasDesktopMapSelection = mapState.routeOverlayData.hasContent ||
                  mapState.routeVehicleMarker != null ||
                  mapState.selectedMapPayload != null;
              final canLoadMore = (plannerState.nextPageCursor?.trim().isNotEmpty ?? false);

              return RoutePlannerResultsView(
                responseText: plannerState.planResponseText.isEmpty
                    ? AppTexts.mainDefaultPlanResponse
                    : plannerState.planResponseText,
                desktopInlineMapMode: isDesktop,
                hasDesktopMapSelection: hasDesktopMapSelection,
                canLoadMore: canLoadMore,
                isLoadingMore: plannerState.isLoadingMore,
                onLoadMore: () async {
                  final success = await context.read<RoutePlannerCubit>().loadMorePlans();
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppTexts.mainLoadMoreFailed)),
                    );
                  }
                },
                ticketWatch: ticketWatch,
                tickets: tickets,
                onShowOnMap: (payload) {
                  if (isDesktop) {
                    context.read<MapCubit>().showDesktopRouteOnBackgroundMap(
                          routeData: payload.routeData,
                          selectedPayload: payload,
                        );
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SelectedItineraryMapScreen(payload: payload),
                    ),
                  );
                },
                onShowTripOnMap: isDesktop
                    ? (routeData, vehicleMarker) {
                        context.read<MapCubit>().showDesktopRouteOnBackgroundMap(
                              routeData: routeData,
                              vehicleMarker: vehicleMarker,
                            );
                      }
                    : null,
                onOpenTripDetailsRequested: onOpenTripDetailsRequested,
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
          },
        );
      },
    );
  }
}
