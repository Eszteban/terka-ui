import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/route_planner_cubit.dart';
import '../../controllers/map_cubit.dart';
import '../../utils/layout_provider.dart';
import '../../widgets/tables/route_planner_results_view.dart';
import '../../models/ticket_item.dart';
import '../../repositories/ticket_repository.dart';
import '../../injection_container.dart';
import 'package:terka/theme/app_texts.dart';
import '../../widgets/forms/route_plan_form.dart';
import 'package:terka/screens/main/widgets/main_selected_map_card.dart';

import '../../widgets/layout/desktop_sidebar_wrapper.dart';

class PlanScreen extends StatefulWidget {
  final String? from;
  final String? to;
  final String? fromCoords;
  final String? toCoords;
  final String? date;
  final String? transfers;
  final String? maxWalk;
  final String? modes;
  final String? ticketWatch;

  const PlanScreen({
    super.key,
    this.from,
    this.to,
    this.fromCoords,
    this.toCoords,
    this.date,
    this.transfers,
    this.maxWalk,
    this.modes,
    this.ticketWatch,
  });

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  late final TextEditingController _searchController1;
  late final TextEditingController _searchController2;

  DateTime? _selectedDate;
  String? _preSelectedFromToken;
  String? _preSelectedToToken;
  List<double>? _preSelectedFromCoords;
  List<double>? _preSelectedToCoords;

  double _currentSliderValue = 5;
  double _currentWalkingValue = 1000;
  Set<String> _selectedKozlekedes = {};
  bool _jegyfigyeles = false;
  List<TicketItem> _tickets = const [];

  @override
  void initState() {
    super.initState();
    _searchController1 = TextEditingController();
    _searchController2 = TextEditingController();
    _loadTickets();
    _initFromProps();
  }

