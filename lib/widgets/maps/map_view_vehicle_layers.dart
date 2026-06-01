part of 'map_view.dart';

extension _MapViewVehicleLayers on _MapViewState {
  List<Widget> _buildVehicleAndStopLayers() {
    final layers = <Widget>[];

    if (_nearbyStops.isNotEmpty) {
      layers.add(
        MarkerLayer(
          markers: _nearbyStops
              .where((stop) => _selectedStopMarkerId != stop.stopId)
              .map(
                (stop) => Marker(
                  key: ValueKey(stop.stopId),
                  point: stop.point,
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _toggleStopLabel(stop),
                    child: _buildMapStopDot(),
                  ),
                ),
              )
              .toList(),
        ),
      );
    }

    if (_vehicleMarkers.isNotEmpty) {
      layers.add(
        MarkerLayer(
          markers: _vehicleMarkers
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
          markers: _vehicleMarkers
              .where((vehicle) => _selectedVehicleMarkerId == vehicle.markerId)
              .map(
                (vehicle) => Marker(
                  point: vehicle.point,
                  width: 320,
                  height: 220,
                  alignment: Alignment.center,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        bottom: 122,
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
                        child: _buildMapStopDot(),
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
