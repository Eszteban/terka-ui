part of 'map_view.dart';

extension _MapViewInitialization on _MapViewState {
  Future<void> _loadLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_MapViewState._lastLatKey);
    final lon = prefs.getDouble(_MapViewState._lastLonKey);
    if (lat != null && lon != null) {
      _lastStoredLocation = LatLng(lat, lon);
    }
  }

  Future<void> _saveLastLocation(double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_MapViewState._lastLatKey, lat);
    await prefs.setDouble(_MapViewState._lastLonKey, lon);
  }

  Future<void> _tryInitialGpsFocus() async {
    if (_didTryInitialGpsFocus) {
      return;
    }
    _didTryInitialGpsFocus = true;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (_lastStoredLocation != null) {
        _mapController.move(_lastStoredLocation!, 12);
      }
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      if (_lastStoredLocation != null) {
        _mapController.move(_lastStoredLocation!, 12);
      }
      return;
    }

    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) {
      if (!mounted) {
        return;
      }
      await _saveLastLocation(lastKnown.latitude, lastKnown.longitude);
      _mapController.move(
        LatLng(lastKnown.latitude, lastKnown.longitude),
        12,
      );
      return;
    }

    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );
      if (!mounted) {
        return;
      }
      await _saveLastLocation(current.latitude, current.longitude);
      _mapController.move(
        LatLng(current.latitude, current.longitude),
        12,
      );
    } catch (_) {
      if (_lastStoredLocation != null) {
        _mapController.move(_lastStoredLocation!, 12);
      }
      // Fallback to default map center when quick GPS lookup fails.
    }
  }

}
