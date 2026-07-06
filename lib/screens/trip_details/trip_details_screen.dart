import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../repositories/transit_repository.dart';
import '../../injection_container.dart';
import '../../theme/app_texts.dart';
import '../../utils/trip_details_utils.dart';
import '../../utils/adaptive_dialog_utils.dart';
import '../../widgets/maps/plan_map_view.dart';
import '../../widgets/maps/route_map_data.dart';
import '../stop_details/stop_details_screen.dart';

import 'widgets/trip_details_table_view.dart';
import 'widgets/trip_details_stop_card.dart';
import 'widgets/trip_details_bottom_card.dart';
import 'widgets/trip_details_mobile_sheet.dart';

typedef TripDetailsBackgroundMapCallback =
    void Function(RouteMapData routeData, RouteVehicleMarker? vehicleMarker);
typedef TripDetailsOpenRequestCallback =
    void Function(String tripId, String serviceDay);
typedef TripDetailsOpenStopRequestCallback =
    void Function(String stopId, String stopName);

class TripDetailsScreen extends StatefulWidget {
  final String tripId;
  final String serviceDay;
  final TripDetailsBackgroundMapCallback? onShowOnBackgroundMap;
  final VoidCallback? onCloseRequested;
  final TripDetailsOpenRequestCallback? onOpenTripDetailsRequested;
  final TripDetailsOpenStopRequestCallback? onOpenStopDetailsRequested;

  const TripDetailsScreen({
    super.key,
    required this.tripId,
    required this.serviceDay,
    this.onShowOnBackgroundMap,
    this.onCloseRequested,
    this.onOpenTripDetailsRequested,
    this.onOpenStopDetailsRequested,
  });

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  static const double _desktopBreakpoint = 600;
  final TransitRepository _transitRepository = sl<TransitRepository>();

  bool _isLoading = true;
  bool _isFetching = false;
  bool _showMap = false;
  String? _error;
  Map<String, dynamic>? _trip;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadTrip();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _loadTrip(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTrip({bool forceFullScreenLoading = false}) async {
    if (_isFetching) {
      return;
    }
    _isFetching = true;

    final isFirstLoad = _trip == null;

    if (isFirstLoad || forceFullScreenLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = null;
      });
    }

