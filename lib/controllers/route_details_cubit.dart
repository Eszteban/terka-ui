import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../../repositories/transit_repository.dart';
import 'map_cubit.dart';
import '../utils/trip_details_utils.dart';
import '../widgets/maps/route_map_data.dart';

abstract class RouteDetailsState {}

class RouteDetailsLoading extends RouteDetailsState {}

class RouteDetailsLoaded extends RouteDetailsState {
  final Map<String, dynamic> routeData;

  RouteDetailsLoaded({required this.routeData});
}

class RouteDetailsError extends RouteDetailsState {
  final String message;
  RouteDetailsError(this.message);
}

class RouteDetailsCubit extends Cubit<RouteDetailsState> {
  final TransitRepository _transitRepository;
  final MapCubit _mapCubit;
  
  final String routeId;

  RouteDetailsCubit({
    required TransitRepository transitRepository,
    required MapCubit mapCubit,
    required this.routeId,
  })  : _transitRepository = transitRepository,
        _mapCubit = mapCubit,
        super(RouteDetailsLoading()) {
    _loadData();
  }

  void forceRefreshMap() {
    if (state is RouteDetailsLoaded) {
      final route = (state as RouteDetailsLoaded).routeData;
      _updateMapData(route);
    } else {
      _loadData();
    }
  }

  @override
  Future<void> close() {
    _mapCubit.clearDesktopRouteSelection();
    return super.close();
  }

  Future<void> _loadData() async {
    try {
      final route = await _transitRepository.fetchRouteDetails(routeId: routeId);

      if (route == null) {
        emit(RouteDetailsError('Nincs adat.'));
        return;
      }

      emit(RouteDetailsLoaded(routeData: route));
      _updateMapData(route);
    } catch (e) {
      emit(RouteDetailsError(e.toString()));
    }
  }

  void _updateMapData(Map<String, dynamic> route) {
    final patterns = route['patterns'];
    if (patterns is List && patterns.isNotEmpty) {
      final segments = <RouteSegment>[];
      final stops = <RouteStopMarker>[];
      final addedStopIds = <String>{};

      for (final pattern in patterns) {
        if (pattern is Map) {
          final shape = pattern['patternGeometry'];
          if (shape is Map && shape['points'] is String) {
            final points = TripDetailsUtils.decodePolyline(shape['points']);
            if (points.isNotEmpty) {
              final rColor = TripDetailsUtils.hexColor(route['color']?.toString() ?? '0A84FF');
              final rTextColor = TripDetailsUtils.hexColor(route['textColor']?.toString() ?? 'FFFFFF');
              segments.add(
                RouteSegment(
                  points: points,
                  color: TripDetailsUtils.resolvedPolylineColor(routeColor: rColor, routeTextColor: rTextColor),
                ),
              );
            }
          }

          final patternStops = pattern['stops'];
          if (patternStops is List) {
            for (var i = 0; i < patternStops.length; i++) {
              final stop = patternStops[i];
              if (stop is Map) {
                final stopId = stop['gtfsId']?.toString();
                if (stopId != null && addedStopIds.add(stopId)) {
                  final lat = stop['lat'];
                  final lon = stop['lon'];
                  if (lat is num && lon is num) {
                    final name = stop['name']?.toString() ?? '';
                    final bearing = stop['bearing'] is num ? (stop['bearing'] as num).toDouble() : null;
                    final platformCode = stop['platformCode']?.toString().trim();
                    
                    final type = i == 0
                        ? RouteStopType.start
                        : (i == patternStops.length - 1
                            ? RouteStopType.end
                            : RouteStopType.transfer);

                    stops.add(
                      RouteStopMarker(
                        point: LatLng(lat.toDouble(), lon.toDouble()),
                        label: TripDetailsUtils.plainText(name),
                        type: type,
                        stopId: stopId,
                        bearing: bearing,
                        platformCode: platformCode != null && platformCode.isNotEmpty ? platformCode : null,
                      ),
                    );
                  }
                }
              }
            }
          }
        }
      }
      final routeName = route['shortName']?.toString() ?? route['longName']?.toString() ?? '';
      _mapCubit.setSelectedRouteInfo(
        routeName,
        TripDetailsUtils.hexColor(route['color']?.toString() ?? '0A84FF'),
        TripDetailsUtils.hexColor(route['textColor']?.toString() ?? 'FFFFFF'),
      );
      
      _mapCubit.showDesktopRouteOnBackgroundMap(
        routeData: RouteMapData(segments: segments, stops: stops),
      );
    }
  }
}
