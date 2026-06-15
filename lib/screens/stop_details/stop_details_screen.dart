import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../services/transit_api_service.dart';
import '../../utils/stop_details_utils.dart';
import '../../theme/app_texts.dart';
import '../trip_details/trip_details_screen.dart';

import 'widgets/stop_details_mobile_sheet.dart';
import 'widgets/stop_details_tabs.dart';

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

  bool _isLoading = true;
  bool _isUpdating = false;
  bool _isFetching = false;
  bool _showPastDepartures = false;
  DateTime _selectedDate = DateTime.now();
  String? _error;
  Map<String, dynamic>? _stop;
  final TransitApiService _transitApiService = const TransitApiService();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadStopDetails();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _loadStopDetails(),
    );
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

    final groupedIds = (widget.groupedStopIds ?? const <String>[])
        .where((id) => id.trim().isNotEmpty)
        .map((id) => id.trim())
        .toSet()
        .toList();
    if (!groupedIds.contains(widget.stopId)) {
      groupedIds.insert(0, widget.stopId);
    }

    try {
      final stops = await _transitApiService.fetchStopDetails(
        stopIds: groupedIds,
        selectedDate: _selectedDate,
      );

      if (stops == null || stops.isEmpty) {
        handleError(AppTexts.stopDetailsNotAvailable);
        return;
      }

      final preferredIds =
          StopDetailsUtils.expandStopIdVariants([widget.stopId]).toSet();
      final primary = stops.firstWhere(
        (s) => preferredIds.contains(s['gtfsId']?.toString() ?? ''),
        orElse: () =>
            StopDetailsUtils.selectClosestStop(stops, widget.initialStopPoint) ??
            stops.first,
      );

      final selectedStop = Map<String, dynamic>.from(primary);
      selectedStop['stoptimesWithoutPatterns'] =
          _extractStopTimesFromStop(primary);

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

  List<Map<String, dynamic>> _extractStopTimesFromStop(
    Map<String, dynamic> stop,
  ) {
    final flattened = <Map<String, dynamic>>[];

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

    final legacy = stop['stoptimesWithoutPatterns'];
    if (legacy is! List) {
      return const [];
    }
    return legacy
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
  }

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

    await _updateSelectedDate(normalized);
  }

  Future<void> _updateSelectedDate(DateTime date) async {
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
    final base =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final stepped = base.add(Duration(days: dayDelta));
    await _updateSelectedDate(stepped);
  }

  bool _isOnSelectedDate(Map<String, dynamic> departure) {
    final occurrence = StopDetailsUtils.resolveDepartureInstant(
      serviceDay: StopDetailsUtils.asNum(departure['serviceDay']),
      secondsOfDay: StopDetailsUtils.eventSecondsOfDay(departure),
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
    final stopName = StopDetailsUtils.plainText(rawStopName);
    final stopNameUsesSpanFont =
        StopDetailsUtils.containsSpanMarkup(rawStopName);

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
    final departures =
        StopDetailsUtils.departures(stop).where(_isOnSelectedDate).toList();
    assert(() {
      debugPrint(
        '[StopDetails] filter date=${_formatSelectedDate(_selectedDate)} all=${StopDetailsUtils.departures(stop).length} sameDay=${departures.length}',
      );
      return true;
    }());
    final hasPast = isTodayView &&
        departures.any((d) => StopDetailsUtils.isPastDeparture(d, now));
    final arrivals = departures.where(StopDetailsUtils.isArrivalEntry).toList();
    final departuresOnly =
        departures.where(StopDetailsUtils.isDepartureEntry).toList();
    final hidePastInToday = isTodayView && !_showPastDepartures;
    final visibleArrivals = hidePastInToday
        ? arrivals
            .where((d) => !StopDetailsUtils.isPastDeparture(d, now))
            .toList()
        : arrivals;
    final visibleDepartures = hidePastInToday
        ? departuresOnly
            .where((d) => !StopDetailsUtils.isPastDeparture(d, now))
            .toList()
        : departuresOnly;

    if (_useMobileMapSheet) {
      return StopDetailsMobileSheet(
        stop: stop,
        initialStopPoint: widget.initialStopPoint,
        initialStopName: widget.initialStopName,
        now: now,
        hasPast: hasPast,
        visibleArrivals: visibleArrivals,
        visibleDepartures: visibleDepartures,
        selectedDate: _selectedDate,
        showPastDepartures: _showPastDepartures,
        onPickDate: _pickDate,
        onTogglePastDepartures: () {
          setState(() {
            _showPastDepartures = !_showPastDepartures;
          });
        },
        onStepSelectedDate: _stepSelectedDate,
        onGoToToday: () {
          final nowDate = DateTime.now();
          _updateSelectedDate(
            DateTime(nowDate.year, nowDate.month, nowDate.day),
          );
        },
        onOpenTripDetails: ({required tripId, required serviceDay}) {
          _openTripDetails(tripId: tripId, serviceDay: serviceDay);
        },
      );
    }

    return StopDetailsTabs(
      now: now,
      hasPast: hasPast,
      visibleArrivals: visibleArrivals,
      visibleDepartures: visibleDepartures,
      selectedDate: _selectedDate,
      showPastDepartures: _showPastDepartures,
      stop: stop,
      onPickDate: _pickDate,
      onTogglePastDepartures: () {
        setState(() {
          _showPastDepartures = !_showPastDepartures;
        });
      },
      onStepSelectedDate: _stepSelectedDate,
      onGoToToday: () {
        final nowDate = DateTime.now();
        _updateSelectedDate(
          DateTime(nowDate.year, nowDate.month, nowDate.day),
        );
      },
      onOpenTripDetails: ({required tripId, required serviceDay}) {
        _openTripDetails(tripId: tripId, serviceDay: serviceDay);
      },
    );
  }

  bool get _useMobileMapSheet {
    return MediaQuery.of(context).size.width <=
        StopDetailsScreen.desktopBreakpoint;
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
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
}
