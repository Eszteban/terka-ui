import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../services/graphql/graphql_client.dart';
import '../services/graphql/graphql_queries.dart';
import '../utils/markup_text_utils.dart';
import '../widgets/maps/plan_map_view.dart';
import '../widgets/maps/route_map_data.dart';
import '../theme/app_texts.dart';
import '../widgets/alerts_section.dart';
import 'trip_details_screen.dart';

class StopDetailsScreen extends StatefulWidget {
  static const double desktopBreakpoint = 700;

  final String stopId;
  final String? initialStopName;
  final LatLng? initialStopPoint;
  final List<String>? groupedStopIds;
  final TripDetailsBackgroundMapCallback? onShowTripOnBackgroundMap;
  final TripDetailsOpenRequestCallback? onOpenTripDetailsRequested;
  final bool closeAfterOpenTripRequest;

  const StopDetailsScreen({
    super.key,
    required this.stopId,
    this.initialStopName,
    this.initialStopPoint,
    this.groupedStopIds,
    this.onShowTripOnBackgroundMap,
    this.onOpenTripDetailsRequested,
    this.closeAfterOpenTripRequest = true,
  });

  @override
  State<StopDetailsScreen> createState() => _StopDetailsScreenState();
}

class _StopDetailsScreenState extends State<StopDetailsScreen> {
  static const String _spanFontFamily = 'MNR2007';
  static const double _spanFontScale = 28 / 16;
  static const int _serviceWindowOffsetHours = 3;
  static const int _serviceWindowRangeHours = 27;
  static const double _mobileSheetMinSize = 0.2;
  static const double _mobileSheetInitialSize = 0.3;
  static const double _mobileSheetMaxSize = 0.92;
  static const double _mobileStopFocusZoom = 16;

