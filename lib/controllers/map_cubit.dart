import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/maps/route_map_data.dart';
import '../widgets/tables/route_planner_results_view.dart';

class MapState {
  final RouteMapData routeOverlayData;
  final RouteVehicleMarker? routeVehicleMarker;
  final SelectedItineraryMapPayload? selectedMapPayload;

  final LatLng? searchHighlightPoint;
  final String? searchHighlightName;
  final LatLng? stopHighlightPoint;
  final String? stopHighlightName;
  final String? selectedRouteName;
  final Color? selectedRouteColor;
  final Color? selectedRouteTextColor;

  const MapState({
    required this.routeOverlayData,
    this.routeVehicleMarker,
    this.selectedMapPayload,
    this.searchHighlightPoint,
    this.searchHighlightName,
    this.stopHighlightPoint,
    this.stopHighlightName,
    this.selectedRouteName,
    this.selectedRouteColor,
    this.selectedRouteTextColor,
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
    LatLng? searchHighlightPoint,
    bool clearSearchHighlightPoint = false,
    String? searchHighlightName,
    bool clearSearchHighlightName = false,
    LatLng? stopHighlightPoint,
    bool clearStopHighlightPoint = false,
    String? stopHighlightName,
    bool clearStopHighlightName = false,
    String? selectedRouteName,
    bool clearSelectedRouteName = false,
    Color? selectedRouteColor,
    bool clearSelectedRouteColor = false,
    Color? selectedRouteTextColor,
    bool clearSelectedRouteTextColor = false,
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
      searchHighlightPoint: clearSearchHighlightPoint
          ? null
          : (searchHighlightPoint ?? this.searchHighlightPoint),
      searchHighlightName: clearSearchHighlightName
          ? null
          : (searchHighlightName ?? this.searchHighlightName),
      stopHighlightPoint: clearStopHighlightPoint
          ? null
          : (stopHighlightPoint ?? this.stopHighlightPoint),
      stopHighlightName: clearStopHighlightName
          ? null
          : (stopHighlightName ?? this.stopHighlightName),
      selectedRouteName: clearSelectedRouteName
          ? null
          : (selectedRouteName ?? this.selectedRouteName),
      selectedRouteColor: clearSelectedRouteColor
          ? null
          : (selectedRouteColor ?? this.selectedRouteColor),
      selectedRouteTextColor: clearSelectedRouteTextColor
          ? null
          : (selectedRouteTextColor ?? this.selectedRouteTextColor),
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
      clearSelectedRouteName: true,
      clearSelectedRouteColor: true,
      clearSelectedRouteTextColor: true,
      clearSearchHighlightPoint: true,
      clearSearchHighlightName: true,
    ));
  }

  void clearRouteDataOnly() {
    emit(state.copyWith(
      clearRouteOverlayData: true,
      clearRouteVehicleMarker: true,
      clearSelectedMapPayload: true,
      clearSelectedRouteName: true,
      clearSelectedRouteColor: true,
      clearSelectedRouteTextColor: true,
    ));
  }

  void setSearchHighlight(LatLng point, String? name) {
    emit(state.copyWith(
      searchHighlightPoint: point,
      searchHighlightName: name,
    ));
  }

  void clearSearchHighlight() {
    emit(state.copyWith(
      clearSearchHighlightPoint: true,
      clearSearchHighlightName: true,
    ));
  }

  void setStopHighlight(LatLng point, String name) {
    emit(state.copyWith(
      stopHighlightPoint: point,
      stopHighlightName: name,
    ));
  }

  void clearStopHighlight() {
    emit(state.copyWith(
      clearStopHighlightPoint: true,
      clearStopHighlightName: true,
    ));
  }

  void setSelectedRouteInfo(String name, Color? color, Color? textColor) {
    emit(state.copyWith(
      selectedRouteName: name,
      selectedRouteColor: color,
      selectedRouteTextColor: textColor,
    ));
  }
}