  @override
  void didUpdateWidget(covariant PlanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.from != oldWidget.from ||
        widget.to != oldWidget.to ||
        widget.date != oldWidget.date ||
        widget.transfers != oldWidget.transfers ||
        widget.maxWalk != oldWidget.maxWalk ||
        widget.modes != oldWidget.modes ||
        widget.ticketWatch != oldWidget.ticketWatch) {
      _initFromProps();
    }
  }

  void _initFromProps() {
    _preSelectedFromToken = widget.from;
    _preSelectedToToken = widget.to;

    if (widget.from != null) {
      final parts = widget.from!.split('::');
      _searchController1.text = parts.isNotEmpty ? parts[0] : widget.from!;
    } else {
      _searchController1.text = '';
    }

    if (widget.to != null) {
      final parts = widget.to!.split('::');
      _searchController2.text = parts.isNotEmpty ? parts[0] : widget.to!;
    } else {
      _searchController2.text = '';
    }

    if (widget.fromCoords != null && widget.fromCoords!.isNotEmpty) {
      final parts = widget.fromCoords!.split(',');
      if (parts.length == 2) {
        _preSelectedFromCoords = [double.tryParse(parts[0]) ?? 0, double.tryParse(parts[1]) ?? 0];
      }
    }

    if (widget.toCoords != null && widget.toCoords!.isNotEmpty) {
      final parts = widget.toCoords!.split(',');
      if (parts.length == 2) {
        _preSelectedToCoords = [double.tryParse(parts[0]) ?? 0, double.tryParse(parts[1]) ?? 0];
      }
    }

    if (widget.date != null && widget.date!.isNotEmpty) {
      _selectedDate = DateTime.tryParse(widget.date!);
    }

    if (widget.transfers != null && widget.transfers!.isNotEmpty) {
      _currentSliderValue = double.tryParse(widget.transfers!) ?? 5;
    }

    if (widget.maxWalk != null && widget.maxWalk!.isNotEmpty) {
      _currentWalkingValue = double.tryParse(widget.maxWalk!) ?? 1000;
    }

    if (widget.modes != null && widget.modes!.isNotEmpty) {
      _selectedKozlekedes.clear();
      _selectedKozlekedes.addAll(widget.modes!.split(','));
    } else {
      _selectedKozlekedes.addAll({
        'Helyi busz',
        'Helyközi busz',
        'Vonat',
        'Metró',
        'Troli',
        'Villamos',
        'Hajó',
      });
    }

    if (widget.ticketWatch != null && widget.ticketWatch!.isNotEmpty) {
      _jegyfigyeles = widget.ticketWatch == 'true';
    }
  }

  Future<void> _loadTickets() async {
    final result = await sl<TicketRepository>().fetchTickets();
    if (mounted) {
      setState(() {
        _tickets = result.tickets;
      });
    }
  }

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _toggleTransportMode(String label) {
    setState(() {
      if (_selectedKozlekedes.contains(label)) {
        _selectedKozlekedes.remove(label);
      } else {
        _selectedKozlekedes.add(label);
      }
    });
  }

  @override
  void dispose() {
    _searchController1.dispose();
    _searchController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = LayoutProvider.isDesktop(context);

    final content = BlocBuilder<RoutePlannerCubit, RoutePlannerState>(
      builder: (context, plannerState) {
        final hasDesktopMapSelection = context.read<MapCubit>().state.routeOverlayData.hasContent ||
            context.read<MapCubit>().state.routeVehicleMarker != null ||
            context.read<MapCubit>().state.selectedMapPayload != null;
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
          onOpenTripDetailsRequested: (tripId, serviceDay) {
            final encodedTripId = Uri.encodeComponent(tripId);
            if (serviceDay.isNotEmpty) {
              context.push('/trip/$encodedTripId?date=$serviceDay');
            } else {
              context.push('/trip/$encodedTripId');
            }
          },
          ticketWatch: _jegyfigyeles,
          tickets: _tickets,
          fromController: _searchController1,
          toController: _searchController2,
          selectedDate: _selectedDate,
          transfers: _currentSliderValue,
          maxWalk: _currentWalkingValue,
          selectedTransportModes: _selectedKozlekedes,
          onSearch: (PlanSearchResult result) {
            context.read<RoutePlannerCubit>().setPlanResult(result);
            
            final queryParams = <String, String>{};
            if (result.fromPlaceToken != null) queryParams['from'] = result.fromPlaceToken!;
            if (result.toPlaceToken != null) queryParams['to'] = result.toPlaceToken!;
            if (result.fromCoordinates != null) queryParams['fromCoords'] = result.fromCoordinates!.join(',');
            if (result.toCoordinates != null) queryParams['toCoords'] = result.toCoordinates!.join(',');
            if (_selectedDate != null) queryParams['date'] = _selectedDate!.toIso8601String();
            queryParams['transfers'] = _currentSliderValue.toString();
            queryParams['maxWalk'] = _currentWalkingValue.toString();
            if (_selectedKozlekedes.isNotEmpty) queryParams['modes'] = _selectedKozlekedes.join(',');
            queryParams['ticketWatch'] = _jegyfigyeles.toString();

            context.go(Uri(path: '/plan', queryParameters: queryParams).toString());
          },
          onLoadingChanged: (isLoading) {
            context.read<RoutePlannerCubit>().setLoading(isLoading);
          },
          onPickDate: _pickDate,
          onTransfersChanged: (value) {
            setState(() {
              _currentSliderValue = value;
            });
          },
          onMaxWalkChanged: (value) {
            setState(() {
              _currentWalkingValue = value;
            });
          },
          onTransportModeToggle: _toggleTransportMode,
          onTicketWatchChanged: (value) {
            setState(() {
              _jegyfigyeles = value;
            });
          },
          initialFromPlaceToken: _preSelectedFromToken,
          initialToPlaceToken: _preSelectedToToken,
          initialFromCoordinates: _preSelectedFromCoords,
          initialToCoordinates: _preSelectedToCoords,
          onFromPlaceChanged: (token, coords) {
            setState(() {
              _preSelectedFromToken = token;
              _preSelectedFromCoords = coords;
            });
          },
          onToPlaceChanged: (token, coords) {
            setState(() {
              _preSelectedToToken = token;
              _preSelectedToCoords = coords;
            });
          },
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
        );
      },
    );

    return DesktopSidebarWrapper(
      applyPaddingOnMobile: true,
      child: content,
    );
  }
}