  bool _isLoading = true;
  bool _isUpdating = false;
  bool _isFetching = false;
  bool _showPastDepartures = false;
  int _mobileSelectedTabIndex = 1;
  DateTime _selectedDate = DateTime.now();
  String? _error;
  Map<String, dynamic>? _stop;
  final GraphqlClient _graphqlClient = const GraphqlClient();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadStopDetails();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => _loadStopDetails());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStopDetails({bool forceFullScreenLoading = false}) async {
    if (_isFetching) {
      return;
    }
    _isFetching = true;

    final isFirstLoad = _stop == null;

    if (isFirstLoad || forceFullScreenLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() {
        _isUpdating = true;
        _error = null;
      });
    }

    void handleError(String message) {
      if (isFirstLoad || forceFullScreenLoading) {
        setState(() {
          _error = message;
          _isLoading = false;
          _isUpdating = false;
        });
      } else {
        setState(() {
          _isUpdating = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppTexts.stopErrorUpdate(message))),
          );
        }
      }
      _isFetching = false;
    }

    final selectedDayStart = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final startEpoch = selectedDayStart.toUtc().millisecondsSinceEpoch ~/ 1000 -
        const Duration(hours: _serviceWindowOffsetHours).inSeconds;

    final groupedIds = (widget.groupedStopIds ?? const <String>[])
        .where((id) => id.trim().isNotEmpty)
        .map((id) => id.trim())
        .toSet()
        .toList();
    if (!groupedIds.contains(widget.stopId)) {
      groupedIds.insert(0, widget.stopId);
    }

    final expandedIds = _expandStopIdVariants(groupedIds);

    final query = buildStopDetailsQuery(expandedIds);
    final variables = {
        'startTime': startEpoch,
        'number': 2147483647,
        'timeRange': const Duration(hours: _serviceWindowRangeHours).inSeconds,
    };

    assert(() {
      debugPrint(
        '[StopDetails] load stop=${widget.stopId} date=${_formatSelectedDate(_selectedDate)} startEpoch=$startEpoch timeRange=${variables['timeRange']}',
      );
      return true;
    }());

    try {
      final response = await _graphqlClient.execute(
        query: query,
        variables: variables,
      );

      if (!response.isSuccess) {
        handleError('HTTP ${response.statusCode}');
        return;
      }

      final decoded = response.json;
      if (decoded == null) {
        handleError(AppTexts.stopInvalidResponse);
        return;
      }

      final data = decoded['data'];
      if (data is! Map) {
        handleError(AppTexts.stopDetailsNotAvailable);
        return;
      }

      final stops = <Map<String, dynamic>>[];
      for (var i = 0; i < expandedIds.length; i++) {
        final item = data['stop$i'];
        if (item is Map) {
          stops.add(item.cast<String, dynamic>());
        }
      }

      if (stops.isEmpty) {
        handleError(AppTexts.stopDetailsNotAvailable);
        return;
      }

      final preferredIds = _expandStopIdVariants([widget.stopId]).toSet();
      final primary = stops.firstWhere(
        (s) => preferredIds.contains(s['gtfsId']?.toString() ?? ''),
        orElse: () => _selectClosestStop(stops) ?? stops.first,
      );

      final selectedStop = Map<String, dynamic>.from(primary);
      selectedStop['stoptimesWithoutPatterns'] = _extractStopTimesFromStop(primary);

      setState(() {
        _stop = selectedStop;
        _isLoading = false;
        _isUpdating = false;
      });
      _isFetching = false;
    } catch (e) {
      handleError('$e');
    }
  }

  List<Map<String, dynamic>> _extractStopTimesFromStop(Map<String, dynamic> stop) {
    final flattened = <Map<String, dynamic>>[];

    // New query shape: stoptimesForPatterns { times: stoptimes { ... } }
    final byPattern = stop['stoptimesForPatterns'];
    if (byPattern is List) {
      for (final pattern in byPattern) {
        if (pattern is! Map) {
          continue;
        }
        final times = pattern['times'];
        if (times is! List) {
          continue;
        }
        for (final raw in times) {
          if (raw is Map) {
            flattened.add(raw.cast<String, dynamic>());
          }
        }
      }
    }

    if (flattened.isNotEmpty) {
      return flattened;
    }

    // Backward compatibility with older response shape.
    final legacy = stop['stoptimesWithoutPatterns'];
    if (legacy is! List) {
      return const [];
    }
    return legacy.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  Map<String, dynamic>? _selectClosestStop(List<Map<String, dynamic>> stops) {
    final target = widget.initialStopPoint;
    if (target == null) {
      return null;
    }

    Map<String, dynamic>? closest;
    var bestDistance = double.infinity;
    for (final stop in stops) {
      final stopPoint = _stopPoint(stop);
      if (stopPoint == null) {
        continue;
      }
      final distance = _distanceBetween(
        target.latitude,
        target.longitude,
        stopPoint.latitude,
        stopPoint.longitude,
      );
      if (distance < bestDistance) {
        bestDistance = distance;
        closest = stop;
      }
    }
    return closest;
  }

  LatLng? _stopPoint(Map<String, dynamic> stop) {
    final lat = _asNum(stop['lat']);
    final lon = _asNum(stop['lon']);
    if (lat == null || lon == null) {
      return null;
    }
    final latValue = lat.toDouble();
    final lonValue = lon.toDouble();
    if (latValue < -90 || latValue > 90 || lonValue < -180 || lonValue > 180) {
      return null;
    }
    return LatLng(latValue, lonValue);
  }

  double _distanceBetween(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a =
      (math.sin(dLat / 2) * math.sin(dLat / 2)) +
      math.cos(_degToRad(lat1)) * math.cos(_degToRad(lat2)) *
        (math.sin(dLon / 2) * math.sin(dLon / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _degToRad(double degrees) => degrees * (3.141592653589793 / 180);

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatSelectedDate(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }

    final normalized = DateTime(picked.year, picked.month, picked.day);
    if (_isSameDate(_selectedDate, normalized)) {
      return;
    }

    await _setSelectedDateAndReload(normalized);
  }

  Future<void> _setSelectedDateAndReload(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    if (_isSameDate(_selectedDate, normalized)) {
      return;
    }

    setState(() {
      _selectedDate = normalized;
      _showPastDepartures = false;
      _stop = null;
    });
    await _loadStopDetails(forceFullScreenLoading: true);
  }

  Future<void> _stepSelectedDate(int dayDelta) async {
    final base = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final stepped = base.add(Duration(days: dayDelta));
    await _setSelectedDateAndReload(stepped);
  }

  bool _isOnSelectedDate(Map<String, dynamic> departure) {
    final occurrence = _resolveDepartureInstant(
      serviceDay: _asNum(departure['serviceDay']),
      secondsOfDay: _eventSecondsOfDay(departure),
    );
    if (occurrence == null) {
      return false;
    }
    return _isSameDate(occurrence, _selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final rawStopName = _stop?['name']?.toString().trim().isNotEmpty == true
        ? _stop!['name'].toString()
        : (widget.initialStopName?.trim().isNotEmpty == true
              ? widget.initialStopName!.trim()
              : AppTexts.stopDetailsLabel);
    final stopName = _plainText(rawStopName);
    final stopNameUsesSpanFont = _containsSpanMarkup(rawStopName);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          stopName,
          style: TextStyle(
            fontFamily: stopNameUsesSpanFont ? _spanFontFamily : null,
            fontSize: stopNameUsesSpanFont ? 20 * _spanFontScale : null,
            leadingDistribution:
                stopNameUsesSpanFont ? TextLeadingDistribution.even : null,
            height: stopNameUsesSpanFont ? 1.0 : null,
          ),
        ),
        actions: [
          if (_isUpdating)
            const SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadStopDetails,
            ),
        ],
      ),
      body: _buildBody(),
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
                onPressed: _loadStopDetails,
                child: Text(AppTexts.retry),
              ),
            ],
          ),
        ),
      );
    }

    final stop = _stop;
    if (stop == null) {
      return Center(child: Text(AppTexts.stopNoData));
    }

    final now = DateTime.now();
    final isTodayView = _isSameDate(_selectedDate, now);
    final departures = _departures(stop).where(_isOnSelectedDate).toList();
    assert(() {
      debugPrint(
        '[StopDetails] filter date=${_formatSelectedDate(_selectedDate)} all=${_departures(stop).length} sameDay=${departures.length}',
      );
      return true;
    }());
    final hasPast = isTodayView && departures.any((d) => _isPastDeparture(d, now));
    final arrivals = departures.where(_isArrivalEntry).toList();
    final departuresOnly = departures.where(_isDepartureEntry).toList();
    final hidePastInToday = isTodayView && !_showPastDepartures;
    final visibleArrivals = hidePastInToday
        ? arrivals.where((d) => !_isPastDeparture(d, now)).toList()
        : arrivals;
    final visibleDepartures = hidePastInToday
        ? departuresOnly.where((d) => !_isPastDeparture(d, now)).toList()
        : departuresOnly;

    if (_useMobileMapSheet) {
      return _buildMobileMapWithDetailsSheet(
        stop: stop,
        now: now,
        hasPast: hasPast,
        visibleArrivals: visibleArrivals,
        visibleDepartures: visibleDepartures,
      );
    }

    return _buildStopDetailsTabs(
      now: now,
      hasPast: hasPast,
      visibleArrivals: visibleArrivals,
      visibleDepartures: visibleDepartures,
    );
  }

  Widget _buildStopDetailsTabs({
    required DateTime now,
    required bool hasPast,
    required List<Map<String, dynamic>> visibleArrivals,
    required List<Map<String, dynamic>> visibleDepartures,
  }) {

    return DefaultTabController(
      length: 2,
      initialIndex: 1,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _stepSelectedDate(-1),
                  tooltip: AppTexts.stopPrevDay,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(AppTexts.stopDateLabel(_formatSelectedDate(_selectedDate))),
                  ),
                ),
                IconButton(
                  onPressed: () => _stepSelectedDate(1),
                  tooltip: AppTexts.stopNextDay,
                  icon: const Icon(Icons.chevron_right),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _isSameDate(_selectedDate, DateTime.now())
                      ? null
                      : () {
                          final nowDate = DateTime.now();
                          _setSelectedDateAndReload(
                            DateTime(nowDate.year, nowDate.month, nowDate.day),
                          );
                        },
                  child: Text(AppTexts.stopToday),
                ),
              ],
            ),
          ),
          if (hasPast)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showPastDepartures = !_showPastDepartures;
                    });
                  },
                  child: Text(
                    _showPastDepartures
                        ? AppTexts.stopHidePast
                        : AppTexts.stopShowPast,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AlertsSection(alerts: _stop?['alerts']),
          ),
          TabBar(
            tabs: [
              Tab(text: AppTexts.stopArrivals),
              Tab(text: AppTexts.stopDepartures),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildStopTimesList(
                  items: visibleArrivals,
                  now: now,
                  emptyMessage: AppTexts.stopNoArrivals,
                ),
                _buildStopTimesList(
                  items: visibleDepartures,
                  now: now,
                  emptyMessage: AppTexts.stopNoDepartures,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _useMobileMapSheet {
    return MediaQuery.of(context).size.width <= StopDetailsScreen.desktopBreakpoint;
  }

  RouteMapData _buildStopMapRouteData(Map<String, dynamic> stop) {
    final point = _stopPoint(stop) ?? widget.initialStopPoint;
    if (point == null) {
      return const RouteMapData(segments: [], stops: []);
    }

    final rawStopName = stop['name']?.toString() ?? widget.initialStopName ?? AppTexts.stops;
    final bearing = stop['bearing'] is num ? (stop['bearing'] as num).toDouble() : null;
    return RouteMapData(
      segments: const [],
      stops: [
        RouteStopMarker(
          point: point,
          label: _plainText(rawStopName),
          type: RouteStopType.start,
          bearing: bearing,
        ),
      ],
    );
  }

  Widget _buildMobileMapWithDetailsSheet({
    required Map<String, dynamic> stop,
    required DateTime now,
    required bool hasPast,
    required List<Map<String, dynamic>> visibleArrivals,
    required List<Map<String, dynamic>> visibleDepartures,
  }) {
    final routeData = _buildStopMapRouteData(stop);
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
            initialZoom: _mobileStopFocusZoom,
            singlePointZoom: _mobileStopFocusZoom,
            showStopLabels: false,
            useBaseMapStopIcon: true,
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: _mobileSheetInitialSize,
          minChildSize: _mobileSheetMinSize,
          maxChildSize: _mobileSheetMaxSize,
          snap: true,
          snapSizes: const [
            _mobileSheetInitialSize,
            0.6,
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
              child: _buildStopDetailsSheetList(
                sheetScrollController: scrollController,
                now: now,
                hasPast: hasPast,
                visibleArrivals: visibleArrivals,
                visibleDepartures: visibleDepartures,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStopTimesList({
    required List<Map<String, dynamic>> items,
    required DateTime now,
    required String emptyMessage,
  }) {
    if (items.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final departure = items[index];
        return _buildDepartureCard(departure, now);
      },
    );
  }

  Widget _buildStopDetailsSheetList({
    required ScrollController sheetScrollController,
    required DateTime now,
    required bool hasPast,
    required List<Map<String, dynamic>> visibleArrivals,
    required List<Map<String, dynamic>> visibleDepartures,
  }) {
    final showingArrivals = _mobileSelectedTabIndex == 0;
    final selectedItems = showingArrivals ? visibleArrivals : visibleDepartures;
    final emptyMessage = showingArrivals
        ? AppTexts.stopNoArrivals
        : AppTexts.stopNoDepartures;

    return ListView(
      controller: sheetScrollController,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        Center(
          child: Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppTexts.stopSwipeInstruction,
          style: Theme.of(context).textTheme.labelLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: () => _stepSelectedDate(-1),
              tooltip: AppTexts.stopPrevDay,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(AppTexts.stopDateLabel(_formatSelectedDate(_selectedDate))),
              ),
            ),
            IconButton(
              onPressed: () => _stepSelectedDate(1),
              tooltip: AppTexts.stopNextDay,
              icon: const Icon(Icons.chevron_right),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _isSameDate(_selectedDate, DateTime.now())
                  ? null
                  : () {
                      final nowDate = DateTime.now();
                      _setSelectedDateAndReload(
                        DateTime(nowDate.year, nowDate.month, nowDate.day),
                      );
                    },
              child: Text(AppTexts.stopToday),
            ),
          ],
        ),
        if (hasPast)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _showPastDepartures = !_showPastDepartures;
                });
              },
              child: Text(
                _showPastDepartures
                    ? AppTexts.stopHidePast
                    : AppTexts.stopShowPast,
              ),
            ),
          ),
        const SizedBox(height: 8),
        AlertsSection(alerts: _stop?['alerts']),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(AppTexts.stopArrivals),
              selected: showingArrivals,
              onSelected: (_) {
                setState(() {
                  _mobileSelectedTabIndex = 0;
                });
              },
            ),
            ChoiceChip(
              label: Text(AppTexts.stopDepartures),
              selected: !showingArrivals,
              onSelected: (_) {
                setState(() {
                  _mobileSelectedTabIndex = 1;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._buildSheetStopTimeItems(
          items: selectedItems,
          now: now,
          emptyMessage: emptyMessage,
        ),
      ],
    );
  }

  List<Widget> _buildSheetStopTimeItems({
    required List<Map<String, dynamic>> items,
    required DateTime now,
    required String emptyMessage,
  }) {
    if (items.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text(emptyMessage)),
        ),
      ];
    }

    final widgets = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      widgets.add(_buildDepartureCard(items[i], now));
      if (i < items.length - 1) {
        widgets.add(const SizedBox(height: 8));
      }
    }
    return widgets;
  }

  Widget _buildDepartureCard(Map<String, dynamic> departure, DateTime now) {
    final trip = departure['trip'];
    final route = trip is Map ? trip['route'] : null;

    final rawRouteShortName =
        route is Map ? (route['shortName']?.toString() ?? '-') : '-';
    final routeShortName = _plainText(
      rawRouteShortName,
    );
    final routeShortNameUsesSpanFont = _containsSpanMarkup(rawRouteShortName);
    final rawHeadsign = trip is Map
        ? (trip['tripHeadsign']?.toString() ??
            departure['headsign']?.toString() ??
            '-')
        : (departure['headsign']?.toString() ?? '-');
    final headsign = _plainText(
      rawHeadsign,
    );
    final headsignUsesSpanFont = _containsSpanMarkup(rawHeadsign);

    final scheduledArrival = _resolveDepartureTime(
      serviceDay: _asNum(departure['serviceDay']),
      secondsOfDay: _asNum(departure['scheduledArrival']),
    );
    final realtimeArrival = _resolveDepartureTime(
      serviceDay: _asNum(departure['serviceDay']),
      secondsOfDay: _asNum(departure['realtimeArrival']),
    );
    final scheduledDeparture = _resolveDepartureTime(
      serviceDay: _asNum(departure['serviceDay']),
      secondsOfDay: _asNum(departure['scheduledDeparture']),
    );
    final realtimeDeparture = _resolveDepartureTime(
      serviceDay: _asNum(departure['serviceDay']),
      secondsOfDay: _asNum(departure['realtimeDeparture']),
    );

    final isArrivalByType = _isArrivalEntry(departure);
    final isDepartureByType = _isDepartureEntry(departure);
    final eventLabel = isArrivalByType && isDepartureByType
        ? AppTexts.stopArrivalsAndDepartures
        : isArrivalByType
            ? AppTexts.stopArrivals
            : isDepartureByType
                ? AppTexts.stopDepartures
                : AppTexts.stopTimeLabel;

    final hasDeparture =
        _asNum(departure['scheduledDeparture']) != null ||
        _asNum(departure['realtimeDeparture']) != null;

    final scheduled = hasDeparture ? scheduledDeparture : scheduledArrival;
    final realtime = hasDeparture ? realtimeDeparture : realtimeArrival;

    final isPast = _isPastDeparture(departure, now);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final delay = hasDeparture
        ? _asNum(departure['departureDelay'])
        : _asNum(departure['arrivalDelay']);
    final isRealtime = departure['realtime'] == true;
    final isOnTime = (delay ?? 0) == 0;
    final realtimeColor = isPast
        ? Colors.grey
        : !isRealtime
            ? (isDark ? Colors.white : Colors.black)
            : isOnTime
                ? Colors.green
                : (delay ?? 0) < 0
                    ? Colors.blue
                    : Colors.red;

    final scheduledArrivalSecs = _asNum(departure['scheduledArrival']);
    final scheduledDepartureSecs = _asNum(departure['scheduledDeparture']);
    final hasBothScheduledTimes = scheduledArrivalSecs != null && scheduledDepartureSecs != null;
    final scheduledTimesDiffer = hasBothScheduledTimes && scheduledArrivalSecs != scheduledDepartureSecs;

    final arrDelay = _asNum(departure['arrivalDelay']);
    final isArrivalOnTime = (arrDelay ?? 0) == 0;
    final realtimeArrivalColor = isPast
        ? Colors.grey
        : !isRealtime
            ? (isDark ? Colors.white : Colors.black)
            : isArrivalOnTime
                ? Colors.green
                : (arrDelay ?? 0) < 0
                    ? Colors.blue
                    : Colors.red;

    final depDelay = _asNum(departure['departureDelay']);
    final isDepartureOnTime = (depDelay ?? 0) == 0;
    final realtimeDepartureColor = isPast
        ? Colors.grey
        : !isRealtime
            ? (isDark ? Colors.white : Colors.black)
            : isDepartureOnTime
                ? Colors.green
                : (depDelay ?? 0) < 0
                    ? Colors.blue
                    : Colors.red;

    final tripId = trip is Map ? trip['gtfsId']?.toString() ?? '' : '';
    final serviceDay = _serviceDayToYmd(_asNum(departure['serviceDay']));
    final canOpenTrip = tripId.trim().isNotEmpty && serviceDay.isNotEmpty;
    final platformCode = departure['stop'] is Map
        ? (departure['stop']['platformCode']?.toString().trim() ?? '')
        : '';
    final hasPlatformCode = platformCode.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.08)) : null,
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: canOpenTrip
              ? () => _openTripDetails(
                  tripId: tripId,
                  serviceDay: serviceDay,
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Container(
                padding: routeShortNameUsesSpanFont
                    ? const EdgeInsets.symmetric(horizontal: 0, vertical: 0)
                    : const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _hexColor(
                    route is Map ? route['color']?.toString() ?? '0A84FF' : '0A84FF',
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  routeShortName,
                  style: TextStyle(
                    color: _hexColor(
                      route is Map
                          ? route['textColor']?.toString() ?? 'FFFFFF'
                          : 'FFFFFF',
                    ),
                    fontSize: routeShortNameUsesSpanFont
                        ? 12 * _spanFontScale
                        : null,
                    fontWeight: FontWeight.w700,
                    fontFamily:
                        routeShortNameUsesSpanFont ? _spanFontFamily : null,
                    leadingDistribution: routeShortNameUsesSpanFont
                        ? TextLeadingDistribution.even
                        : null,
                    height: routeShortNameUsesSpanFont ? 1.0 : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headsign,
                      softWrap: true,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: headsignUsesSpanFont
                            ? 14 * _spanFontScale
                            : null,
                        fontFamily:
                            headsignUsesSpanFont ? _spanFontFamily : null,
                        leadingDistribution: headsignUsesSpanFont
                            ? TextLeadingDistribution.even
                            : null,
                        height: headsignUsesSpanFont ? 1.0 : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      eventLabel,
                      style: TextStyle(
                        color: isPast ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (hasPlatformCode)
                      Text(
                        AppTexts.stopPlatform(platformCode),
                        style: TextStyle(
                          color: isPast ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (scheduledTimesDiffer) ...[
                      Row(
                        children: [
                          Text(
                            '${AppTexts.tripArrivalColumn} ',
                            style: TextStyle(
                              color: isPast ? Colors.grey : (isDark ? Colors.white70 : Colors.black54),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _formatTime(scheduledArrival),
                            style: TextStyle(
                              color: isPast ? Colors.grey : (isDark ? Colors.white : Colors.black),
                              decoration: (scheduledArrival != null && realtimeArrival != null &&
                                      scheduledArrival != realtimeArrival)
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(realtimeArrival),
                            style: TextStyle(
                              color: realtimeArrivalColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${AppTexts.tripDepartureColumn} ',
                            style: TextStyle(
                              color: isPast ? Colors.grey : (isDark ? Colors.white70 : Colors.black54),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _formatTime(scheduledDeparture),
                            style: TextStyle(
                              color: isPast ? Colors.grey : (isDark ? Colors.white : Colors.black),
                              decoration: (scheduledDeparture != null && realtimeDeparture != null &&
                                      scheduledDeparture != realtimeDeparture)
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(realtimeDeparture),
                            style: TextStyle(
                              color: realtimeDepartureColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Text(
                            _formatTime(scheduled),
                            style: TextStyle(
                              color: isPast ? Colors.grey : (isDark ? Colors.white : Colors.black),
                              decoration: (scheduled != null && realtime != null &&
                                      scheduled != realtime)
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(realtime),
                            style: TextStyle(
                              color: realtimeColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (canOpenTrip)
                const Padding(
                  padding: EdgeInsets.only(left: 6, top: 2),
                  child: Icon(Icons.chevron_right, size: 20),
                ),
            ],
          ),
        ),
      ),
    )
    );
  }

  Future<void> _openTripDetails({
    required String tripId,
    required String serviceDay,
  }) async {
    final isDesktop =
        MediaQuery.of(context).size.width > StopDetailsScreen.desktopBreakpoint;

    if (isDesktop && widget.onOpenTripDetailsRequested != null) {
      widget.onOpenTripDetailsRequested!(tripId, serviceDay);
      if (widget.closeAfterOpenTripRequest && mounted) {
        Navigator.of(context).maybePop();
      }
      return;
    }

    final useDesktopDialog =
        widget.onShowTripOnBackgroundMap != null && isDesktop;

    if (useDesktopDialog) {
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
              onOpenTripDetailsRequested: widget.onOpenTripDetailsRequested,
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
          onOpenTripDetailsRequested: widget.onOpenTripDetailsRequested,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _departures(Map<String, dynamic> stop) {
    final list = stop['stoptimesWithoutPatterns'];
    if (list is! List) {
      return const [];
    }
    final mapped = list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    mapped.sort((a, b) {
      final aTime = _resolveDepartureInstant(
            serviceDay: _asNum(a['serviceDay']),
            secondsOfDay: _eventSecondsOfDay(a),
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = _resolveDepartureInstant(
            serviceDay: _asNum(b['serviceDay']),
            secondsOfDay: _eventSecondsOfDay(b),
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return aTime.compareTo(bTime);
    });
    return mapped;
  }

  bool _isArrivalEntry(Map<String, dynamic> stopTime) {
    return _isScheduledStopAction(stopTime['dropoffType']);
  }

  bool _isDepartureEntry(Map<String, dynamic> stopTime) {
    return _isScheduledStopAction(stopTime['pickupType']);
  }

  bool _isScheduledStopAction(dynamic value) {
    return value?.toString().toUpperCase() == 'SCHEDULED';
  }

  bool _isPastDeparture(Map<String, dynamic> departure, DateTime now) {
    final departureInstant = _resolveDepartureInstant(
      serviceDay: _asNum(departure['serviceDay']),
      secondsOfDay: _eventSecondsOfDay(departure),
    );
    if (departureInstant == null) {
      return false;
    }
    return departureInstant.isBefore(now);
  }

  num? _eventSecondsOfDay(Map<String, dynamic> departure) {
    return _asNum(departure['realtimeDeparture']) ??
        _asNum(departure['scheduledDeparture']) ??
        _asNum(departure['realtimeArrival']) ??
        _asNum(departure['scheduledArrival']);
  }

  DateTime? _resolveDepartureInstant({
    required num? serviceDay,
    required num? secondsOfDay,
  }) {
    if (serviceDay == null || secondsOfDay == null) {
      return null;
    }

    final dayMillis = serviceDay.toInt() * 1000;
    return DateTime.fromMillisecondsSinceEpoch(dayMillis, isUtc: true)
        .add(Duration(seconds: secondsOfDay.toInt()))
        .toLocal();
  }

  DateTime? _resolveDepartureTime({
    required num? serviceDay,
    required num? secondsOfDay,
  }) {
    if (serviceDay == null || secondsOfDay == null) {
      return null;
    }
    final serviceDayMidnight = _serviceDayLocalMidnight(serviceDay);
    if (serviceDayMidnight == null) {
      return null;
    }
    final totalSeconds = secondsOfDay.toInt();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return DateTime(
      serviceDayMidnight.year,
      serviceDayMidnight.month,
      serviceDayMidnight.day,
      hours,
      minutes,
      seconds,
    );
  }

  String _serviceDayToYmd(num? serviceDay) {
    final dt = _serviceDayLocalMidnight(serviceDay);
    if (dt == null) {
      return '';
    }
    final yyyy = dt.year.toString().padLeft(4, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    return '$yyyy$mm$dd';
  }

  DateTime? _serviceDayLocalMidnight(num? serviceDay) {
    if (serviceDay == null) {
      return null;
    }
    final raw = DateTime.fromMillisecondsSinceEpoch(serviceDay.toInt() * 1000);

    // Some backend timestamps around DST can land on 01:00 local time.
    // Rebuild as local midnight so seconds-of-day math stays stable.
    return DateTime(raw.year, raw.month, raw.day);
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) {
      return '-';
    }
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  num? _asNum(dynamic value) => value is num ? value : null;

  List<String> _expandStopIdVariants(List<String> ids) {
    final ordered = <String>[];
    final seen = <String>{};

    void add(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) {
        return;
      }
      seen.add(trimmed);
      ordered.add(trimmed);
    }

    for (final raw in ids) {
      final id = raw.trim();
      add(id);

      if (id.startsWith('SOM:hkir|')) {
        final suffix = id.substring('SOM:hkir|'.length);
        add('hkir:$suffix');
        add(suffix);
      }

      if (id.startsWith('hkir:')) {
        final suffix = id.substring('hkir:'.length);
        add('SOM:hkir|$suffix');
        add(suffix);
      }

      if (id.startsWith('hkir_')) {
        add('hkir:$id');
        add('SOM:hkir|$id');
      }

      if (id.contains('|')) {
        final suffix = id.split('|').last;
        add(suffix);
        if (suffix.startsWith('hkir_')) {
          add('hkir:$suffix');
          add('SOM:hkir|$suffix');
        }
      }
    }

    return ordered;
  }

  bool _containsSpanMarkup(String value) {
    return containsSpanMarkup(value);
  }

  String _plainText(String input) {
    return plainTextFromHtml(input);
  }

  Color _hexColor(String rawHex) {
    final hex = rawHex.replaceAll('#', '').trim();
    final parsed = int.tryParse(hex.length == 6 ? hex : '0A84FF', radix: 16);
    return parsed == null ? const Color(0xFF0A84FF) : Color(0xFF000000 | parsed);
  }
}
