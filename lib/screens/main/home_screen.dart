import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'widgets/main_planner_content.dart';
import '../../controllers/route_planner_cubit.dart';
import '../../controllers/map_cubit.dart';
import '../../models/ticket_item.dart';
import '../../repositories/ticket_repository.dart';
import '../../injection_container.dart';
import '../../theme/app_texts.dart';
import '../../widgets/forms/route_plan_form.dart';

import '../../widgets/layout/desktop_sidebar_wrapper.dart';

class HomeScreen extends StatefulWidget {
  final bool isDesktop;
  final String? initialFrom;
  final String? initialTo;
  final String? initialFromCoords;
  final String? initialToCoords;

  const HomeScreen({
    super.key,
    required this.isDesktop,
    this.initialFrom,
    this.initialTo,
    this.initialFromCoords,
    this.initialToCoords,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController1 = TextEditingController();
  final TextEditingController _searchController2 = TextEditingController();

  DateTime? _selectedDate;
  String? _preSelectedFromToken;
  String? _preSelectedToToken;
  List<double>? _preSelectedFromCoords;
  List<double>? _preSelectedToCoords;

  double _currentSliderValue = 5;
  double _currentWalkingValue = 1000;
  final Set<String> _selectedKozlekedes = {
    'Helyi busz',
    'Helyközi busz',
    'Vonat',
    'Metró',
    'Troli',
    'Villamos',
    'Hajó',
  };
  bool _jegyfigyeles = false;
  List<TicketItem> _tickets = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MapCubit>().clearRouteDataOnly();
      }
    });

    _preSelectedFromToken = widget.initialFrom;
    _preSelectedToToken = widget.initialTo;



    if (widget.initialFromCoords != null) {
      final parts = widget.initialFromCoords!.split(',');
      if (parts.length == 2) {
        _preSelectedFromCoords = [
          double.tryParse(parts[0]) ?? 0.0,
          double.tryParse(parts[1]) ?? 0.0,
        ];
      }
    }

    if (widget.initialToCoords != null) {
      final parts = widget.initialToCoords!.split(',');
      if (parts.length == 2) {
        _preSelectedToCoords = [
          double.tryParse(parts[0]) ?? 0.0,
          double.tryParse(parts[1]) ?? 0.0,
        ];
      }
    }

    _loadTickets();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFrom != oldWidget.initialFrom) {
      _preSelectedFromToken = widget.initialFrom;
    }
    if (widget.initialTo != oldWidget.initialTo) {
      _preSelectedToToken = widget.initialTo;
    }
    if (widget.initialFromCoords != oldWidget.initialFromCoords) {
      if (widget.initialFromCoords != null) {
        final parts = widget.initialFromCoords!.split(',');
        if (parts.length == 2) {
          _preSelectedFromCoords = [
            double.tryParse(parts[0]) ?? 0.0,
            double.tryParse(parts[1]) ?? 0.0,
          ];
        }
      } else {
        _preSelectedFromCoords = null;
      }
    }
    if (widget.initialToCoords != oldWidget.initialToCoords) {
      if (widget.initialToCoords != null) {
        final parts = widget.initialToCoords!.split(',');
        if (parts.length == 2) {
          _preSelectedToCoords = [
            double.tryParse(parts[0]) ?? 0.0,
            double.tryParse(parts[1]) ?? 0.0,
          ];
        }
      } else {
        _preSelectedToCoords = null;
      }
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
  Widget build(BuildContext context) {
    final content = MainPlannerContent(
      isDesktop: widget.isDesktop,
      ticketWatch: _jegyfigyeles,
      tickets: _tickets,
      fromController: _searchController1,
      toController: _searchController2,
      selectedDate: _selectedDate,
      transfers: _currentSliderValue,
      maxWalk: _currentWalkingValue,
      selectedTransportModes: _selectedKozlekedes,
      initialFromPlaceToken: _preSelectedFromToken,
      initialToPlaceToken: _preSelectedToToken,
      initialFromCoordinates: _preSelectedFromCoords,
      initialToCoordinates: _preSelectedToCoords,
      autofocusFrom:
          _preSelectedFromToken == null && _preSelectedToToken != null,
      onSearch: (PlanSearchResult result) {
        context.read<RoutePlannerCubit>().setPlanResult(result);

        final queryParams = <String, String>{};
        if (result.fromPlaceToken != null)
          queryParams['from'] = result.fromPlaceToken!;
        if (result.toPlaceToken != null)
          queryParams['to'] = result.toPlaceToken!;
        if (result.fromCoordinates != null)
          queryParams['fromCoords'] = result.fromCoordinates!.join(',');
        if (result.toCoordinates != null)
          queryParams['toCoords'] = result.toCoordinates!.join(',');
        if (_selectedDate != null)
          queryParams['date'] = _selectedDate!.toIso8601String();
        queryParams['transfers'] = _currentSliderValue.toString();
        queryParams['maxWalk'] = _currentWalkingValue.toString();
        if (_selectedKozlekedes.isNotEmpty)
          queryParams['modes'] = _selectedKozlekedes.join(',');
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
      onOpenTripDetailsRequested: (tripId, serviceDay) {
        final encodedTripId = Uri.encodeComponent(tripId);
        if (serviceDay.isNotEmpty) {
          context.push('/trip/$encodedTripId?date=$serviceDay');
        } else {
          context.push('/trip/$encodedTripId');
        }
      },
    );

    return DesktopSidebarWrapper(child: content);
  }
}
