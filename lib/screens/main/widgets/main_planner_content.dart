import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terka/theme/app_texts.dart';
import '../../../models/ticket_item.dart';
import '../../../widgets/forms/route_plan_form.dart';
import '../../../controllers/route_planner_cubit.dart';
import '../../../controllers/map_cubit.dart';
import 'main_plan_loading_view.dart';

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

  final String? initialFromPlaceToken;
  final String? initialToPlaceToken;
  final List<double>? initialFromCoordinates;
  final List<double>? initialToCoordinates;
  final bool autofocusFrom;
  final Function(String? token, List<double>? coordinates)? onFromPlaceChanged;
  final Function(String? token, List<double>? coordinates)? onToPlaceChanged;

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
    this.initialFromPlaceToken,
    this.initialToPlaceToken,
    this.initialFromCoordinates,
    this.initialToCoordinates,
    this.autofocusFrom = false,
    this.onFromPlaceChanged,
    this.onToPlaceChanged,
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
              initialFromPlaceToken: initialFromPlaceToken,
              initialToPlaceToken: initialToPlaceToken,
              initialFromCoordinates: initialFromCoordinates,
              initialToCoordinates: initialToCoordinates,
              autofocusFrom: autofocusFrom,
              onFromPlaceChanged: onFromPlaceChanged,
              onToPlaceChanged: onToPlaceChanged,
            );
          },
        );
      },
    );
  }
}
