part of 'map_view.dart';

extension _MapViewInteractions on _MapViewState {
  Future<void> _refreshVehiclesForVisibleBounds() async {
    if (!mounted) {
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
        if (item is! Map) {
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
            : (item['vehicleId']?.toString() ?? 'Jármű');
        final serviceLabel = _plainTextFromHtml(
          item['label'] is String
              ? item['label'] as String
              : (item['vehicleId']?.toString() ?? 'Jármű'),
        );
        final uicLabel = _plainTextFromHtml(
          item['uicCode'] is String
              ? item['uicCode'] as String
              : (item['vehicleId']?.toString() ?? 'Jármű'),
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
        final routeShortNameUsesSpanFont =
            _containsSpanMarkup(rawRouteShortName);

        final vehicleModel = _plainTextFromHtml(
          item['vehicleModel'] is String ? item['vehicleModel'] as String : "-",
        );

        final rawTripNumber = trip is Map && trip['tripShortName'] is String
            ? trip['tripShortName'] as String
            : '';
        final tripNumber = _plainTextFromHtml(rawTripNumber);
        final tripNumberUsesSpanFont = _containsSpanMarkup(rawTripNumber);
        final rawTripHeadsign = trip is Map && trip['tripHeadsign'] is String
            ? trip['tripHeadsign'] as String
            : '';
        final tripHeadsign = _plainTextFromHtml(rawTripHeadsign);
        final tripHeadsignUsesSpanFont = _containsSpanMarkup(rawTripHeadsign);
        final tripGtfsId =
            trip is Map && trip['gtfsId'] is String ? (trip['gtfsId'] as String) : '';
        final serviceDate =
            trip is Map && trip['serviceDate'] is String
                ? (trip['serviceDate'] as String)
                : _todayServiceDate();

        final nextStop = item['nextStop'];
        final prevOrCurrentStop = item['prevOrCurrentStop'];
        final arrivalDelaySeconds =
            nextStop is Map && nextStop['arrivalDelay'] is num
                ? (nextStop['arrivalDelay'] as num).toInt()
                : (prevOrCurrentStop is Map &&
                        prevOrCurrentStop['arrivalDelay'] is num
                    ? (prevOrCurrentStop['arrivalDelay'] as num).toInt()
                    : (prevOrCurrentStop is Map &&
                            prevOrCurrentStop['departureDelay'] is num
                        ? (prevOrCurrentStop['departureDelay'] as num).toInt()
                        : null));

        String? nextStopName;
        final stopRelationship = item['stopRelationship'];
        if (stopRelationship is List) {
          int bestRank = 1 << 30;
          for (final rel in stopRelationship) {
            if (rel is! Map) {
              continue;
            }
            final stop = rel['stop'];
            final name = stop is Map ? stop['name'] : null;
            final status = rel['status'];
            if (name is String && name.trim().isNotEmpty) {
              final rank = _stopStatusRank(status is String ? status : '');
              if (rank < bestRank) {
                bestRank = rank;
                nextStopName = _plainTextFromHtml(name).trim();
              }
            }
          }
        } else if (stopRelationship is Map) {
          final stop = stopRelationship['stop'];
          final name = stop is Map ? stop['name'] : null;
          if (name is String && name.trim().isNotEmpty) {
            nextStopName = _plainTextFromHtml(name).trim();
          }
        }

        final color = route is Map && route['color'] is String
            ? route['color'] as String
            : '0A84FF';
        final textColor = route is Map && route['textColor'] is String
            ? route['textColor'] as String
            : 'FFFFFF';
        final markerTextColor = _parseTextColor(textColor);
        final markerColor = _parseRouteColor(color, mode: mode);
        final markerOutlineAndHeadingColor = markerTextColor;
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
            tripNumber: tripNumber,
            tripNumberUsesSpanFont: tripNumberUsesSpanFont,
            tripHeadsign: tripHeadsign,
            tripHeadsignUsesSpanFont: tripHeadsignUsesSpanFont,
            vehicleModel: vehicleModel,
            arrivalDelaySeconds: arrivalDelaySeconds,
            nextStopName: nextStopName,
            mode: mode,
            markerColor: markerColor,
            markerTextColor: markerTextColor,
            markerOutlineAndHeadingColor: markerOutlineAndHeadingColor,
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
                  final stopId = item['gtfsId']?.toString().trim().isNotEmpty == true
                      ? item['gtfsId'].toString().trim()
                      : '${lat.toStringAsFixed(6)}:${lon.toStringAsFixed(6)}';
                  final stopName = _plainTextFromHtml(
                    item['name']?.toString() ?? 'Megálló',
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A helymeghatározás nincs bekapcsolva.'),
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
            const SnackBar(
              content: Text('A helyhozzáférés engedély szükséges.'),
            ),
          );
        }
        return;
      }

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A pozíció lekérése túl sokáig tartott.'),
          ),
        );
      }
    } on MissingPluginException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A lokáció plugin nincs betöltve. Indítsd újra az appot.',
            ),
          ),
        );
      }
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A lokáció lekérése nem sikerült.')),
        );
      }
    } finally {
      if (mounted) {
        refreshState(() => _isLocating = false);
      }
    }
  }

  void _toggleVehicleLabel(String markerId) {
    _consumeNextMapTapClose();
    refreshState(() {
      _selectedStopMarkerId = null;
      _selectedStopQuickInfo = null;
      _isLoadingSelectedStopQuickInfo = false;
      if (_selectedVehicleMarkerId == markerId) {
        _selectedVehicleMarkerId = null;
      } else {
        _selectedVehicleMarkerId = markerId;
      }
    });
  }

  void _toggleStopLabel(_MapStopData stop) {
    _consumeNextMapTapClose();
    final isSame = _selectedStopMarkerId == stop.stopId;
    refreshState(() {
      _selectedVehicleMarkerId = null;
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
          _selectedStopQuickInfo =
              _StopQuickInfo(stopName: fallbackName, lineCount: 0, lines: const []);
        });
        return;
      }

      final decoded = response.json;
      if (decoded == null) {
        refreshState(() {
          _isLoadingSelectedStopQuickInfo = false;
          _selectedStopQuickInfo =
              _StopQuickInfo(stopName: fallbackName, lineCount: 0, lines: const []);
        });
        return;
      }

      final stop = decoded['data']?['stop'];
      if (stop is! Map) {
        refreshState(() {
          _isLoadingSelectedStopQuickInfo = false;
          _selectedStopQuickInfo =
              _StopQuickInfo(stopName: fallbackName, lineCount: 0, lines: const []);
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
        _selectedStopQuickInfo =
            _StopQuickInfo(stopName: fallbackName, lineCount: 0, lines: const []);
      });
    }
  }

  Future<void> _openStopDetails(_MapStopData stop) async {
    _consumeNextMapTapClose();
    final normalized = _normalizedStopGroupName(stop.name);
    final groupedIds = _nearbyStops
        .where((candidate) {
          if (_normalizedStopGroupName(candidate.name) != normalized) {
            return false;
          }
          final latDiff = (candidate.point.latitude - stop.point.latitude).abs();
          final lonDiff = (candidate.point.longitude - stop.point.longitude).abs();
          return latDiff <= 0.0025 && lonDiff <= 0.0025;
        })
        .map((candidate) => candidate.stopId)
        .toSet()
        .toList();

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
            child: StopDetailsScreen(
              stopId: stop.stopId,
              initialStopName: stop.name,
              initialStopPoint: stop.point,
              groupedStopIds: groupedIds,
              onShowTripOnBackgroundMap: widget.onShowTripOnBackgroundMap,
            ),
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StopDetailsScreen(
          stopId: stop.stopId,
          initialStopName: stop.name,
          initialStopPoint: stop.point,
          groupedStopIds: groupedIds,
          onShowTripOnBackgroundMap: widget.onShowTripOnBackgroundMap,
        ),
      ),
    );
  }

  void _consumeNextMapTapClose() {
    _suppressNextMapTapClose = true;
    Timer(const Duration(milliseconds: 120), () {
      _suppressNextMapTapClose = false;
    });
  }
}
