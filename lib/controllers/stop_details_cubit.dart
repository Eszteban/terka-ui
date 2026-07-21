import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../../repositories/transit_repository.dart';
import '../utils/stop_details_utils.dart';
import 'map_cubit.dart';

abstract class StopDetailsState {}

class StopDetailsLoading extends StopDetailsState {}

class StopDetailsLoaded extends StopDetailsState {
  final Map<String, dynamic> stop;
  final List<Map<String, dynamic>> uniqueLines;
  final bool isRefreshing;
  final String? refreshError;
  final DateTime selectedDate;
  final bool showPastDepartures;
  final Set<String> selectedLines;

  StopDetailsLoaded({
    required this.stop,
    required this.uniqueLines,
    required this.selectedDate,
    required this.showPastDepartures,
    required this.selectedLines,
    this.isRefreshing = false,
    this.refreshError,
  });

  StopDetailsLoaded copyWith({
    Map<String, dynamic>? stop,
    List<Map<String, dynamic>>? uniqueLines,
    DateTime? selectedDate,
    bool? showPastDepartures,
    Set<String>? selectedLines,
    bool? isRefreshing,
    String? refreshError,
    bool clearRefreshError = false,
  }) {
    return StopDetailsLoaded(
      stop: stop ?? this.stop,
      uniqueLines: uniqueLines ?? this.uniqueLines,
      selectedDate: selectedDate ?? this.selectedDate,
      showPastDepartures: showPastDepartures ?? this.showPastDepartures,
      selectedLines: selectedLines ?? this.selectedLines,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshError: clearRefreshError ? null : (refreshError ?? this.refreshError),
    );
  }
}

class StopDetailsError extends StopDetailsState {
  final String message;
  StopDetailsError(this.message);
}

class StopDetailsCubit extends Cubit<StopDetailsState> {
  final TransitRepository _transitRepository;
  final MapCubit? _mapCubit;
  
  final String stopId;
  final List<String> groupedStopIds;
  final DateTime selectedDate;
  final bool showPastDepartures;
  final Set<String> selectedLines;
  
  Timer? _refreshTimer;
  bool _isFetching = false;

  StopDetailsCubit({
    required TransitRepository transitRepository,
    MapCubit? mapCubit,
    required this.stopId,
    LatLng? initialStopPoint,
    String? initialStopName,
    List<String>? groupedStopIds,
    DateTime? date,
    bool? past,
    Set<String>? lines,
  })  : _transitRepository = transitRepository,
        _mapCubit = mapCubit,
        groupedStopIds = groupedStopIds ?? [stopId],
        selectedDate = date ?? StopDetailsUtils.budapestToday(),
        showPastDepartures = past ?? false,
        selectedLines = lines ?? <String>{},
        super(StopDetailsLoading()) {
    _mapCubit?.clearDesktopRouteSelection();
    if (initialStopPoint != null) {
      _mapCubit?.setStopHighlight(initialStopPoint, initialStopName ?? stopId);
    }
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => _loadData());
  }

  Future<void> close() {
    _refreshTimer?.cancel();
    _mapCubit?.clearStopHighlight();
    return super.close();
  }

  void forceRefreshMap() {
    _mapCubit?.clearDesktopRouteSelection();
    if (state is StopDetailsLoaded) {
      final stop = (state as StopDetailsLoaded).stop;
      final lat = StopDetailsUtils.asNum(stop['lat'])?.toDouble();
      final lon = StopDetailsUtils.asNum(stop['lon'])?.toDouble();
      if (lat != null && lon != null) {
        _mapCubit?.setStopHighlight(LatLng(lat, lon), stop['name']?.toString() ?? stopId);
      }
    } else {
      _loadData();
    }
  }

  void clearMapHighlight() {
    _mapCubit?.clearStopHighlight();
  }

  List<Map<String, dynamic>> _getUniqueLines(Map<String, dynamic> stop) {
    final routes = stop['routes'];
    if (routes is! List) return const [];

    final seenNames = <String>{};
    final unique = <Map<String, dynamic>>[];
    for (final r in routes) {
      if (r is Map) {
        var rawLabel = r['shortName']?.toString() ?? '';
        if (rawLabel.trim().isEmpty) {
          rawLabel = r['longName']?.toString() ?? '';
        }
        if (rawLabel.trim().isEmpty) {
          rawLabel = '-';
        }
        final label = StopDetailsUtils.plainText(rawLabel);
        final useSpanFont = StopDetailsUtils.containsSpanMarkup(rawLabel);
        if (seenNames.add(label)) {
          unique.add({
            'shortName': label,
            'color': r['color']?.toString() ?? '0A84FF',
            'textColor': r['textColor']?.toString() ?? 'FFFFFF',
            'useSpanFont': useSpanFont,
          });
        }
      }
    }
    unique.sort((a, b) => a['shortName'].toString().compareTo(b['shortName'].toString()));
    return unique;
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

  Future<void> _loadData() async {
    if (_isFetching) return;
    _isFetching = true;

    if (state is StopDetailsLoaded) {
      emit((state as StopDetailsLoaded).copyWith(isRefreshing: true, clearRefreshError: true));
    }

    try {
      final stopsData = await _transitRepository.fetchStopDetails(
        stopIds: groupedStopIds,
        selectedDate: selectedDate,
      );

      if (stopsData == null || stopsData.isEmpty) {
        if (state is StopDetailsLoaded) {
          emit((state as StopDetailsLoaded).copyWith(
            isRefreshing: false,
            refreshError: 'Nincs adat.',
          ));
        } else {
          emit(StopDetailsError('Nincs adat.'));
        }
        _isFetching = false;
        return;
      }

      final preferredIds =
          StopDetailsUtils.expandStopIdVariants([stopId]).toSet();
      final primary = stopsData.firstWhere(
        (s) => preferredIds.contains(s['gtfsId']?.toString() ?? ''),
        orElse: () => stopsData.first,
      );

      final stop = Map<String, dynamic>.from(primary);
      stop['stoptimesWithoutPatterns'] = _extractStopTimesFromStop(primary);

      final uniqueLines = _getUniqueLines(stop);

      final lat = StopDetailsUtils.asNum(stop['lat'])?.toDouble();
      final lon = StopDetailsUtils.asNum(stop['lon'])?.toDouble();
      if (lat != null && lon != null) {
        _mapCubit?.setStopHighlight(LatLng(lat, lon), stop['name']?.toString() ?? stopId);
      }

      emit(StopDetailsLoaded(
        stop: stop,
        uniqueLines: uniqueLines,
        selectedDate: selectedDate,
        showPastDepartures: showPastDepartures,
        selectedLines: selectedLines,
      ));

    } catch (e) {
      if (state is StopDetailsLoaded) {
        emit((state as StopDetailsLoaded).copyWith(
          isRefreshing: false,
          refreshError: e.toString(),
        ));
      } else {
        emit(StopDetailsError(e.toString()));
      }
    } finally {
      _isFetching = false;
    }
  }
}
