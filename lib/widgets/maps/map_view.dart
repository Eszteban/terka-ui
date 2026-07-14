import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/app_texts.dart';
import 'map_controls.dart';

import '../../services/graphql/graphql_client.dart';
import '../../services/graphql/graphql_queries.dart';
import '../../utils/markup_text_utils.dart';
import '../../screens/stop_details/stop_details_screen.dart';
import '../../screens/trip_details/trip_details_screen.dart';
import '../../utils/adaptive_dialog_utils.dart';
import 'map_initialization_utils.dart';
import 'route_map_data.dart';
import 'vehicle_info_card.dart';
import 'user_location_dot.dart';
import '../../controllers/map_cubit.dart';

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
  final Function(String, String)? onOpenTripDetailsRequested;
  final Function(String, String?, LatLng?, List<String>?)?
  onOpenStopDetailsRequested;
  final bool hideGeneralStopsAndVehicles;
  final LatLng? searchHighlightPoint;
  final void Function(String stopName, LatLng stopPoint, String stopId)? onPlanRouteToStop;
  final String? selectedRouteName;

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
    this.onOpenTripDetailsRequested,
    this.onOpenStopDetailsRequested,
    this.hideGeneralStopsAndVehicles = false,
    this.searchHighlightPoint,
    this.onPlanRouteToStop,
    this.selectedRouteName,
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
  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;

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
        _startPositionTracking();
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
      _selectedVehicleMarkerId = null;
      _selectedStopMarkerId = null;
      _selectedStopQuickInfo = null;
      _isLoadingSelectedStopQuickInfo = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_hasRouteOverlayContent) {
          return;
        }
        _fitToOverlayRoute();
      });
    }
    if (widget.searchHighlightPoint != oldWidget.searchHighlightPoint &&
        widget.searchHighlightPoint != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(widget.searchHighlightPoint!, 15);
        }
      });
    }
  }

  bool get _hasRouteOverlayContent {
    final mapState = context.read<MapCubit>().state;
    final routeData =
        widget.routeOverlayData ??
        (mapState.routeOverlayData.hasContent
            ? mapState.routeOverlayData
            : null);
    final routeVehicleMarker =
        widget.routeVehicleMarker ?? mapState.routeVehicleMarker;
    return (routeData?.hasContent ?? false) || routeVehicleMarker != null;
  }

  bool get _useDesktopDialogs {
    return MediaQuery.of(context).size.width >
        StopDetailsScreen.desktopBreakpoint;
  }

  List<LatLng> _overlayRoutePoints() {
    final points = <LatLng>[];
    final mapState = context.read<MapCubit>().state;
    final routeData =
        widget.routeOverlayData ??
        (mapState.routeOverlayData.hasContent
            ? mapState.routeOverlayData
            : null);
    final routeVehicleMarker =
        widget.routeVehicleMarker ?? mapState.routeVehicleMarker;

    if (routeData != null) {
      for (final segment in routeData.segments) {
        points.addAll(segment.points);
      }
      for (final stop in routeData.stops) {
        points.add(stop.point);
      }
    }
    if (routeVehicleMarker != null) {
      points.add(routeVehicleMarker.point);
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
    final mapState = context.read<MapCubit>().state;
    final routeData =
        widget.routeOverlayData ??
        (mapState.routeOverlayData.hasContent
            ? mapState.routeOverlayData
            : null);
    final routeVehicleMarker =
        widget.routeVehicleMarker ?? mapState.routeVehicleMarker;

    if (routeData != null) {
      if (routeData.segments.isNotEmpty &&
          routeData.segments.first.points.isNotEmpty) {
        return routeData.segments.first.points.first;
      }
      if (routeData.stops.isNotEmpty) {
        return routeData.stops.first.point;
      }
    }
    return routeVehicleMarker?.point;
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

  void _showMapAttributionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppTexts.isHungarian ? 'Térkép információk' : 'Map Information',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTexts.isHungarian
                    ? '• Térkép csempék: © CARTO\n• Térképadatok: © OpenStreetMap közreműködők'
                    : '• Map tiles: © CARTO\n• Map data: © OpenStreetMap contributors',
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 12),
              Text(
                AppTexts.isHungarian
                    ? 'A térképi adatok az OpenStreetMap nyílt adatbázisából származnak (ODbL).'
                    : 'Map data is sourced from the OpenStreetMap open database (ODbL).',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppTexts.isHungarian ? 'Bezárás' : 'Close'),
            ),
          ],
        );
      },
    );
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
      camera.zoom < 16 ? 16 : camera.zoom,
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
    if (widget.selectedRouteName != null) {
      return <String>[..._railModes, ..._coachModes, ..._localModes];
    }
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
    if (widget.selectedRouteName != null) {
      return 1300;
    }
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
    _positionSubscription?.cancel();
    _vehicleRefreshDebounce?.cancel();
    _vehiclePeriodicRefresh?.cancel();
    _mapEventSubscription.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MapCubit, MapState>(
      listenWhen: (previous, current) {
        return previous.routeOverlayData != current.routeOverlayData ||
            previous.routeVehicleMarker != current.routeVehicleMarker;
      },
      listener: (context, state) {
        _selectedVehicleMarkerId = null;
        _selectedStopMarkerId = null;
        _selectedStopQuickInfo = null;
        _isLoadingSelectedStopQuickInfo = false;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_hasRouteOverlayContent) {
            return;
          }
          _fitToOverlayRoute();
        });
      },
      child: BlocBuilder<MapCubit, MapState>(
        builder: (context, mapState) {
          return FutureBuilder<bool>(
            future: _mapReady,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data != true) {
                return Center(child: Text(AppTexts.mapLoadFailed));
              }

              final routeData =
                  widget.routeOverlayData ??
                  (mapState.routeOverlayData.hasContent
                      ? mapState.routeOverlayData
                      : null);
              final routeVehicleMarker =
                  widget.routeVehicleMarker ?? mapState.routeVehicleMarker;
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
                                  : InteractiveFlag.all &
                                        ~InteractiveFlag.rotate,
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
                                  : InteractiveFlag.all &
                                        ~InteractiveFlag.rotate,
                            ),
                          ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            Theme.of(context).brightness == Brightness.dark
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
                                      ? (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black)
                                      : segment.color,
                                  strokeWidth: 5,
                                  pattern: segment.isWalk
                                      ? StrokePattern.dotted()
                                      : const StrokePattern.solid(),
                                ),
                              )
                              .toList(),
                        ),
                      if (MapControls.showUserLocation && _currentPosition != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              child: const UserLocationDot(),
                            ),
                          ],
                        ),
                      ..._buildMapStopLayers(),
                      if (routeData != null && routeData.stops.isNotEmpty)
                        MarkerLayer(
                          markers: routeData.stops.map((stop) {
                            final isSelected =
                                _selectedStopMarkerId == stop.stopId;
                            return Marker(
                              point: stop.point,
                              width: isSelected ? 320 : 38,
                              height: isSelected ? 180 : 38,
                              alignment: Alignment.center,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _toggleRouteStopLabel(stop),
                                child: isSelected
                                    ? Stack(
                                        clipBehavior: Clip.none,
                                        alignment: Alignment.center,
                                        children: [
                                          Positioned(
                                            bottom: 92,
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: _consumeNextMapTapClose,
                                              child: _buildRouteStopInfoCard(
                                                stop,
                                              ),
                                            ),
                                          ),
                                          _buildMapStopDot(stop.bearing),
                                        ],
                                      )
                                    : Stack(
                                        clipBehavior: Clip.none,
                                        alignment: Alignment.bottomCenter,
                                        children: [
                                          if (widget.showRouteStopLabels)
                                            Positioned(
                                              bottom: 30,
                                              child: Builder(
                                                builder: (context) {
                                                  final isDark =
                                                      Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.dark;
                                                  final bgColor = isDark
                                                      ? Colors.grey[900]!
                                                            .withValues(
                                                              alpha: 0.92,
                                                            )
                                                      : Colors.white.withValues(
                                                          alpha: 0.92,
                                                        );
                                                  return Container(
                                                    constraints:
                                                        const BoxConstraints(
                                                          maxWidth: 180,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: bgColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      stop.label,
                                                      overflow:
                                                          TextOverflow.ellipsis,
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
                                                  color: _routeStopColor(
                                                    stop.type,
                                                  ),
                                                  size: 30,
                                                ),
                                        ],
                                      ),
                              ),
                            );
                          }).toList(),
                        ),
                      ..._buildMapVehicleLayers(),
                      if (routeVehicleMarker != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: routeVehicleMarker.point,
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              child: _buildRouteVehicleDot(routeVehicleMarker),
                            ),
                          ],
                        ),
                      if (widget.searchHighlightPoint != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: widget.searchHighlightPoint!,
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
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
                          ).colorScheme.surface.withValues(alpha: 0.85),
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
                  MapControls(
                    controlsBottomInset: widget.controlsBottomInset,
                    showRotationControls: widget.showRotationControls,
                    isRotationGestureEnabled: _isRotationGestureEnabled,
                    isRotated: _isRotated,
                    showMyLocationButton: widget.showMyLocationButton,
                    isLocating: _isLocating,
                    onResetNorth: _resetNorth,
                    onToggleRotation: _toggleRotationGesture,
                    onToggleLocationDot: () {
                      setState(() {
                        MapControls.showUserLocation = !MapControls.showUserLocation;
                      });
                    },
                    onJumpToCurrentLocation: _jumpToCurrentLocation,
                    onZoomIn: () => _zoomBy(1),
                    onZoomOut: () => _zoomBy(-1),
                    onShowAttribution: () => _showMapAttributionDialog(context),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openTripDetails(_VehicleMarkerData vehicle) async {
    debugPrint(
      '[Map Debug] Opening vehicle details: vehicleId=${vehicle.markerId}, tripId=${vehicle.tripGtfsId}',
    );
    final tripId = vehicle.tripGtfsId.trim();
    if (tripId.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppTexts.mapNoTripId)));
      return;
    }

    final serviceDay = vehicle.serviceDate.trim().isNotEmpty
        ? vehicle.serviceDate.trim()
        : _todayServiceDate();

    if (widget.onOpenTripDetailsRequested != null) {
      widget.onOpenTripDetailsRequested!(tripId, serviceDay);
      return;
    }

    if (!mounted) {
      return;
    }

    if (_useDesktopDialogs) {
      await showAdaptiveDetailsDialog<void>(
        context: context,
        child: TripDetailsScreen(
          tripId: tripId,
          serviceDay: serviceDay,
          onShowOnBackgroundMap: widget.onShowTripOnBackgroundMap,
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
