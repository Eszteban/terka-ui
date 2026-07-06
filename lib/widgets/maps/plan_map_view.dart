import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

import '../../theme/app_texts.dart';
import 'map_initialization_utils.dart';
import 'route_map_data.dart';
import 'user_location_dot.dart';

class PlanMapView extends StatefulWidget {
  final RouteMapData routeData;
  final EdgeInsets fitPadding;
  final double controlsBottomInset;
  final double initialZoom;
  final double singlePointZoom;
  final bool showRotationControls;
  final bool showMyLocationButton;
  final bool showStopLabels;
  final bool useBaseMapStopIcon;
  final RouteVehicleMarker? vehicleMarker;
  final bool enableVehicleInfoLabelTap;
  final WidgetBuilder? vehicleInfoCardBuilder;
  final bool enableStopInfoLabelTap;
  final Widget Function(BuildContext context, RouteStopMarker stop)?
  stopInfoCardBuilder;

  const PlanMapView({
    super.key,
    required this.routeData,
    this.fitPadding = const EdgeInsets.all(48),
    this.controlsBottomInset = 0,
    this.initialZoom = 12,
    this.singlePointZoom = 15,
    this.showRotationControls = true,
    this.showMyLocationButton = true,
    this.showStopLabels = true,
    this.useBaseMapStopIcon = false,
    this.vehicleMarker,
    this.enableVehicleInfoLabelTap = false,
    this.vehicleInfoCardBuilder,
    this.enableStopInfoLabelTap = false,
    this.stopInfoCardBuilder,
  });

  @override
  State<PlanMapView> createState() => _PlanMapViewState();
}

class _PlanMapViewState extends State<PlanMapView> {
  static const double _minZoom = 3;
  static const double _maxZoom = 19;

