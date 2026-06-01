import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../services/graphql/graphql_client.dart';
import '../services/graphql/graphql_queries.dart';
import '../utils/markup_text_utils.dart';
import '../widgets/maps/plan_map_view.dart';
import '../widgets/maps/route_map_data.dart';
import 'stop_details_screen.dart';

typedef TripDetailsBackgroundMapCallback =
    void Function(RouteMapData routeData, RouteVehicleMarker? vehicleMarker);
typedef TripDetailsOpenRequestCallback =
    void Function(String tripId, String serviceDay);
typedef TripDetailsOpenStopRequestCallback =
    void Function(String stopId, String stopName);

class _TripStopQuickRoute {
  final String id;
  final String label;
  final bool usesSpanFont;
  final Color backgroundColor;
  final Color textColor;

  const _TripStopQuickRoute({
    required this.id,
    required this.label,
    required this.usesSpanFont,
    required this.backgroundColor,
    required this.textColor,
  });
}

class _TripStopQuickInfo {
  final String stopId;
  final String stopName;
  final List<_TripStopQuickRoute> lines;

  const _TripStopQuickInfo({
    required this.stopId,
    required this.stopName,
    required this.lines,
  });
}

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
  static const String _spanFontFamily = 'MNR2007';
  static const double _spanFontScale = 28 / 16;
  static const double _desktopBreakpoint = 700;
  static const double _mobileSheetMinSize = 0.16;
  static const double _mobileSheetInitialSize = 0.24;
  static const double _mobileSheetMaxSize = 0.9;
  static const bool _debugDumpDecodedPolyline = true;
  final GraphqlClient _graphqlClient = const GraphqlClient();

  bool _isLoading = true;
  bool _showMap = false;
  String? _error;
  Map<String, dynamic>? _trip;
  _TripStopQuickInfo? _selectedStopQuickInfo;
  bool _isLoadingSelectedStopQuickInfo = false;
  String? _selectedStopQuickInfoStopId;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadTrip();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => _loadTrip());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTrip() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _graphqlClient.execute(
        query: tripDetailsQuery,
        variables: {'tripId': widget.tripId, 'serviceDay': widget.serviceDay},
      );

      if (!response.isSuccess) {
        setState(() {
          _error = 'Trip lekérdezés hiba: HTTP ${response.statusCode}';
          _isLoading = false;
        });
        return;
      }

      final decoded = response.json;
      if (decoded == null) {
        setState(() {
          _error = 'Érvénytelen válasz formátum.';
          _isLoading = false;
        });
        return;
      }

      final data = decoded['data'];
      final trip = data is Map ? data['trip'] : null;
      if (trip is! Map) {
        setState(() {
          _error = 'A járat adatai nem érhetők el.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _trip = trip.cast<String, dynamic>();
        _isLoading = false;
      });

      if (_isDesktopBackgroundMapMode && widget.onShowOnBackgroundMap != null) {
        final loadedTrip = trip.cast<String, dynamic>();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _showTripOnBackgroundMap(loadedTrip, closeAfter: false);
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Nem sikerült a járat adatait lekérni: $e';
        _isLoading = false;
      });
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
            useMobileMapSheet || _showMap ? 'Járat térképen' : 'Járat adatai',
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
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadTrip,
            ),
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
              FilledButton(
                onPressed: _loadTrip,
                child: const Text('Újrapróbálás'),
              ),
            ],
          ),
        ),
      );
    }

    final trip = _trip;
    if (trip == null) {
      return const Center(child: Text('Nincs megjeleníthető adat.'));
    }

    if (_useMobileMapSheet) {
      return _buildMobileMapWithDetailsSheet(trip);
    }

    return _showMap ? _buildMapView(trip) : _buildTableView(trip);
  }

  Widget _buildTableView(Map<String, dynamic> trip) {
    final stopTimes = _stopTimes(trip);
    final route = _route(trip);
    final rawTripHeadsign = trip['tripHeadsign']?.toString() ?? '-';
    final tripHeadsign = _plainText(rawTripHeadsign);
    final tripHeadsignUsesSpanFont = _containsSpanMarkup(rawTripHeadsign);
    final title = _plainText(trip['tripShortName']?.toString() ?? '-');
    final rawLineLabel = route['shortName']?.toString() ?? '-';
    final lineLabel = _plainText(rawLineLabel);
    final lineLabelUsesSpanFont = _containsSpanMarkup(rawLineLabel);
    final routeColor = _hexColor(route['color']?.toString() ?? '0A84FF');
    final routeTextColor = _hexColor(
      route['textColor']?.toString() ?? 'FFFFFF',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildLineBadge(
                    lineLabel: lineLabel,
                    routeColor: routeColor,
                    routeTextColor: routeTextColor,
                    useSpanFont: lineLabelUsesSpanFont,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      softWrap: true,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                tripHeadsign,
                softWrap: true,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildStopTimesDataTable(stopTimes),
          ),
        ),
      ],
    );
  }

  Widget _buildStopTimesDataTable(List<Map<String, dynamic>> stopTimes) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        columns: const [
          DataColumn(label: Text('Megálló')),
          DataColumn(label: Text('Érkezés')),
          DataColumn(label: Text('Indulás')),
        ],
        rows: stopTimes.map((stopTime) {
          final stop = stopTime['stop'];
          final stopName = _plainText(
            stop is Map ? (stop['name']?.toString() ?? '-') : '-',
          );
          final stopId = stop is Map ? (stop['id']?.toString().trim() ?? '') : '';
          final passedStop = _isPassedStop(stopTime);
          
          LatLng? point;
          if (stop is Map && stop['lat'] is num && stop['lon'] is num) {
            point = LatLng((stop['lat'] as num).toDouble(), (stop['lon'] as num).toDouble());
          }

          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 180,
                  child: stopId.isNotEmpty
                      ? InkWell(
                          onTap: () => _openStopDetails(
                            stopId: stopId,
                            stopName: stopName,
                            initialStopPoint: point,
                          ),
                          child: Text(
                            stopName,
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        )
                      : Text(stopName),
                ),
              ),
              DataCell(
                _buildRealtimeTime(
                  scheduled: _asNum(stopTime['scheduledArrival']),
                  realtime: _asNum(stopTime['realtimeArrival']),
                  delay: _asNum(stopTime['arrivalDelay']),
                  isRealtime: stopTime['realtime'] == true,
                  passedStop: passedStop,
                ),
              ),
              DataCell(
                _buildRealtimeTime(
                  scheduled: _asNum(stopTime['scheduledDeparture']),
                  realtime: _asNum(stopTime['realtimeDeparture']),
                  delay: _asNum(stopTime['departureDelay']),
                  isRealtime: stopTime['realtime'] == true,
                  passedStop: passedStop,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  bool get _isDesktopBackgroundMapMode {
    return widget.onShowOnBackgroundMap != null &&
        MediaQuery.of(context).size.width > _desktopBreakpoint;
  }

  bool get _useMobileMapSheet {
    return MediaQuery.of(context).size.width <= _desktopBreakpoint;
  }

  Widget _buildMobileMapWithDetailsSheet(Map<String, dynamic> trip) {
    final routeData = _buildTripRouteMapData(trip);
    final route = _route(trip);
    final routeColor = _hexColor(route['color']?.toString() ?? '0A84FF');
    final routeTextColor = _hexColor(
      route['textColor']?.toString() ?? 'FFFFFF',
    );
    final vehicleMarker = _buildTripVehicleMarker(
      trip,
      routeColor: routeColor,
      routeTextColor: routeTextColor,
    );
    final stopTimes = _stopTimes(trip);
    final rawTripHeadsign = trip['tripHeadsign']?.toString() ?? '-';
    final tripHeadsign = _plainText(rawTripHeadsign);
    final rawLineLabel = route['shortName']?.toString() ?? '-';
    final lineLabel = _plainText(rawLineLabel);
    final lineLabelUsesSpanFont = _containsSpanMarkup(rawLineLabel);
    final tripShortName = _plainText(trip['tripShortName']?.toString() ?? '-');
    final screenHeight = MediaQuery.of(context).size.height;
    final controlsBottomInset = screenHeight * _mobileSheetInitialSize + 24;

    return Stack(
      children: [
        Positioned.fill(
          child: PlanMapView(
            routeData: routeData,
            controlsBottomInset: controlsBottomInset,
            fitPadding: EdgeInsets.fromLTRB(
              48,
              48,
              48,
              controlsBottomInset + 120,
            ),
            showStopLabels: false,
            useBaseMapStopIcon: true,
            vehicleMarker: vehicleMarker,
            enableVehicleInfoLabelTap: vehicleMarker != null,
            vehicleInfoCardBuilder: vehicleMarker == null
                ? null
                : (context) => _buildVehicleTapInfoCard(
                    trip,
                    routeColor,
                    routeTextColor,
                  ),
            enableStopInfoLabelTap: true,
            stopInfoCardBuilder: (context, stop) => _buildRouteStopTapInfoCard(
              stop,
            ),
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: _mobileSheetInitialSize,
          minChildSize: _mobileSheetMinSize,
          maxChildSize: _mobileSheetMaxSize,
          snap: true,
          snapSizes: const [
            _mobileSheetInitialSize,
            0.5,
            _mobileSheetMaxSize,
          ],
          builder: (context, scrollController) {
            final colorScheme = Theme.of(context).colorScheme;
            return Material(
              elevation: 8,
              color: colorScheme.surface.withValues(alpha: 0.97),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
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
                  const SizedBox(height: 8),
                  Text(
                    'Pöccintsd fel az összes időadathoz',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildLineBadge(
                        lineLabel: lineLabel,
                        routeColor: routeColor,
                        routeTextColor: routeTextColor,
                        useSpanFont: lineLabelUsesSpanFont,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tripShortName,
                          style: Theme.of(context).textTheme.titleMedium,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tripHeadsign,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStopTimesDataTable(stopTimes),
                ],
              ),
            );
          },
        ),
      ],
    );
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
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920, maxHeight: 860),
            child: StopDetailsScreen(
              stopId: stopId,
              initialStopName: stopName,
              initialStopPoint: initialStopPoint,
              onShowTripOnBackgroundMap: widget.onShowOnBackgroundMap,
              onOpenTripDetailsRequested: widget.onOpenTripDetailsRequested,
            ),
          ),
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

  Widget _buildRouteStopTapInfoCard(RouteStopMarker stop) {
    final stopId = stop.stopId?.trim() ?? '';
    final stopName = _selectedStopQuickInfo?.stopName.trim().isNotEmpty == true
        ? _selectedStopQuickInfo!.stopName.trim()
        : stop.label;
    final lines = _selectedStopQuickInfo?.lines ?? const <_TripStopQuickRoute>[];

    if (stopId.isNotEmpty &&
        _selectedStopQuickInfoStopId != stopId &&
        !_isLoadingSelectedStopQuickInfo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (_selectedStopQuickInfoStopId != stopId) {
          _loadSelectedStopQuickInfo(stopId, fallbackName: stop.label);
        }
      });
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              stop.label,
              textAlign: TextAlign.center,
              softWrap: true,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            if (_isLoadingSelectedStopQuickInfo && stopId.isNotEmpty)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (lines.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: lines.map(_buildTripStopRouteBadge).toList(),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: stopId.isEmpty
                    ? null
                    : () {
                        _openStopDetails(
                          stopId: stopId,
                          stopName: stopName,
                          initialStopPoint: stop.point,
                        );
                      },
                child: const Text('Megálló adatai'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripStopRouteBadge(_TripStopQuickRoute line) {
    return Container(
      padding: line.usesSpanFont
          ? const EdgeInsets.symmetric(horizontal: 0, vertical: 0)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: line.backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        line.label,
        style: TextStyle(
          color: line.textColor,
          fontSize: line.usesSpanFont ? 12 * _spanFontScale : 12,
          fontWeight: FontWeight.w700,
          fontFamily: line.usesSpanFont ? _spanFontFamily : null,
          leadingDistribution: line.usesSpanFont
              ? TextLeadingDistribution.even
              : null,
          height: line.usesSpanFont ? 1.0 : null,
        ),
      ),
    );
  }

  Future<void> _loadSelectedStopQuickInfo(
    String stopId, {
    required String fallbackName,
  }) async {
    setState(() {
      _isLoadingSelectedStopQuickInfo = true;
      _selectedStopQuickInfoStopId = stopId;
      _selectedStopQuickInfo = null;
    });

    try {
      final response = await _graphqlClient.execute(
        query: stopQuickInfoQuery,
        variables: {'stopId': stopId},
        timeout: const Duration(seconds: 10),
      );

      if (!mounted || _selectedStopQuickInfoStopId != stopId) {
        return;
      }

      if (!response.isSuccess) {
        setState(() {
          _isLoadingSelectedStopQuickInfo = false;
          _selectedStopQuickInfo = _TripStopQuickInfo(
            stopId: stopId,
            stopName: fallbackName,
            lines: const [],
          );
        });
        return;
      }

      final decoded = response.json;
      if (decoded == null) {
        setState(() {
          _isLoadingSelectedStopQuickInfo = false;
          _selectedStopQuickInfo = _TripStopQuickInfo(
            stopId: stopId,
            stopName: fallbackName,
            lines: const [],
          );
        });
        return;
      }

      final stop = decoded['data']?['stop'];
      if (stop is! Map) {
        setState(() {
          _isLoadingSelectedStopQuickInfo = false;
          _selectedStopQuickInfo = _TripStopQuickInfo(
            stopId: stopId,
            stopName: fallbackName,
            lines: const [],
          );
        });
        return;
      }

      final routes = stop['routes'];
      final routeMap = <String, _TripStopQuickRoute>{};
      if (routes is List) {
        for (final route in routes) {
          if (route is Map && route['gtfsId'] != null) {
            final id = route['gtfsId'].toString().trim();
            if (id.isEmpty) {
              continue;
            }
            var rawLabel = route['shortName']?.toString() ?? '';
            if (rawLabel.trim().isEmpty) {
              rawLabel = route['longName']?.toString() ?? '';
            }
            if (rawLabel.trim().isEmpty) {
              rawLabel = '-';
            }
            final label = _plainText(rawLabel);
            routeMap[id] = _TripStopQuickRoute(
              id: id,
              label: label,
              usesSpanFont: _containsSpanMarkup(rawLabel),
              backgroundColor: _hexColor(route['color']?.toString() ?? '0A84FF'),
              textColor: _hexColor(route['textColor']?.toString() ?? 'FFFFFF'),
            );
          }
        }
      }

      final lines = routeMap.values.toList()
        ..sort((a, b) => a.label.compareTo(b.label));

      final stopName = _plainText(
        stop['name']?.toString().trim().isNotEmpty == true
            ? stop['name'].toString()
            : fallbackName,
      );

      setState(() {
        _isLoadingSelectedStopQuickInfo = false;
        _selectedStopQuickInfo = _TripStopQuickInfo(
          stopId: stopId,
          stopName: stopName,
          lines: lines,
        );
      });
    } catch (_) {
      if (!mounted || _selectedStopQuickInfoStopId != stopId) {
        return;
      }
      setState(() {
        _isLoadingSelectedStopQuickInfo = false;
        _selectedStopQuickInfo = _TripStopQuickInfo(
          stopId: stopId,
          stopName: fallbackName,
          lines: const [],
        );
      });
    }
  }

  void _showTripOnBackgroundMap(
    Map<String, dynamic> trip, {
    required bool closeAfter,
  }) {
    final route = _route(trip);
    final routeColor = _hexColor(route['color']?.toString() ?? '0A84FF');
    final routeTextColor = _hexColor(
      route['textColor']?.toString() ?? 'FFFFFF',
    );
    final routeData = _buildTripRouteMapData(trip);
    final vehicleMarker = _buildTripVehicleMarker(
      trip,
      routeColor: routeColor,
      routeTextColor: routeTextColor,
    );

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
    final routeData = _buildTripRouteMapData(trip);
    final route = _route(trip);
    final routeColor = _hexColor(route['color']?.toString() ?? '0A84FF');
    final routeTextColor = _hexColor(
      route['textColor']?.toString() ?? 'FFFFFF',
    );
    final vehicleMarker = _buildTripVehicleMarker(
      trip,
      routeColor: routeColor,
      routeTextColor: routeTextColor,
    );

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
                : (context) => _buildVehicleTapInfoCard(
                    trip,
                    routeColor,
                    routeTextColor,
                  ),
            enableStopInfoLabelTap: true,
            stopInfoCardBuilder: (context, stop) => _buildRouteStopTapInfoCard(
              stop,
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: SafeArea(
            top: false,
            child: _buildBottomInfoCard(trip, routeColor, routeTextColor),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomInfoCard(
    Map<String, dynamic> trip,
    Color routeColor,
    Color routeTextColor,
  ) {
    final info = _buildTripVehicleInfo(trip);

    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                _buildLineBadge(
                  lineLabel: info.line,
                  routeColor: routeColor,
                  routeTextColor: routeTextColor,
                  useSpanFont: info.lineUsesSpanFont,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${info.tripShortName} - ${info.tripHeadsign}',
                    softWrap: true,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(info.vehicleInfoText, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _showMap = false;
                  });
                },
                child: const Text('Vissza'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTapInfoCard(
    Map<String, dynamic> trip,
    Color routeColor,
    Color routeTextColor,
  ) {
    final info = _buildTripVehicleInfo(trip);
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLineBadge(
                  lineLabel: info.line,
                  routeColor: routeColor,
                  routeTextColor: routeTextColor,
                  useSpanFont: info.lineUsesSpanFont,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    info.tripShortName,
                    softWrap: true,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              info.tripHeadsign,
              softWrap: true,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              info.vehicleInfoText,
              maxLines: 5,
              style: const TextStyle(
                fontSize: 12,
                height: 1.15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({
    String line,
    bool lineUsesSpanFont,
    String tripShortName,
    bool tripShortNameUsesSpanFont,
    String tripHeadsign,
    bool tripHeadsignUsesSpanFont,
    String vehicleInfoText,
  })
  _buildTripVehicleInfo(Map<String, dynamic> trip) {
    final route = _route(trip);
    final vehicle = _firstVehicle(trip);
    final hasVehicle = vehicle.isNotEmpty;
    final rawLine = route['shortName']?.toString() ?? '-';
    final line = _plainText(rawLine);
    final lineUsesSpanFont = _containsSpanMarkup(rawLine);
    final rawTripHeadsign = trip['tripHeadsign']?.toString() ?? '-';
    final tripHeadsign = _plainText(rawTripHeadsign);
    final tripHeadsignUsesSpanFont = _containsSpanMarkup(rawTripHeadsign);
    final vehicleTrip = vehicle['trip'];
    final vehicleTripGtfsId = vehicleTrip is Map
        ? vehicleTrip['gtfsId']?.toString()
        : null;
    final vehicleId = vehicle['vehicleId']?.toString();
    final rawVehicleLabel = vehicle['label']?.toString() ?? '';
    final label = !hasVehicle
        ? ''
        : (vehicleId != null &&
              vehicleTripGtfsId != null &&
              vehicleId == vehicleTripGtfsId)
        ? 'Becsült pozíció'
      : rawVehicleLabel.trim().isNotEmpty
      ? _plainText(rawVehicleLabel)
        : 'ismeretlen jármű';
    final routeMode = route['mode']?.toString() ?? '';
    final fallbackModel = routeMode == 'RAIL_REPLACEMENT_BUS'
        ? 'vonatpótló busz'
        : 'Ismeretlen';
    final rawVehicleModel = vehicle['vehicleModel']?.toString() ?? '';
    final model = rawVehicleModel.trim().isNotEmpty
        ? _plainText(rawVehicleModel)
        : fallbackModel;

    final rawTripShortName = trip['tripShortName']?.toString() ?? '-';
    final tripShortName = _plainText(rawTripShortName);
    final tripShortNameUsesSpanFont = _containsSpanMarkup(rawTripShortName);

    final delayText = _delayText(null);

    String nextStopName = '-';
    final stopRelationship = vehicle['stopRelationship'];
    if (stopRelationship is Map) {
      final stop = stopRelationship['stop'];
      if (stop is Map && stop['name'] is String) {
        nextStopName = _plainText(stop['name'] as String);
      }
    } else if (stopRelationship is List) {
      for (final rel in stopRelationship) {
        if (rel is! Map) {
          continue;
        }
        final stop = rel['stop'];
        if (stop is Map && stop['name'] is String) {
          final name = _plainText(stop['name'] as String).trim();
          if (name.isNotEmpty) {
            nextStopName = name;
            break;
          }
        }
      }
    }

    final vehicleInfoText = hasVehicle
        ? '$label\n$model\n$delayText\nköv: $nextStopName'
        : 'Nem található jármű';

    return (
      line: line,
      lineUsesSpanFont: lineUsesSpanFont,
      tripShortName: tripShortName,
      tripShortNameUsesSpanFont: tripShortNameUsesSpanFont,
      tripHeadsign: tripHeadsign,
      tripHeadsignUsesSpanFont: tripHeadsignUsesSpanFont,
      vehicleInfoText: vehicleInfoText,
    );
  }

  Widget _buildRealtimeTime({
    required num? scheduled,
    required num? realtime,
    required num? delay,
    required bool isRealtime,
    required bool passedStop,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseTextColor = colorScheme.onSurface;
    final mutedTextColor = colorScheme.onSurfaceVariant;
    final scheduledText = _formatEpoch(scheduled);
    final realtimeText = _formatEpoch(realtime);
    final hasRealtimeDelta =
        scheduled != null && realtime != null && realtime != scheduled;

    if (passedStop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            scheduledText,
            style: TextStyle(
              decoration: TextDecoration.lineThrough,
              color: mutedTextColor,
            ),
          ),
          Text(realtimeText, style: TextStyle(color: mutedTextColor)),
        ],
      );
    }

    if (!isRealtime) {
      return Text(
        realtimeText,
        style: TextStyle(color: baseTextColor, fontWeight: FontWeight.w700),
      );
    }

    if (!hasRealtimeDelta) {
      return Text(
        realtimeText,
        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w700),
      );
    }

    final color = (delay ?? 0) > 0
        ? Colors.red
        : (delay ?? 0) < 0
        ? Colors.blue
        : baseTextColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          scheduledText,
          style: TextStyle(
            decoration: TextDecoration.lineThrough,
            color: baseTextColor,
          ),
        ),
        Text(
          realtimeText,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _stopTimes(Map<String, dynamic> trip) {
    final stopTimes = trip['stoptimes'];
    if (stopTimes is! List) {
      return const [];
    }
    return stopTimes
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
  }

  Map<String, dynamic> _route(Map<String, dynamic> trip) {
    final route = trip['route'];
    return route is Map ? route.cast<String, dynamic>() : const {};
  }

  Map<String, dynamic> _firstVehicle(Map<String, dynamic> trip) {
    final pattern = trip['pattern'];
    final vehicles = pattern is Map
        ? pattern['vehiclePositions']
        : trip['vehiclePositions'];
    if (vehicles is List && vehicles.isNotEmpty && vehicles.first is Map) {
      return (vehicles.first as Map).cast<String, dynamic>();
    }
    return const {};
  }

  List<({LatLng point, String label, String? stopId})> _stopPoints(
    Map<String, dynamic> trip,
  ) {
    final result = <({LatLng point, String label, String? stopId})>[];
    for (final stopTime in _stopTimes(trip)) {
      final stop = stopTime['stop'];
      if (stop is! Map) {
        continue;
      }
      final lat = stop['lat'];
      final lon = stop['lon'];
      final name = stop['name']?.toString() ?? '';
      if (lat is num && lon is num) {
        result.add(
          (
            point: LatLng(lat.toDouble(), lon.toDouble()),
            label: _plainText(name),
            stopId: stop['id']?.toString().trim(),
          ),
        );
      }
    }
    return result;
  }

  List<LatLng> _tripGeometryPoints(Map<String, dynamic> trip) {
    final tripGeometry = trip['tripGeometry'];
    if (tripGeometry is! Map) {
      return const [];
    }

    final encoded = tripGeometry['points'];
    if (encoded is! String || encoded.isEmpty) {
      return const [];
    }

    final points = _decodePolyline(encoded);
    
    return points;
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lon = 0;

    while (index < encoded.length) {
      var value = 0;
      var shift = 0;
      var chunk = 0;
      do {
        chunk = encoded.codeUnitAt(index++) - 63;
        value |= (chunk & 0x1f) << shift;
        shift += 5;
      } while (chunk >= 0x20);
      final latMagnitude = value >> 1;
      final deltaLat = (value & 1) != 0 ? -(latMagnitude + 1) : latMagnitude;
      lat += deltaLat;

      value = 0;
      shift = 0;
      do {
        chunk = encoded.codeUnitAt(index++) - 63;
        value |= (chunk & 0x1f) << shift;
        shift += 5;
      } while (chunk >= 0x20);
      final lonMagnitude = value >> 1;
      final deltaLon = (value & 1) != 0 ? -(lonMagnitude + 1) : lonMagnitude;
      lon += deltaLon;

      points.add(LatLng(lat / 1e5, lon / 1e5));
    }

    return points;
  }

  

  RouteMapData _buildTripRouteMapData(Map<String, dynamic> trip) {
    final route = _route(trip);
    final routeColor = _hexColor(route['color']?.toString() ?? '0A84FF');
    final routeTextColor = _hexColor(
      route['textColor']?.toString() ?? 'FFFFFF',
    );
    final displayedRouteColor = _resolvedPolylineColor(
      routeColor: routeColor,
      routeTextColor: routeTextColor,
    );

    final stopPoints = _stopPoints(trip);
    final geometryPoints = _tripGeometryPoints(trip);

    var finalGeometryPoints = geometryPoints;
    if (finalGeometryPoints.length < 2 && stopPoints.length >= 2) {
      finalGeometryPoints = stopPoints.map((e) => e.point).toList();
    }

    final segments = <RouteSegment>[];
    if (finalGeometryPoints.length >= 2) {
      segments.add(
        RouteSegment(points: finalGeometryPoints, color: displayedRouteColor),
      );
    }

    final stops = <RouteStopMarker>[];
    for (var i = 0; i < stopPoints.length; i++) {
      final item = stopPoints[i];
      final type = i == 0
          ? RouteStopType.start
          : (i == stopPoints.length - 1
                ? RouteStopType.end
                : RouteStopType.transfer);
      stops.add(
        RouteStopMarker(
          point: item.point,
          label: item.label,
          type: type,
          stopId: item.stopId,
        ),
      );
    }

    return RouteMapData(segments: segments, stops: stops);
  }

  RouteVehicleMarker? _buildTripVehicleMarker(
    Map<String, dynamic> trip, {
    required Color routeColor,
    required Color routeTextColor,
  }) {
    final vehicle = _firstVehicle(trip);
    if (vehicle.isEmpty) {
      return null;
    }

    final lat = vehicle['lat'];
    final lon = vehicle['lon'];
    if (lat is! num || lon is! num) {
      return null;
    }

    final latValue = lat.toDouble();
    final lonValue = lon.toDouble();

    final heading = vehicle['heading'] is num
        ? (vehicle['heading'] as num).toDouble()
        : 0.0;
    final info = _buildTripVehicleInfo(trip);

    return RouteVehicleMarker(
      point: LatLng(latValue, lonValue),
      headingDegrees: heading,
      markerColor: routeColor,
      markerTextColor: routeTextColor,
      lineLabel: info.line,
      lineLabelUsesSpanFont: info.lineUsesSpanFont,
      tripShortName: info.tripShortName,
      tripShortNameUsesSpanFont: info.tripShortNameUsesSpanFont,
      tripHeadsign: info.tripHeadsign,
      tripHeadsignUsesSpanFont: info.tripHeadsignUsesSpanFont,
      vehicleInfoText: info.vehicleInfoText,
      tripId: widget.tripId,
      //serviceDay: widget.serviceDay,
    );
  }

  Color _hexColor(String rawHex) {
    final hex = rawHex.replaceAll('#', '').trim();
    final parsed = int.tryParse(hex.length == 6 ? hex : '0A84FF', radix: 16);
    return parsed == null
        ? const Color(0xFF0A84FF)
        : Color(0xFF000000 | parsed);
  }

  Color _resolvedPolylineColor({
    required Color routeColor,
    required Color routeTextColor,
  }) {
    return _isWhiteLike(routeColor) ? routeTextColor : routeColor;
  }

  bool _isWhiteLike(Color color) {
    return (color.red >= 254 && color.green >= 254 && color.blue >= 254);
  }

  bool _isPassedStop(Map<String, dynamic> stopTime) {
    final reference =
        _asNum(stopTime['realtimeDeparture']) ??
        _asNum(stopTime['scheduledDeparture']) ??
        _asNum(stopTime['realtimeArrival']) ??
        _asNum(stopTime['scheduledArrival']);
    if (reference == null) {
      return false;
    }
    final dt = _resolveDateTime(reference);
    if (dt == null) {
      return false;
    }
    return dt.isBefore(DateTime.now());
  }

  Widget _buildLineBadge({
    required String lineLabel,
    required Color routeColor,
    required Color routeTextColor,
    required bool useSpanFont,
  }) {
    return Container(
      padding: useSpanFont
          ? EdgeInsets.symmetric(horizontal: 0, vertical: 0)
          : EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: routeColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        lineLabel,
        style: TextStyle(
          color: routeTextColor,
          fontWeight: FontWeight.w700,
          fontSize: useSpanFont ? 12 * _spanFontScale : null,
          fontFamily: useSpanFont ? _spanFontFamily : null,
          leadingDistribution: useSpanFont
              ? TextLeadingDistribution.even
              : null,
          height: useSpanFont ? 1.0 : null,
        ),
      ),
    );
  }

  bool _containsSpanMarkup(String value) {
    return containsSpanMarkup(value);
  }

  num? _asNum(dynamic value) => value is num ? value : null;

  String _formatEpoch(num? value) {
    final dt = value == null ? null : _resolveDateTime(value);
    if (dt == null) {
      return '-';
    }
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  DateTime? _resolveDateTime(num rawValue) {
    final intValue = rawValue.toInt();

    if (intValue > 9999999999) {
      return DateTime.fromMillisecondsSinceEpoch(intValue);
    }

    if (intValue > 2000000000) {
      return DateTime.fromMillisecondsSinceEpoch(intValue * 1000);
    }

    final serviceDate = _parseServiceDay(widget.serviceDay);
    if (serviceDate == null) {
      return null;
    }
    final hours = intValue ~/ 3600;
    final minutes = (intValue % 3600) ~/ 60;
    final seconds = intValue % 60;
    return DateTime(
      serviceDate.year,
      serviceDate.month,
      serviceDate.day,
      hours,
      minutes,
      seconds,
    );
  }

  DateTime? _parseServiceDay(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 8) {
      return null;
    }
    final year = int.tryParse(digitsOnly.substring(0, 4));
    final month = int.tryParse(digitsOnly.substring(4, 6));
    final day = int.tryParse(digitsOnly.substring(6, 8));
    if (year == null || month == null || day == null) {
      return null;
    }
    return DateTime(year, month, day);
  }

  String _delayText(num? delaySeconds) {
    if (delaySeconds == null) {
      return 'késés: n/a';
    }
    final minutes = (delaySeconds / 60).round();
    if (minutes > 0) {
      return 'késés: +${minutes}p';
    }
    if (minutes < 0) {
      return 'késés: ${minutes}p';
    }
    return 'késés: 0p';
  }

  String _plainText(String input) {
    return plainTextFromHtml(input);
  }
}
