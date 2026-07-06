import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/maps/route_map_data.dart';
import '../widgets/tables/route_planner_results_view.dart';

class MapState {
  final RouteMapData routeOverlayData;
  final RouteVehicleMarker? routeVehicleMarker;
  final SelectedItineraryMapPayload? selectedMapPayload;

  const MapState({
    required this.routeOverlayData,
    this.routeVehicleMarker,
    this.selectedMapPayload,
  });

  factory MapState.initial() {
    return const MapState(
      routeOverlayData: RouteMapData(segments: [], stops: []),
    );
  }

  MapState copyWith({
    RouteMapData? routeOverlayData,
    bool clearRouteOverlayData = false,
    RouteVehicleMarker? routeVehicleMarker,
    bool clearRouteVehicleMarker = false,
    SelectedItineraryMapPayload? selectedMapPayload,
    bool clearSelectedMapPayload = false,
  }) {
    return MapState(
      routeOverlayData: clearRouteOverlayData
          ? const RouteMapData(segments: [], stops: [])
          : (routeOverlayData ?? this.routeOverlayData),
      routeVehicleMarker: clearRouteVehicleMarker
          ? null
          : (routeVehicleMarker ?? this.routeVehicleMarker),
      selectedMapPayload: clearSelectedMapPayload
          ? null
          : (selectedMapPayload ?? this.selectedMapPayload),
    );
  }
}

class MapCubit extends Cubit<MapState> {
  MapCubit() : super(MapState.initial());

  void showDesktopRouteOnBackgroundMap({
    required RouteMapData routeData,
    RouteVehicleMarker? vehicleMarker,
    SelectedItineraryMapPayload? selectedPayload,
  }) {
    emit(state.copyWith(
      clearRouteOverlayData: true,
      clearRouteVehicleMarker: true,
      clearSelectedMapPayload: true,
    ));
    Future.microtask(() {
      emit(state.copyWith(
        routeOverlayData: routeData,
        routeVehicleMarker: vehicleMarker,
        selectedMapPayload: selectedPayload,
      ));
    });
  }

  void clearDesktopRouteSelection() {
    emit(state.copyWith(
      clearRouteOverlayData: true,
      clearRouteVehicleMarker: true,
      clearSelectedMapPayload: true,
    ));
  }
}
