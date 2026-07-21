import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/transit_repository.dart';
import 'map_cubit.dart';
import '../utils/trip_details_utils.dart';

abstract class TripDetailsState {}

class TripDetailsLoading extends TripDetailsState {}

class TripDetailsLoaded extends TripDetailsState {
  final Map<String, dynamic> trip;
  final bool isRefreshing;
  final String? refreshError;

  TripDetailsLoaded({
    required this.trip,
    this.isRefreshing = false,
    this.refreshError,
  });

  TripDetailsLoaded copyWith({
    Map<String, dynamic>? trip,
    bool? isRefreshing,
    String? refreshError,
    bool clearRefreshError = false,
  }) {
    return TripDetailsLoaded(
      trip: trip ?? this.trip,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshError: clearRefreshError ? null : (refreshError ?? this.refreshError),
    );
  }
}

class TripDetailsError extends TripDetailsState {
  final String message;
  TripDetailsError(this.message);
}

class TripDetailsCubit extends Cubit<TripDetailsState> {
  final TransitRepository _transitRepository;
  final MapCubit _mapCubit;
  
  final String tripId;
  final String serviceDay;
  
  Timer? _refreshTimer;
  bool _isFetching = false;

  TripDetailsCubit({
    required TransitRepository transitRepository,
    required MapCubit mapCubit,
    required this.tripId,
    required this.serviceDay,
  })  : _transitRepository = transitRepository,
        _mapCubit = mapCubit,
        super(TripDetailsLoading()) {
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => _loadData());
  }

  void forceRefreshMap() {
    if (state is TripDetailsLoaded) {
      final trip = (state as TripDetailsLoaded).trip;
      final routeData = TripDetailsUtils.buildTripRouteMapData(trip);
      final vehicleMarker = TripDetailsUtils.buildTripVehicleMarker(trip, tripId);
      
      _mapCubit.showDesktopRouteOnBackgroundMap(
        routeData: routeData,
        vehicleMarker: vehicleMarker,
      );
    } else {
      _loadData();
    }
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    _mapCubit.clearDesktopRouteSelection();
    return super.close();
  }

  Future<void> _loadData() async {
    if (_isFetching) return;
    _isFetching = true;

    if (state is TripDetailsLoaded) {
      emit((state as TripDetailsLoaded).copyWith(isRefreshing: true, clearRefreshError: true));
    }

    try {
      final trip = await _transitRepository.fetchTripDetails(
        tripId: tripId,
        serviceDay: serviceDay,
      );

      if (trip == null) {
        if (state is TripDetailsLoaded) {
          emit((state as TripDetailsLoaded).copyWith(
            isRefreshing: false,
            refreshError: 'Nincs adat.',
          ));
        } else {
          emit(TripDetailsError('Nincs adat.'));
        }
        _isFetching = false;
        return;
      }

      emit(TripDetailsLoaded(trip: trip));

      final routeData = TripDetailsUtils.buildTripRouteMapData(trip);
      final vehicleMarker = TripDetailsUtils.buildTripVehicleMarker(trip, tripId);
      
      _mapCubit.showDesktopRouteOnBackgroundMap(
        routeData: routeData,
        vehicleMarker: vehicleMarker,
      );

    } catch (e) {
      if (state is TripDetailsLoaded) {
        emit((state as TripDetailsLoaded).copyWith(
          isRefreshing: false,
          refreshError: e.toString(),
        ));
      } else {
        emit(TripDetailsError(e.toString()));
      }
    } finally {
      _isFetching = false;
    }
  }
}
