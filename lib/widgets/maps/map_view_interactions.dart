part of 'map_view.dart';

extension _MapViewInteractions on _MapViewState {
  void _handleMapInteraction(TapPosition tapPosition, LatLng point) async {
    context.read<MapCubit>().setSearchHighlight(point, null);

    if (widget.onPlanRouteFromMap == null) return;
    
    final defaultName = AppTexts.isHungarian ? 'Kijelölt hely' : 'Selected location';
    String finalName = defaultName;
    try {
      final baseUri = Uri.parse(photonReverseApiUrl);
      final uri = baseUri.replace(queryParameters: {
        ...baseUri.queryParameters,
        'lat': point.latitude.toString(),
        'lon': point.longitude.toString(),
        'lang': AppTexts.isHungarian ? 'hu' : 'en',
      });
      final response = await http.get(uri).timeout(const Duration(milliseconds: 1200));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map && body['features'] is List && (body['features'] as List).isNotEmpty) {
           final firstFeature = body['features'][0];
           if (firstFeature is Map && firstFeature['properties'] is Map) {
              final formatted = _formatReversePhotonName(firstFeature['properties'].cast<String, dynamic>());
              if (formatted.isNotEmpty) {
                 finalName = formatted;
                 if (mounted) {
                   context.read<MapCubit>().setSearchHighlight(point, null);
                 }
              }
           }
        }
      }
    } catch (_) {}

    if (!mounted) return;
    
    if (LayoutProvider.isDesktop(context)) {
      await _showDesktopContextMenu(tapPosition.global, point, finalName);
    } else {
      await _showMobileBottomSheet(point, finalName);
    }
    
    if (mounted) {
      context.read<MapCubit>().clearSearchHighlight();
    }
  }

  Future<void> _showDesktopContextMenu(Offset globalPosition, LatLng point, String name) async {
    final colorScheme = Theme.of(context).colorScheme;
    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx,
        globalPosition.dy,
      ),
      items: <PopupMenuEntry<dynamic>>[
        PopupMenuItem(
          enabled: false,
          child: Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: () {
            widget.onPlanRouteFromMap?.call(name, point, false);
          },
          child: Row(
            children: [
              Icon(Icons.trip_origin, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(AppTexts.isHungarian ? 'Tervezés innen' : 'Plan from here'),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () {
            widget.onPlanRouteFromMap?.call(name, point, true);
          },
          child: Row(
            children: [
              Icon(Icons.place, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(AppTexts.isHungarian ? 'Tervezés ide' : 'Plan here'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showMobileBottomSheet(LatLng point, String name) async {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: isDark ? Border.all(color: AppColors.white.withValues(alpha: 0.08)) : null,
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.place, color: colorScheme.primary, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onPlanRouteFromMap?.call(name, point, false);
                        },
                        icon: const Icon(Icons.trip_origin),
                        label: Text(AppTexts.isHungarian ? 'Tervezés innen' : 'Plan from here'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onPlanRouteFromMap?.call(name, point, true);
                        },
                        icon: const Icon(Icons.directions),
                        label: Text(AppTexts.isHungarian ? 'Tervezés ide' : 'Plan here'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _refreshVehiclesForVisibleBounds() async {
    if (!mounted) {
      return;
    }

    if (widget.hideGeneralStopsAndVehicles) {
      if (_vehicleMarkers.isNotEmpty || _nearbyStops.isNotEmpty) {
        refreshState(() {
          _vehicleMarkers = const [];
          _nearbyStops = const [];
        });
      }
      return;
    }

    final camera = _mapController.camera;
    final bounds = camera.visibleBounds;
    final modes = _modesForZoom(camera.zoom);
    final shouldLoadStops = camera.zoom >= _MapViewState._stopMinZoom;
    final maxStops = _maxStopsForZoom(camera.zoom);
    if (modes.isEmpty) {
      if (mounted) {
        refreshState(() {
          _vehicleMarkers = const [];
          _nearbyStops = const [];
        });
      }
      return;
    }

    final requestId = ++_vehicleRequestNonce;
    if (mounted) {
      refreshState(() {
        _isLoadingVehicles = true;
      });
    }

    try {
      final modesLiteral = modes.join(',');
      final response = await _graphqlClient.execute(
        query: buildVehiclePositionsQuery(modesLiteral),
        variables: {
          'swLat': bounds.south,
          'swLon': bounds.west,
          'neLat': bounds.north,
          'neLon': bounds.east,
        },
        timeout: const Duration(seconds: 10),
      );

      if (requestId != _vehicleRequestNonce) {
        return;
      }

      if (!response.isSuccess) {
        if (mounted) {
          refreshState(() {
            _vehicleMarkers = const [];
          });
        }
        return;
      }

      final decoded = response.json;
      if (decoded == null) {
        return;
      }

      final dynamic list = decoded['data']?['vehiclePositions'];
      if (list is! List) {
        if (mounted) {
          refreshState(() {
            _vehicleMarkers = const [];
          });
        }
        return;
      }

      final markers = <_VehicleMarkerData>[];
      final maxVehicles = _maxVehiclesForZoom(camera.zoom);
      for (final item in list) {
        if (markers.length >= maxVehicles) {
          break;
        }
        if (item is! Map<String, dynamic>) {
          continue;
        }

        final latValue = item['lat'];
        final lonValue = item['lon'];
        if (latValue is! num || lonValue is! num) {
          continue;
        }

        final trip = item['trip'];
        final route = trip is Map ? trip['route'] : null;
        final mode = route is Map && route['mode'] is String
            ? route['mode'] as String
            : 'UNKNOWN';

        final rawServiceLabel = item['label'] is String
            ? item['label'] as String
            : (item['uicCode']?.toString() ?? AppTexts.unknown);
        final serviceLabel = _plainTextFromHtml(
          item['label'] is String
              ? item['label'] as String
              : (item['uicCode']?.toString() ?? AppTexts.unknown),
        );
        final uicLabel = _plainTextFromHtml(
          item['uicCode'] is String
              ? item['uicCode'] as String
              : (item['vehicleId']?.toString() ?? AppTexts.unknown),
        );

        final serviceLabelUsesSpanFont = _containsSpanMarkup(rawServiceLabel);
        final headingDegrees = item['heading'] is num
            ? (item['heading'] as num).toDouble()
            : 0.0;

        final rawRouteShortName =
            trip is Map && trip['routeShortName'] is String
            ? trip['routeShortName'] as String
            : '';
        final routeShortName = _plainTextFromHtml(rawRouteShortName);
        final routeShortNameUsesSpanFont = _containsSpanMarkup(
          rawRouteShortName,
        );

        final tripGtfsId = trip is Map && trip['gtfsId'] is String
            ? (trip['gtfsId'] as String)
            : '';
        final serviceDate = trip is Map && trip['serviceDate'] is String
            ? (trip['serviceDate'] as String)
            : _todayServiceDate();

        final color = route is Map && route['color'] is String
            ? route['color'] as String
            : '0A84FF';
        final textColor = route is Map && route['textColor'] is String
            ? route['textColor'] as String
            : 'FFFFFF';
        final markerTextColor = _parseTextColor(textColor);
        final markerColor = _parseRouteColor(color, mode: mode);
        final markerOutlineHeadingColor = markerTextColor;
        final markerId = item['vehicleId']?.toString().trim().isNotEmpty == true
            ? item['vehicleId'].toString()
            : '${latValue.toStringAsFixed(5)}:${lonValue.toStringAsFixed(5)}:${serviceLabel.trim()}';

        markers.add(
          _VehicleMarkerData(
            markerId: markerId,
            tripGtfsId: tripGtfsId,
            serviceDate: serviceDate,
            point: LatLng(latValue.toDouble(), lonValue.toDouble()),
            headingDegrees: headingDegrees,
            serviceLabel: serviceLabel.isNotEmpty ? serviceLabel : uicLabel,
            serviceLabelUsesSpanFont: serviceLabelUsesSpanFont,
            routeShortName: routeShortName,
            routeShortNameUsesSpanFont: routeShortNameUsesSpanFont,
            mode: mode,
            markerColor: markerColor,
            markerTextColor: markerTextColor,
            markerOutlineHeadingColor: markerOutlineHeadingColor,
            rawVehicle: item,
          ),
        );
      }

      var stops = <_MapStopData>[];
      if (shouldLoadStops) {
        try {
          final stopResponse = await _graphqlClient.execute(
            query: stopsByBboxQuery,
            variables: {
              'minLat': bounds.south,
              'minLon': bounds.west,
              'maxLat': bounds.north,
              'maxLon': bounds.east,
            },
            timeout: const Duration(seconds: 10),
          );

          if (stopResponse.isSuccess) {
            final stopDecoded = stopResponse.json;
            if (stopDecoded != null) {
              final dynamic stopList = stopDecoded['data']?['stopsByBbox'];
              if (stopList is List) {
                final parsedStops = <_MapStopData>[];
                for (final item in stopList) {
                  if (parsedStops.length >= maxStops) {
                    break;
                  }
                  if (item is! Map) {
                    continue;
                  }
                  final lat = item['lat'];
                  final lon = item['lon'];
                  if (lat is! num || lon is! num) {
                    continue;
                  }
                  final bearing = item['bearing'] is num
                      ? (item['bearing'] as num).toDouble()
                      : null;
                  final stopId =
                      item['gtfsId']?.toString().trim().isNotEmpty == true
                      ? item['gtfsId'].toString().trim()
                      : '${lat.toStringAsFixed(6)}:${lon.toStringAsFixed(6)}';
                  final stopName = _plainTextFromHtml(
                    item['name']?.toString() ?? AppTexts.tripStopColumn,
                  );
                  parsedStops.add(
                    _MapStopData(
                      stopId: stopId,
                      name: stopName,
                      point: LatLng(lat.toDouble(), lon.toDouble()),
                      bearing: bearing,
                    ),
                  );
                }
                stops = parsedStops;
              }
            }
          }
        } catch (_) {
          stops = const [];
        }
      }

      if (mounted && requestId == _vehicleRequestNonce) {
        refreshState(() {
          _vehicleMarkers = markers;
          _nearbyStops = shouldLoadStops ? stops : const [];
          if (_selectedVehicleMarkerId != null &&
              !markers.any((m) => m.markerId == _selectedVehicleMarkerId)) {
            _selectedVehicleMarkerId = null;
          }
          if (_selectedStopMarkerId != null &&
              !_nearbyStops.any((s) => s.stopId == _selectedStopMarkerId)) {
            _selectedStopMarkerId = null;
            _selectedStopQuickInfo = null;
            _isLoadingSelectedStopQuickInfo = false;
          }
        });
      }
    } catch (_) {
      if (mounted && requestId == _vehicleRequestNonce) {
        refreshState(() {
          _vehicleMarkers = const [];
          _nearbyStops = const [];
        });
      }
    } finally {
      if (mounted && requestId == _vehicleRequestNonce) {
        refreshState(() {
          _isLoadingVehicles = false;
        });
      }
    }
  }

  Future<void> _jumpToCurrentLocation() async {
    if (_isLocating) return;

    refreshState(() => _isLocating = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppTexts.mapLocationDisabled)));
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
            SnackBar(content: Text(AppTexts.mapPermissionRequired)),
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

      unawaited(
        Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        ).then(_moveToPosition).catchError((_) {}),
      );
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppTexts.mapTimeout)));
      }
    } on MissingPluginException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppTexts.mapPluginNotLoaded)));
      }
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppTexts.mapLocationFailed)));
      }
    } finally {
      if (mounted) {
        refreshState(() => _isLocating = false);
      }
    }
  }

  void _toggleVehicleLabel(String markerId) {
    debugPrint('[Map Debug] Vehicle clicked/toggled: ID=$markerId');
    _consumeNextMapTapClose();
    refreshState(() {
      _selectedStopMarkerId = null;
      _selectedStopQuickInfo = null;
      _isLoadingSelectedStopQuickInfo = false;
      _isRouteVehicleLabelVisible = false;
      if (_selectedVehicleMarkerId == markerId) {
        _selectedVehicleMarkerId = null;
      } else {
        _selectedVehicleMarkerId = markerId;
      }
    });
  }

  void _toggleStopLabel(_MapStopData stop) {
    debugPrint('[Map Debug] Stop clicked/toggled: ID=${stop.stopId}, Name=${stop.name}');
    _consumeNextMapTapClose();
    final isSame = _selectedStopMarkerId == stop.stopId;
    refreshState(() {
      _selectedVehicleMarkerId = null;
      _isRouteVehicleLabelVisible = false;
      if (isSame) {
        _selectedStopMarkerId = null;
        _selectedStopQuickInfo = null;
        _isLoadingSelectedStopQuickInfo = false;
      } else {
        _selectedStopMarkerId = stop.stopId;
        _selectedStopQuickInfo = null;
        _isLoadingSelectedStopQuickInfo = true;
      }
    });

    if (!isSame) {
      _loadSelectedStopQuickInfo(stop.stopId, fallbackName: stop.name);
    }
  }

  Future<void> _loadSelectedStopQuickInfo(
    String stopId, {
    required String fallbackName,
  }) async {
    try {
      final response = await _graphqlClient.execute(
        query: stopQuickInfoQuery,
        variables: {'stopId': stopId},
        timeout: const Duration(seconds: 10),
      );

      if (!mounted || _selectedStopMarkerId != stopId) {
        return;
      }

      if (!response.isSuccess) {
        refreshState(() {
          _isLoadingSelectedStopQuickInfo = false;
          _selectedStopQuickInfo = _StopQuickInfo(
            stopName: fallbackName,
            lineCount: 0,
            lines: const [],
          );
        });
        return;
      }

      final decoded = response.json;
      if (decoded == null) {
        refreshState(() {
          _isLoadingSelectedStopQuickInfo = false;
          _selectedStopQuickInfo = _StopQuickInfo(
            stopName: fallbackName,
            lineCount: 0,
            lines: const [],
          );
        });
        return;
      }

      final stop = decoded['data']?['stop'];
      if (stop is! Map) {
        refreshState(() {
          _isLoadingSelectedStopQuickInfo = false;
          _selectedStopQuickInfo = _StopQuickInfo(
            stopName: fallbackName,
            lineCount: 0,
            lines: const [],
          );
        });
        return;
      }

      final routes = stop['routes'];
      final routeMap = <String, _StopQuickRoute>{};
      if (routes is List) {
        for (final route in routes) {
          if (route is Map && route['gtfsId'] != null) {
            final id = route['gtfsId'].toString().trim();
            if (id.isNotEmpty) {
              final rawLabel = route['shortName']?.toString() ?? '';
              final label = _plainTextFromHtml(rawLabel).trim();
              if (label.isEmpty) {
                continue;
              }
              final rawColor = route['color']?.toString() ?? '0A84FF';
              final rawTextColor = route['textColor']?.toString() ?? 'FFFFFF';
              routeMap[id] = _StopQuickRoute(
                id: id,
                label: label,
                usesSpanFont: _containsSpanMarkup(rawLabel),
                backgroundColor: _parseRouteColor(rawColor, mode: 'BUS'),
                textColor: _parseTextColor(rawTextColor),
              );
            }
          }
        }
      }

      final lines = routeMap.values.toList()
        ..sort((a, b) => a.label.compareTo(b.label));

      final stopName = _plainTextFromHtml(
        stop['name']?.toString().trim().isNotEmpty == true
            ? stop['name'].toString()
            : fallbackName,
      );

      refreshState(() {
        _isLoadingSelectedStopQuickInfo = false;
        _selectedStopQuickInfo = _StopQuickInfo(
          stopName: stopName,
          lineCount: lines.length,
          lines: lines,
        );
      });
    } catch (_) {
      if (!mounted || _selectedStopMarkerId != stopId) {
        return;
      }
      refreshState(() {
        _isLoadingSelectedStopQuickInfo = false;
        _selectedStopQuickInfo = _StopQuickInfo(
          stopName: fallbackName,
          lineCount: 0,
          lines: const [],
        );
      });
    }
  }

  Future<void> _openStopDetails(_MapStopData stop) async {
    debugPrint('[Map Debug] Opening stop details: ID=${stop.stopId}, Name=${stop.name}');
    _consumeNextMapTapClose();
    final normalized = _normalizedStopGroupName(stop.name);
    final groupedIds = _nearbyStops
        .where((candidate) {
          if (_normalizedStopGroupName(candidate.name) != normalized) {
            return false;
          }
          final latDiff = (candidate.point.latitude - stop.point.latitude)
              .abs();
          final lonDiff = (candidate.point.longitude - stop.point.longitude)
              .abs();
          return latDiff <= 0.0025 && lonDiff <= 0.0025;
        })
        .map((candidate) => candidate.stopId)
        .toSet()
        .toList();

    if (widget.onOpenStopDetailsRequested != null) {
      widget.onOpenStopDetailsRequested!(
        stop.stopId,
        stop.name,
        stop.point,
        groupedIds,
      );
      return;
    }

    if (!mounted) {
      return;
    }

    if (_useDesktopDialogs) {
      await showAdaptiveDetailsDialog<void>(
        context: context,
        child: BlocProvider(
          create: (context) => StopDetailsCubit(
            transitRepository: sl<TransitRepository>(),
            mapCubit: context.read<MapCubit>(),
            stopId: stop.stopId,
            initialStopPoint: stop.point,
            initialStopName: stop.name,
            groupedStopIds: groupedIds,
          ),
          child: StopDetailsScreen(
            stopId: stop.stopId,
            initialStopName: stop.name,
            initialStopPoint: stop.point,
            groupedStopIds: groupedIds,
            onPlanRouteToStop: widget.onPlanRouteToStop,
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (context) => StopDetailsCubit(
            transitRepository: sl<TransitRepository>(),
            mapCubit: context.read<MapCubit>(),
            stopId: stop.stopId,
            initialStopPoint: stop.point,
            initialStopName: stop.name,
            groupedStopIds: groupedIds,
          ),
          child: StopDetailsScreen(
            stopId: stop.stopId,
            initialStopName: stop.name,
            initialStopPoint: stop.point,
            groupedStopIds: groupedIds,
            onPlanRouteToStop: widget.onPlanRouteToStop,
          ),
        ),
      ),
    );
  }

  void _toggleRouteStopLabel(RouteStopMarker stop) {
    _consumeNextMapTapClose();
    final isSame = _selectedStopMarkerId == stop.stopId;
    refreshState(() {
      _selectedVehicleMarkerId = null;
      _isRouteVehicleLabelVisible = false;
      if (isSame) {
        _selectedStopMarkerId = null;
        _selectedStopQuickInfo = null;
        _isLoadingSelectedStopQuickInfo = false;
      } else {
        _selectedStopMarkerId = stop.stopId;
        _selectedStopQuickInfo = null;
        _isLoadingSelectedStopQuickInfo = true;
      }
    });

    if (!isSame && stop.stopId != null) {
      _loadSelectedStopQuickInfo(stop.stopId!, fallbackName: stop.label);
    }
  }

  Widget _buildRouteStopInfoCard(RouteStopMarker stop) {
    final converted = _MapStopData(
      stopId: stop.stopId ?? '',
      name: stop.label,
      point: stop.point,
      bearing: stop.bearing,
    );

    return _buildStopInfoCard(converted);
  }

  void _consumeNextMapTapClose() {
    _suppressNextMapTapClose = true;
    Timer(const Duration(milliseconds: 120), () {
      _suppressNextMapTapClose = false;
    });
  }
  String _formatReversePhotonName(Map<String, dynamic> properties) {
    final name = properties['name']?.toString() ?? '';
    final street = properties['street']?.toString() ?? '';
    final houseNumber = properties['housenumber']?.toString() ?? '';
    final city = properties['city']?.toString() ?? '';
    final postcode = properties['postcode']?.toString() ?? '';

    final cleanName = (name.isNotEmpty && RegExp(r'^\d+$').hasMatch(name)) ? '' : name;
    final parts = <String>[];

    if (cleanName.isNotEmpty) {
      parts.add(cleanName);
      if (street.isNotEmpty) {
        if (houseNumber.isNotEmpty) {
          parts.add('$street $houseNumber');
        } else {
          parts.add(street);
        }
      }
    } else if (street.isNotEmpty) {
      if (houseNumber.isNotEmpty) {
        parts.add('$street $houseNumber');
      } else {
        parts.add(street);
      }
    }

    if (city.isNotEmpty && !parts.contains(city)) {
      parts.add(city);
    }
    if (postcode.isNotEmpty) {
      parts.add(postcode);
    }

    return parts.isEmpty ? '' : parts.join(', ');
  }
}
