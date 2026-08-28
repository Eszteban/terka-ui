part of 'map_view.dart';

extension _MapViewVehicleLayers on _MapViewState {
  List<Widget> _buildMapStopLayers() {
    final layers = <Widget>[];

    if (widget.hideGeneralStopsAndVehicles) {
      return layers;
    }

    if (_nearbyStops.isNotEmpty) {
      layers.add(
        MarkerLayer(
          markers: _nearbyStops
              .where((stop) => _selectedStopMarkerId != stop.stopId)
              .map(
                (stop) => Marker(
                  key: ValueKey(stop.stopId),
                  point: stop.point,
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _toggleStopLabel(stop),
                    child: _buildMapStopDot(stop.bearing),
                  ),
                ),
              )
              .toList(),
        ),
      );
    }

    return layers;
  }

  List<Widget> _buildMapVehicleLayers() {
    final layers = <Widget>[];

    if (widget.hideGeneralStopsAndVehicles) {
      return layers;
    }

    // Filter vehicles if selectedRouteName is specified (Vonal kirajzolásánál csak az adott vonalon közlekedő járatok!)
    var vehiclesList = _vehicleMarkers;
    if (widget.selectedRouteName != null) {
      final targetRouteName = plainTextFromHtml(widget.selectedRouteName!).trim().toLowerCase();
      vehiclesList = _vehicleMarkers.where((v) {
        final vehicleRoute = plainTextFromHtml(v.routeShortName).trim().toLowerCase();
        return vehicleRoute == targetRouteName;
      }).toList();
    }

    if (vehiclesList.isNotEmpty) {
      layers.add(
        MarkerLayer(
          markers: vehiclesList
              .where((vehicle) => _selectedVehicleMarkerId != vehicle.markerId)
              .map(
                (vehicle) => Marker(
                  point: vehicle.point,
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _toggleVehicleLabel(vehicle.markerId),
                    child: _buildVehicleDot(vehicle),
                  ),
                ),
              )
              .toList(),
        ),
      );
    }

    return layers;
  }

  List<Widget> _buildSelectedStopOverlayLayers(RouteMapData? routeData) {
    final layers = <Widget>[];
    if (_selectedStopMarkerId == null) return layers;

    // Check in nearbyStops
    final selectedNearby = _nearbyStops.where((s) => s.stopId == _selectedStopMarkerId).toList();
    if (selectedNearby.isNotEmpty) {
      final stop = selectedNearby.first;
      layers.add(
        MarkerLayer(
          markers: [
            Marker(
              key: ValueKey('selected_${stop.stopId}'),
              point: stop.point,
              width: 320,
              height: 220,
              alignment: Alignment.center,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: 115,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _consumeNextMapTapClose,
                      child: _buildStopInfoCard(stop),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _toggleStopLabel(stop),
                    child: _buildMapStopDot(stop.bearing),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      return layers;
    }

    // Check in routeData stops
    if (routeData != null) {
      final selectedRouteStops = routeData.stops.where((s) => s.stopId == _selectedStopMarkerId).toList();
      if (selectedRouteStops.isNotEmpty) {
        final stop = selectedRouteStops.first;
        layers.add(
          MarkerLayer(
            markers: [
              Marker(
                key: ValueKey('selected_route_${stop.stopId}'),
                point: stop.point,
                width: 320,
                height: 220,
                alignment: Alignment.center,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      bottom: 115,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _consumeNextMapTapClose,
                        child: _buildRouteStopInfoCard(stop),
                      ),
                    ),
                    _buildMapStopDot(stop.bearing),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    }

    return layers;
  }

  List<Widget> _buildSelectedVehicleOverlayLayers() {
    final layers = <Widget>[];
    if (_selectedVehicleMarkerId == null) return layers;

    final selectedVehicles = _vehicleMarkers.where((v) => v.markerId == _selectedVehicleMarkerId).toList();
    if (selectedVehicles.isNotEmpty) {
      final vehicle = selectedVehicles.first;
      layers.add(
        MarkerLayer(
          markers: [
            Marker(
              key: ValueKey('selected_veh_${vehicle.markerId}'),
              point: vehicle.point,
              width: 320,
              height: 380,
              alignment: Alignment.center,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: 200,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _consumeNextMapTapClose,
                      child: _buildVehicleInfoCard(vehicle),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _toggleVehicleLabel(vehicle.markerId),
                    child: _buildVehicleDot(vehicle),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return layers;
  }
}
