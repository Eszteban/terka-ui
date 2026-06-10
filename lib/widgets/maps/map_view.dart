import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_texts.dart';

import '../../services/graphql/graphql_client.dart';
import '../../services/graphql/graphql_queries.dart';
import '../../utils/markup_text_utils.dart';
import '../../utils/vehicle_type_lookup.dart';
import '../../screens/stop_details_screen.dart';
import '../../screens/trip_details_screen.dart';
import 'map_initialization_utils.dart';
import 'route_map_data.dart';
import 'vehicle_info_card.dart';

part 'map_view_models.dart';
part 'map_view_overlays.dart';
part 'map_view_helpers.dart';
part 'map_view_interactions.dart';
part 'map_view_initialization.dart';
part 'map_view_vehicle_layers.dart';

class MapView extends StatefulWidget {
  final double controlsBottomInset;
  final bool showMyLocationButton;
  final bool showRotationControls;
  final RouteMapData? routeOverlayData;
  final RouteVehicleMarker? routeVehicleMarker;
  final EdgeInsets routeFitPadding;
  final bool showRouteStopLabels;
  final bool useBaseMapStopIcon;
  final TripDetailsBackgroundMapCallback? onShowTripOnBackgroundMap;

  const MapView({
    super.key,
    this.controlsBottomInset = 0,
    this.showMyLocationButton = true,
    this.showRotationControls = true,
    this.routeOverlayData,
    this.routeVehicleMarker,
    this.routeFitPadding = const EdgeInsets.all(48),
    this.showRouteStopLabels = false,
    this.useBaseMapStopIcon = true,
    this.onShowTripOnBackgroundMap,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final GraphqlClient _graphqlClient = const GraphqlClient();
  static const double _minZoom = 3;
  static const double _maxZoom = 19;
  static const double _coachMinZoom = 10;
  static const double _localMinZoom = 13;
  static const double _stopMinZoom = 15;
  static const String _lastLatKey = 'last_lat';
  static const String _lastLonKey = 'last_lon';

  static const List<String> _railModes = [
    'RAIL',
    'RAIL_REPLACEMENT_BUS',
    'SUBURBAN_RAILWAY',
    'TRAMTRAIN',
  ];
  static const List<String> _coachModes = ['COACH'];
  static const List<String> _localModes = [
    'BUS',
    'SUBWAY',
    'TRAM',
    'TROLLEYBUS',
    'FERRY',
  ];
  static const Set<String> _fallbackWhiteHexColors = {'FFFFFF', 'FEFEFE'};
  static const String _spanFontFamily = 'MNR2007';
  static const double _spanFontScale = 28 / 16;

  late final Future<bool> _mapReady = canLoadMapTiles();
  final MapController _mapController = MapController();
  late final StreamSubscription<MapEvent> _mapEventSubscription;
  Timer? _vehicleRefreshDebounce;
  Timer? _vehiclePeriodicRefresh;
  int _vehicleRequestNonce = 0;
  List<_VehicleMarkerData> _vehicleMarkers = const [];
  List<_MapStopData> _nearbyStops = const [];
  String? _selectedVehicleMarkerId;
  String? _selectedStopMarkerId;
  _StopQuickInfo? _selectedStopQuickInfo;
  bool _isLoadingSelectedStopQuickInfo = false;
  bool _isRotated = false;
  bool _isLocating = false;
  bool _isLoadingVehicles = false;
  bool _isRotationGestureEnabled = false;
  bool _suppressNextMapTapClose = false;
  bool _didTryInitialGpsFocus = false;
  LatLng? _lastStoredLocation;

  @override
  void initState() {
    super.initState();
    _mapEventSubscription = _mapController.mapEventStream.listen((event) {
      final rotated = event.camera.rotation.abs() > 0.1;
      if (rotated != _isRotated && mounted) {
        setState(() {
          _isRotated = rotated;
        });
      }
    });
    _loadLastLocation().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (_hasRouteOverlayContent) {
          _fitToOverlayRoute();
        } else {
          _tryInitialGpsFocus();
        }
        _scheduleVehicleRefresh();
      });
    });
    _vehiclePeriodicRefresh = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) {
        return;
      }
      _refreshVehiclesForVisibleBounds();
    });
  }

  @override
  void didUpdateWidget(covariant MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeOverlayData != widget.routeOverlayData ||
        oldWidget.routeVehicleMarker != widget.routeVehicleMarker ||
        oldWidget.routeFitPadding != widget.routeFitPadding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_hasRouteOverlayContent) {
          return;
        }
        _fitToOverlayRoute();
      });
    }
  }

  bool get _hasRouteOverlayContent {
    return (widget.routeOverlayData?.hasContent ?? false) ||
        widget.routeVehicleMarker != null;
  }

  bool get _useDesktopDialogs {
    return MediaQuery.of(context).size.width >
        StopDetailsScreen.desktopBreakpoint;
  }

  List<LatLng> _overlayRoutePoints() {
    final points = <LatLng>[];
    final routeData = widget.routeOverlayData;
    if (routeData != null) {
      for (final segment in routeData.segments) {
        points.addAll(segment.points);
      }
      for (final stop in routeData.stops) {
        points.add(stop.point);
      }
    }
    if (widget.routeVehicleMarker != null) {
      points.add(widget.routeVehicleMarker!.point);
    }
    return points;
  }

  CameraFit? _initialOverlayCameraFit() {
    final points = _overlayRoutePoints();
    if (points.length < 2) {
      return null;
    }
    return CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(points),
      padding: widget.routeFitPadding,
    );
  }

  LatLng? _overlayRouteFallbackCenter() {
    final routeData = widget.routeOverlayData;
    if (routeData != null) {
      if (routeData.segments.isNotEmpty &&
          routeData.segments.first.points.isNotEmpty) {
        return routeData.segments.first.points.first;
      }
      if (routeData.stops.isNotEmpty) {
        return routeData.stops.first.point;
      }
    }
    return widget.routeVehicleMarker?.point;
  }

  void _fitToOverlayRoute() {
    if (!_hasRouteOverlayContent) {
      return;
    }

    final points = _overlayRoutePoints();
    if (points.isEmpty) {
      return;
    }

    if (points.length == 1) {
      _mapController.move(
        points.first,
        _mapController.camera.zoom < 14 ? 14 : _mapController.camera.zoom,
      );
      return;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: widget.routeFitPadding,
      ),
    );
  }

  Color _routeStopColor(RouteStopType type) {
    switch (type) {
      case RouteStopType.start:
        return Colors.green;
      case RouteStopType.transfer:
        return Colors.orange;
      case RouteStopType.end:
        return Colors.red;
    }
  }

  Widget _buildRouteVehicleDot(RouteVehicleMarker vehicle) {
    final angle = vehicle.headingDegrees * (3.141592653589793 / 180);
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: vehicle.markerColor,
              border: Border.all(color: vehicle.markerTextColor, width: 2.2),
            ),
          ),
          Transform.rotate(
            angle: angle,
            child: Icon(
              Icons.navigation,
              size: 16,
              color: vehicle.markerTextColor,
            ),
          ),
        ],
      ),
    );
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final newZoom = (camera.zoom + delta).clamp(_minZoom, _maxZoom);
    _mapController.move(camera.center, newZoom);
    _scheduleVehicleRefresh();
  }

  void _resetNorth() {
    _mapController.rotate(0);
  }

  void _toggleRotationGesture() {
    setState(() {
      _isRotationGestureEnabled = !_isRotationGestureEnabled;
    });

    if (!_isRotationGestureEnabled) {
      _resetNorth();
    }
  }

  void _moveToPosition(Position position) {
    final camera = _mapController.camera;
    _mapController.move(
      LatLng(position.latitude, position.longitude),
      camera.zoom < 15 ? 15 : camera.zoom,
    );
    unawaited(_saveLastLocation(position.latitude, position.longitude));
  }

  void _scheduleVehicleRefresh() {
    _vehicleRefreshDebounce?.cancel();
    _vehicleRefreshDebounce = Timer(
      const Duration(milliseconds: 420),
      _refreshVehiclesForVisibleBounds,
    );
  }

  List<String> _modesForZoom(double zoom) {
    final modes = <String>[..._railModes];
    if (zoom >= _coachMinZoom) {
      modes.addAll(_coachModes);
    }
    if (zoom >= _localMinZoom) {
      modes.addAll(_localModes);
    }
    return modes;
  }

  int _maxVehiclesForZoom(double zoom) {
    if (zoom < _coachMinZoom) {
      return 260;
    }
    if (zoom < _localMinZoom) {
      return 700;
    }
    return 1300;
  }

  int _maxStopsForZoom(double zoom) {
    if (zoom < 16) {
      return 600;
    }
    if (zoom < 17) {
      return 900;
    }
    return 1400;
  }

  @override
  void dispose() {
    _vehicleRefreshDebounce?.cancel();
    _vehiclePeriodicRefresh?.cancel();
    _mapEventSubscription.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _mapReady,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data != true) {
          return Center(child: Text(AppTexts.mapLoadFailed));
        }

        final routeData = widget.routeOverlayData;
        final initialOverlayFit = _initialOverlayCameraFit();
        final initialCenter =
            _overlayRouteFallbackCenter() ??
            _lastStoredLocation ??
            LatLng(47.497913, 19.040236);
        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: initialOverlayFit != null
                  ? MapOptions(
                      initialCameraFit: initialOverlayFit,
                      minZoom: _minZoom,
                      maxZoom: _maxZoom,
                      onTap: (_, _) {
                        if (_suppressNextMapTapClose) {
                          _suppressNextMapTapClose = false;
                          return;
                        }
                        if (_selectedVehicleMarkerId != null ||
                            _selectedStopMarkerId != null) {
                          setState(() {
                            _selectedVehicleMarkerId = null;
                            _selectedStopMarkerId = null;
                            _selectedStopQuickInfo = null;
                            _isLoadingSelectedStopQuickInfo = false;
                          });
                        }
                      },
                      onPositionChanged: (_, _) {
                        _scheduleVehicleRefresh();
                      },
                      interactionOptions: InteractionOptions(
                        flags:
                            (widget.showRotationControls &&
                                _isRotationGestureEnabled)
                            ? InteractiveFlag.all
                            : InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    )
                  : MapOptions(
                      initialCenter: initialCenter,
                      initialZoom: 12,
                      minZoom: _minZoom,
                      maxZoom: _maxZoom,
                      onTap: (_, _) {
                        if (_suppressNextMapTapClose) {
                          _suppressNextMapTapClose = false;
                          return;
                        }
                        if (_selectedVehicleMarkerId != null ||
                            _selectedStopMarkerId != null) {
                          setState(() {
                            _selectedVehicleMarkerId = null;
                            _selectedStopMarkerId = null;
                            _selectedStopQuickInfo = null;
                            _isLoadingSelectedStopQuickInfo = false;
                          });
                        }
                      },
                      onPositionChanged: (_, _) {
                        _scheduleVehicleRefresh();
                      },
                      interactionOptions: InteractionOptions(
                        flags:
                            (widget.showRotationControls &&
                                _isRotationGestureEnabled)
                            ? InteractiveFlag.all
                            : InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
              children: [
                TileLayer(
                  urlTemplate: Theme.of(context).brightness == Brightness.dark
                      ? 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png'
                      : 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png',
                  userAgentPackageName: 'hu.terka.terka_mobile_ui',
                  maxZoom: 19,
                ),
                if (routeData != null && routeData.segments.isNotEmpty)
                  PolylineLayer(
                    polylines: routeData.segments
                        .where((segment) => segment.points.length >= 2)
                        .map(
                          (segment) => Polyline(
                            points: segment.points,
                            color: segment.isWalk
                                ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                                : segment.color,
                            strokeWidth: 5,
                            pattern: segment.isWalk
                                ? StrokePattern.dotted()
                                : const StrokePattern.solid(),
                          ),
                        )
                        .toList(),
                  ),
                ..._buildVehicleAndStopLayers(),
                if (routeData != null && routeData.stops.isNotEmpty)
                  MarkerLayer(
                    markers: routeData.stops
                        .map(
                          (stop) => Marker(
                            point: stop.point,
                            width: 38,
                            height: 38,
                            alignment: widget.useBaseMapStopIcon
                                ? Alignment.center
                                : Alignment.topCenter,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.bottomCenter,
                              children: [
                                if (widget.showRouteStopLabels)
                                  Positioned(
                                    bottom: 30,
                                    child: Builder(
                                      builder: (context) {
                                        final isDark =
                                            Theme.of(context).brightness ==
                                            Brightness.dark;
                                        final bgColor = isDark
                                            ? Colors.grey[900]!.withOpacity(
                                                0.92,
                                              )
                                            : Colors.white.withOpacity(
                                                0.92,
                                              );
                                        return Container(
                                          constraints: const BoxConstraints(
                                            maxWidth: 180,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: bgColor,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            stop.label,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                widget.useBaseMapStopIcon
                                    ? _buildMapStopDot(stop.bearing)
                                    : Icon(
                                        Icons.location_on,
                                        color: _routeStopColor(stop.type),
                                        size: 30,
                                      ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                if (widget.routeVehicleMarker != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: widget.routeVehicleMarker!.point,
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        child: _buildRouteVehicleDot(
                          widget.routeVehicleMarker!,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (_isLoadingVehicles)
              Positioned(
                top: 12,
                right: 12,
                child: DecoratedBox(
                    decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
            if (widget.showMyLocationButton)
              Positioned(
                left: 12,
                bottom: 12 + widget.controlsBottomInset,
                child: FloatingActionButton.small(
                  heroTag: 'map_my_location',
                  onPressed: _jumpToCurrentLocation,
                  child: _isLocating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                ),
              ),
            Positioned(
              right: 12,
              bottom: 12 + widget.controlsBottomInset,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showRotationControls) ...[
                    FloatingActionButton.small(
                      heroTag: 'map_rotate_toggle',
                      onPressed: _toggleRotationGesture,
                      backgroundColor: _isRotationGestureEnabled
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      foregroundColor: _isRotationGestureEnabled
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                      child: Icon(
                        _isRotationGestureEnabled
                            ? Icons.screen_lock_rotation
                            : Icons.screen_rotation,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isRotated) ...[
                      FloatingActionButton.small(
                        heroTag: 'map_compass',
                        onPressed: _resetNorth,
                        child: const Icon(Icons.explore),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                  FloatingActionButton.small(
                    heroTag: 'map_zoom_in',
                    onPressed: () => _zoomBy(1),
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'map_zoom_out',
                    onPressed: () => _zoomBy(-1),
                    child: const Icon(Icons.remove),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openTripDetails(_VehicleMarkerData vehicle) async {
    final tripId = vehicle.tripGtfsId.trim();
    if (tripId.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTexts.mapNoTripId)),
      );
      return;
    }

    final serviceDay = vehicle.serviceDate.trim().isNotEmpty
        ? vehicle.serviceDate.trim()
        : _todayServiceDate();

    if (!mounted) {
      return;
    }

    if (_useDesktopDialogs) {
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920, maxHeight: 860),
            child: TripDetailsScreen(
              tripId: tripId,
              serviceDay: serviceDay,
              onShowOnBackgroundMap: widget.onShowTripOnBackgroundMap,
            ),
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripDetailsScreen(
          tripId: tripId,
          serviceDay: serviceDay,
          onShowOnBackgroundMap: widget.onShowTripOnBackgroundMap,
        ),
      ),
    );
  }

  void refreshState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }
}
