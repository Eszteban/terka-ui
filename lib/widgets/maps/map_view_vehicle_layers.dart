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

    if (_selectedStopMarkerId != null) {
      layers.add(
        MarkerLayer(
          markers: _nearbyStops
              .where((stop) => _selectedStopMarkerId == stop.stopId)
              .map(
                (stop) => Marker(
                  key: ValueKey('selected_${stop.stopId}'),
                  point: stop.point,
                  width: 320,
                  height: 180,
                  alignment: Alignment.center,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        bottom: 92,
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

    if (_selectedVehicleMarkerId != null) {
      layers.add(
        MarkerLayer(
          markers: vehiclesList
              .where((vehicle) => _selectedVehicleMarkerId == vehicle.markerId)
              .map(
                (vehicle) => Marker(
                  point: vehicle.point,
                  width: 320,
                  height: 360,
                  alignment: Alignment.center,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        bottom: 192,
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
              )
              .toList(),
        ),
      );
    }

    return layers;
  }
}