  late final Future<bool> _mapReady = canLoadMapTiles();
  final MapController _mapController = MapController();
  late final StreamSubscription<MapEvent> _mapEventSubscription;
  bool _isRotated = false;
  bool _isRotationGestureEnabled = false;
  bool _isVehicleLabelVisible = false;
  bool _isStopLabelVisible = false;
  String? _selectedStopSelectionKey;
  bool _suppressNextMapTapClose = false;
  bool _isLocating = false;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startPositionTracking();
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapEventSubscription.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _startPositionTracking() async {
    if (_positionSubscription != null) return;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && _currentPosition == null && mounted) {
        setState(() {
          _currentPosition = lastKnown;
        });
      }

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
        ),
      ).listen(
        (Position position) {
          if (mounted) {
            setState(() {
              _currentPosition = position;
            });
          }
        },
        onError: (error) {
          debugPrint('[PlanMap Debug] Position stream error: $error');
        },
      );
    } catch (e) {
      debugPrint('[PlanMap Debug] Error starting position tracking: $e');
    }
  }

  @override
  void didUpdateWidget(covariant PlanMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehicleMarker != widget.vehicleMarker &&
        _isVehicleLabelVisible) {
      _isVehicleLabelVisible = false;
    }
    if (oldWidget.routeData != widget.routeData && _isStopLabelVisible) {
      _isStopLabelVisible = false;
      _selectedStopSelectionKey = null;
    }
    if (oldWidget.routeData != widget.routeData ||
        oldWidget.vehicleMarker != widget.vehicleMarker ||
        oldWidget.fitPadding != widget.fitPadding) {
      _scheduleFitToRoute();
    }
  }

  void _toggleVehicleLabel() {
    if (!widget.enableVehicleInfoLabelTap || widget.vehicleMarker == null) {
      return;
    }
    _suppressNextMapTapClose = true;
    setState(() {
      _isVehicleLabelVisible = !_isVehicleLabelVisible;
    });
  }

  String _stopSelectionKey(RouteStopMarker stop) {
    final stopId = stop.stopId?.trim();
    if (stopId != null && stopId.isNotEmpty) {
      return stopId;
    }
    return '${stop.label}:${stop.point.latitude.toStringAsFixed(6)}:${stop.point.longitude.toStringAsFixed(6)}';
  }

  void _toggleStopLabel(RouteStopMarker stop) {
    if (!widget.enableStopInfoLabelTap || widget.stopInfoCardBuilder == null) {
      return;
    }
    final selectionKey = _stopSelectionKey(stop);
    _suppressNextMapTapClose = true;
    setState(() {
      _isVehicleLabelVisible = false;
      if (_selectedStopSelectionKey == selectionKey && _isStopLabelVisible) {
        _isStopLabelVisible = false;
        _selectedStopSelectionKey = null;
      } else {
        _selectedStopSelectionKey = selectionKey;
        _isStopLabelVisible = true;
      }
    });
  }

  void _consumeNextMapTapClose() {
    _suppressNextMapTapClose = true;
  }

  void _onMapTap() {
    if (_suppressNextMapTapClose) {
      _suppressNextMapTapClose = false;
      return;
    }
    if (_isVehicleLabelVisible) {
      setState(() {
        _isVehicleLabelVisible = false;
      });
    }
    if (_isStopLabelVisible) {
      setState(() {
        _isStopLabelVisible = false;
        _selectedStopSelectionKey = null;
      });
    }
  }

  void _scheduleFitToRoute() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _fitToRoute(widget.routeData);
    });
  }

  List<LatLng> _collectPointsForBounds(RouteMapData routeData) {
    final points = <LatLng>[];
    for (final segment in routeData.segments) {
      points.addAll(segment.points);
    }
    for (final stop in routeData.stops) {
      points.add(stop.point);
    }
    if (widget.vehicleMarker != null) {
      points.add(widget.vehicleMarker!.point);
    }
    return points;
  }

  CameraFit? _initialCameraFit(RouteMapData routeData) {
    final points = _collectPointsForBounds(routeData);

    if (points.length < 2) {
      return null;
    }

    return CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(points),
      padding: widget.fitPadding,
    );
  }

  void _fitToRoute(RouteMapData routeData) {
    if (!routeData.hasContent && widget.vehicleMarker == null) {
      return;
    }

    final points = _collectPointsForBounds(routeData);

    if (points.isEmpty) {
      return;
    }

    if (points.length == 1) {
      final camera = _mapController.camera;
      final targetZoom = camera.zoom < widget.singlePointZoom
          ? widget.singlePointZoom
          : camera.zoom;
      _mapController.move(points.first, targetZoom);
      return;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: widget.fitPadding,
      ),
    );
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final newZoom = (camera.zoom + delta).clamp(_minZoom, _maxZoom);
    _mapController.move(camera.center, newZoom);
  }

  void _moveToPosition(Position position) {
    final camera = _mapController.camera;
    final targetZoom = camera.zoom < widget.singlePointZoom
        ? widget.singlePointZoom
        : camera.zoom;
    _mapController.move(
      LatLng(position.latitude, position.longitude),
      targetZoom,
    );
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

  Future<void> _jumpToCurrentLocation() async {
    if (_isLocating) return;

    setState(() => _isLocating = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppTexts.mapLocationDisabled),
            ),
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppTexts.mapPermissionRequired),
            ),
          );
        }
        return;
      }

      _startPositionTracking();

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _moveToPosition(lastKnown);
      }

      const quickSettings = LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 5),
      );
      final quickPosition = await Geolocator.getCurrentPosition(
        locationSettings: quickSettings,
      );
      _moveToPosition(quickPosition);
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTexts.mapTimeout),
          ),
        );
      }
    } on MissingPluginException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppTexts.mapPluginNotLoaded,
            ),
          ),
        );
      }
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppTexts.mapLocationFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Color _markerColor(RouteStopType type) {
    switch (type) {
      case RouteStopType.start:
        return Colors.green;
      case RouteStopType.transfer:
        return Colors.orange;
      case RouteStopType.end:
        return Colors.red;
    }
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

        final fallbackCenter =
            widget.routeData.segments.isNotEmpty &&
                widget.routeData.segments.first.points.isNotEmpty
            ? widget.routeData.segments.first.points.first
            : (widget.routeData.stops.isNotEmpty
                  ? widget.routeData.stops.first.point
                  : (widget.vehicleMarker?.point ??
                        const LatLng(47.497913, 19.040236)));
        final initialFit = _initialCameraFit(widget.routeData);

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: initialFit != null
                  ? MapOptions(
                      initialCameraFit: initialFit,
                      minZoom: _minZoom,
                      maxZoom: _maxZoom,
                      onTap: (_, _) => _onMapTap(),
                      interactionOptions: InteractionOptions(
                        flags:
                            (widget.showRotationControls &&
                                _isRotationGestureEnabled)
                            ? InteractiveFlag.all
                            : InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    )
                  : MapOptions(
                      initialCenter: fallbackCenter,
                      initialZoom: widget.initialZoom,
                      minZoom: _minZoom,
                      maxZoom: _maxZoom,
                      onTap: (_, _) => _onMapTap(),
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
                if (widget.routeData.segments.isNotEmpty)
                  PolylineLayer(
                    polylines: widget.routeData.segments
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
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        child: const UserLocationDot(),
                      ),
                    ],
                  ),
                if (widget.routeData.stops.isNotEmpty)
                  MarkerLayer(
                    markers: () {
                      final stops = widget.routeData.stops.toList();
                      if (_isStopLabelVisible &&
                          _selectedStopSelectionKey != null) {
                        final selectedIndex = stops.indexWhere(
                          (s) =>
                              _stopSelectionKey(s) == _selectedStopSelectionKey,
                        );
                        if (selectedIndex != -1) {
                          final selected = stops.removeAt(selectedIndex);
                          stops.add(selected);
                        }
                      }
                      return stops.map((stop) {
                        final isPopupVisible =
                            widget.enableStopInfoLabelTap &&
                            _isStopLabelVisible &&
                            _selectedStopSelectionKey ==
                                _stopSelectionKey(stop);
                        return Marker(
                          point: stop.point,
                          width: isPopupVisible ? 320 : 38,
                          height: isPopupVisible ? 220 : 38,
                          alignment: Alignment.center,
                          child:
                              widget.enableStopInfoLabelTap &&
                                  widget.stopInfoCardBuilder != null
                              ? Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    if (isPopupVisible)
                                      Positioned(
                                        bottom: 122,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: _consumeNextMapTapClose,
                                          child: widget.stopInfoCardBuilder!(
                                            context,
                                            stop,
                                          ),
                                        ),
                                      ),
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => _toggleStopLabel(stop),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        alignment: widget.useBaseMapStopIcon
                                            ? Alignment.center
                                            : Alignment.bottomCenter,
                                        children: [
                                          if (widget.showStopLabels)
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
                                                            .withOpacity(0.92)
                                                      : Colors.white
                                                            .withOpacity(0.92);
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
                                          _buildStopMarkerChild(stop),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Stack(
                                  clipBehavior: Clip.none,
                                  alignment: widget.useBaseMapStopIcon
                                      ? Alignment.center
                                      : Alignment.bottomCenter,
                                  children: [
                                    if (widget.showStopLabels)
                                      Positioned(
                                        bottom: 30,
                                        child: Builder(
                                          builder: (context) {
                                            final isDark =
                                                Theme.of(context).brightness ==
                                                Brightness.dark;
                                            final bgColor = isDark
                                                ? Colors.grey[900]!.withValues(
                                                    alpha: 0.92,
                                                  )
                                                : Colors.white.withValues(
                                                    alpha: 0.92,
                                                  );
                                            return Container(
                                              constraints: const BoxConstraints(
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
                                                    BorderRadius.circular(6),
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
                                    _buildStopMarkerChild(stop),
                                  ],
                                ),
                        );
                      }).toList();
                    }(),
                  ),
                if (widget.vehicleMarker != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: widget.vehicleMarker!.point,
                        width: _isVehicleLabelVisible ? 320 : 24,
                        height: _isVehicleLabelVisible ? 360 : 24,
                        alignment: Alignment.center,
                        child:
                            (widget.enableVehicleInfoLabelTap &&
                                widget.vehicleInfoCardBuilder != null)
                            ? Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  if (_isVehicleLabelVisible)
                                    Positioned(
                                      bottom: 192,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: _consumeNextMapTapClose,
                                        child: widget.vehicleInfoCardBuilder!(
                                          context,
                                        ),
                                      ),
                                    ),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _toggleVehicleLabel,
                                    child: _buildVehicleDot(
                                      widget.vehicleMarker!,
                                    ),
                                  ),
                                ],
                              )
                            : _buildVehicleDot(widget.vehicleMarker!),
                      ),
                    ],
                  ),
              ],
            ),
            Positioned(
              right: 12,
              bottom: 12 + widget.controlsBottomInset,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showMyLocationButton) ...[
                    FloatingActionButton.small(
                      heroTag: 'plan_map_my_location',
                      tooltip: AppTexts.mapTooltipMyLocation,
                      onPressed: _jumpToCurrentLocation,
                      child: _isLocating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (widget.showRotationControls) ...[
                    FloatingActionButton.small(
                      heroTag: 'plan_map_rotate_toggle',
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
                        heroTag: 'plan_map_compass',
                        onPressed: _resetNorth,
                        child: const Icon(Icons.explore),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                  FloatingActionButton.small(
                    heroTag: 'plan_map_zoom_in',
                    onPressed: () => _zoomBy(1),
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'plan_map_zoom_out',
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

  Widget _buildBaseMapStopDot(double? bearing) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final circleColor = isDark ? Colors.black : Colors.white;
    final contentColor = isDark ? Colors.white : Colors.black;

    return SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleColor,
              border: Border.all(color: contentColor, width: 2),
            ),
            child: Icon(Icons.apartment, size: 12, color: contentColor),
          ),
          if (bearing != null)
            Positioned.fill(
              child: Transform.rotate(
                angle: bearing * (3.141592653589793 / 180),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Transform.translate(
                    offset: const Offset(0, -3),
                    child: Icon(
                      Icons.arrow_drop_up,
                      size: 22,
                      color: contentColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPinStopDot(RouteStopMarker stop) {
    final baseIcon = Icon(
      Icons.location_on,
      color: _markerColor(stop.type),
      size: 30,
    );

    if (stop.bearing == null) {
      return baseIcon;
    }

    final angle = stop.bearing! * (3.141592653589793 / 180);
    return SizedBox(
      width: 30,
      height: 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          baseIcon,
          Positioned(
            top: 4,
            child: Transform.rotate(
              angle: angle,
              child: const Icon(
                Icons.arrow_upward,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopMarkerChild(RouteStopMarker stop) {
    if (widget.useBaseMapStopIcon) {
      return _buildBaseMapStopDot(stop.bearing);
    } else {
      return _buildPinStopDot(stop);
    }
  }

  Widget _buildVehicleDot(RouteVehicleMarker vehicle) {
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
}