    void handleError(String message) {
      if (isFirstLoad || forceFullScreenLoading) {
        setState(() {
          _error = message;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppTexts.stopErrorUpdate(message))),
          );
        }
      }
      _isFetching = false;
    }

    try {
      final trip = await _transitRepository.fetchTripDetails(
        tripId: widget.tripId,
        serviceDay: widget.serviceDay,
      );

      if (trip == null) {
        handleError(AppTexts.tripDetailsNotAvailable);
        return;
      }

      setState(() {
        _trip = trip;
        _isLoading = false;
      });
      _isFetching = false;

      if (_isDesktopBackgroundMapMode && widget.onShowOnBackgroundMap != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _showTripOnBackgroundMap(trip, closeAfter: false);
        });
      }
    } catch (e) {
      handleError('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final useMobileMapSheet = _useMobileMapSheet;

    return PopScope(
      canPop: useMobileMapSheet ? true : !_showMap,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        if (!useMobileMapSheet && _showMap) {
          setState(() {
            _showMap = false;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            useMobileMapSheet || _showMap
                ? AppTexts.tripRouteOnMap
                : AppTexts.tripDetails,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (!useMobileMapSheet && _showMap) {
                setState(() {
                  _showMap = false;
                });
              } else {
                if (widget.onCloseRequested != null) {
                  widget.onCloseRequested!();
                } else {
                  Navigator.of(context).maybePop();
                }
              }
            },
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTrip),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _loadTrip, child: Text(AppTexts.retry)),
            ],
          ),
        ),
      );
    }

    final trip = _trip;
    if (trip == null) {
      return Center(child: Text(AppTexts.noData));
    }

    if (_useMobileMapSheet) {
      return TripDetailsMobileSheet(
        trip: trip,
        tripId: widget.tripId,
        serviceDay: widget.serviceDay,
        onStopTap: ({
          required stopId,
          required stopName,
          required initialStopPoint,
        }) {
          _openStopDetails(
            stopId: stopId,
            stopName: stopName,
            initialStopPoint: initialStopPoint,
          );
        },
        stopInfoCardBuilder: (context, stop) => TripDetailsStopCard(
          stop: stop,
          onOpenStopDetails: ({
            required stopId,
            required stopName,
            required initialStopPoint,
          }) {
            _openStopDetails(
              stopId: stopId,
              stopName: stopName,
              initialStopPoint: initialStopPoint,
            );
          },
        ),
      );
    }

    return _showMap
        ? _buildMapView(trip)
        : TripDetailsTableView(
            trip: trip,
            serviceDay: widget.serviceDay,
            onStopTap: ({
              required stopId,
              required stopName,
              required initialStopPoint,
            }) {
              _openStopDetails(
                stopId: stopId,
                stopName: stopName,
                initialStopPoint: initialStopPoint,
              );
            },
          );
  }

  bool get _isDesktopBackgroundMapMode {
    return widget.onShowOnBackgroundMap != null &&
        MediaQuery.of(context).size.width > _desktopBreakpoint;
  }

  bool get _useMobileMapSheet {
    return MediaQuery.of(context).size.width <= _desktopBreakpoint;
  }

  Future<void> _openStopDetails({
    required String stopId,
    required String stopName,
    LatLng? initialStopPoint,
  }) async {
    final isDesktop = MediaQuery.of(context).size.width > _desktopBreakpoint;

    if (isDesktop && widget.onOpenStopDetailsRequested != null) {
      widget.onOpenStopDetailsRequested!(stopId, stopName);
      return;
    }

    if (_isDesktopBackgroundMapMode) {
      await showAdaptiveDetailsDialog<void>(
        context: context,
        child: StopDetailsScreen(
          stopId: stopId,
          initialStopName: stopName,
          initialStopPoint: initialStopPoint,
          onShowTripOnBackgroundMap: widget.onShowOnBackgroundMap,
          onOpenTripDetailsRequested: widget.onOpenTripDetailsRequested,
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StopDetailsScreen(
          stopId: stopId,
          initialStopName: stopName,
          initialStopPoint: initialStopPoint,
          onShowTripOnBackgroundMap: widget.onShowOnBackgroundMap,
          onOpenTripDetailsRequested: widget.onOpenTripDetailsRequested,
        ),
      ),
    );
  }

  void _showTripOnBackgroundMap(
    Map<String, dynamic> trip, {
    required bool closeAfter,
  }) {
    final routeData = TripDetailsUtils.buildTripRouteMapData(trip);
    final vehicleMarker =
        TripDetailsUtils.buildTripVehicleMarker(trip, widget.tripId);

    if (_isDesktopBackgroundMapMode &&
        widget.onShowOnBackgroundMap != null &&
        (routeData.hasContent || vehicleMarker != null)) {
      widget.onShowOnBackgroundMap!(routeData, vehicleMarker);
      if (closeAfter) {
        if (widget.onCloseRequested != null) {
          widget.onCloseRequested!();
        } else {
          Navigator.of(context).maybePop();
        }
      }
      return;
    }

    if (!closeAfter) {
      return;
    }

    setState(() {
      _showMap = true;
    });
  }

  Widget _buildMapView(Map<String, dynamic> trip) {
    final routeData = TripDetailsUtils.buildTripRouteMapData(trip);
    final route = TripDetailsUtils.route(trip);
    final routeColor =
        TripDetailsUtils.hexColor(route['color']?.toString() ?? '0A84FF');
    final routeTextColor = TripDetailsUtils.hexColor(
      route['textColor']?.toString() ?? 'FFFFFF',
    );
    final vehicleMarker =
        TripDetailsUtils.buildTripVehicleMarker(trip, widget.tripId);

    return Stack(
      children: [
        Positioned.fill(
          child: PlanMapView(
            routeData: routeData,
            controlsBottomInset: 220,
            fitPadding: const EdgeInsets.fromLTRB(48, 48, 48, 320),
            showStopLabels: false,
            useBaseMapStopIcon: true,
            vehicleMarker: vehicleMarker,
            enableVehicleInfoLabelTap: vehicleMarker != null,
            vehicleInfoCardBuilder: vehicleMarker == null
                ? null
                : (context) => TripDetailsUtils.buildVehicleTapInfoCard(
                      trip: trip,
                      routeColor: routeColor,
                      routeTextColor: routeTextColor,
                    ),
            enableStopInfoLabelTap: true,
            stopInfoCardBuilder: (context, stop) => TripDetailsStopCard(
              stop: stop,
              onOpenStopDetails: ({
                required stopId,
                required stopName,
                required initialStopPoint,
              }) {
                _openStopDetails(
                  stopId: stopId,
                  stopName: stopName,
                  initialStopPoint: initialStopPoint,
                );
              },
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: SafeArea(
            top: false,
            child: TripDetailsBottomCard(
              trip: trip,
              routeColor: routeColor,
              routeTextColor: routeTextColor,
              onBack: () {
                setState(() {
                  _showMap = false;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
