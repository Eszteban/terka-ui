part of 'map_view.dart';

extension _MapViewOverlays on _MapViewState {
  Widget _buildVehicleInfoCard(_VehicleMarkerData vehicle) {
    final lineLabel = vehicle.routeShortName.trim().isNotEmpty
        ? vehicle.routeShortName.trim()
        : (vehicle.serviceLabel.trim().isNotEmpty
              ? vehicle.serviceLabel.trim()
              : '-');
              
    final tripNumberLabel = vehicle.tripNumber.trim().isNotEmpty
        ? vehicle.tripNumber.trim()
        : '-';
        
    final service = vehicle.serviceLabel.trim().isNotEmpty
        ? vehicle.serviceLabel.trim()
        : AppTexts.unknown.toLowerCase();
        
    final fallbackModel = vehicle.mode == 'RAIL_REPLACEMENT_BUS'
        ? AppTexts.railReplacementBus
        : AppTexts.unknown;
        
    final model = vehicle.vehicleModel.trim().isNotEmpty
        ? vehicle.vehicleModel.trim()
        : fallbackModel;

    

    return VehicleInfoCard(
      lineLabel: lineLabel,
      lineLabelUsesSpanFont: vehicle.routeShortNameUsesSpanFont,
      tripNumberLabel: tripNumberLabel,
      tripHeadsignLabel: vehicle.tripHeadsign.trim(),
      serviceLabel: service,
      modelLabel: model,
      vehicleSpeed: vehicle.vehicleSpeed,
      arrivalDelaySeconds: vehicle.arrivalDelaySeconds,
      nextStopName: vehicle.nextStopName,
      markerColor: vehicle.markerColor,
      markerTextColor: vehicle.markerTextColor,
      nextStopStatus: vehicle.nextStopStatus,
      onTap: () {
        _consumeNextMapTapClose();
        _openTripDetails(vehicle);
      },
    );
  }

  Widget _buildVehicleDot(_VehicleMarkerData vehicle) {
    final angle = vehicle.headingDegrees * (3.141592653589793 / 180);
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: vehicle.markerColor,
              border: Border.all(color: vehicle.markerTextColor, width: 2.2),
            ),
          ),
          Transform.rotate(
            angle: angle,
            child: Icon(
              Icons.navigation,
              size: 16,
              color: vehicle.markerTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapStopDot(double? bearing) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final circleColor = isDark ? Colors.black : Colors.white;
    final contentColor = isDark ? Colors.white : Colors.black;

    return SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleColor,
              border: Border.all(color: contentColor, width: 2),
            ),
            child: Icon(Icons.apartment, size: 12, color: contentColor),
          ),
          if (bearing != null)
            Positioned.fill(
              child: Transform.rotate(
                angle: bearing * (3.141592653589793 / 180),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Transform.translate(
                    offset: const Offset(0, -3),
                    child: Icon(
                      Icons.arrow_drop_up,
                      size: 22,
                      color: contentColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStopInfoCard(_MapStopData stop) {
    final info = _selectedStopQuickInfo;
    final stopName = info?.stopName.trim().isNotEmpty == true
        ? info!.stopName.trim()
        : stop.name;
    final lines = info?.lines ?? const <_StopQuickRoute>[];

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _consumeNextMapTapClose();
          _openStopDetails(stop);
        },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                stopName,
                textAlign: TextAlign.center,
                softWrap: true,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              if (_isLoadingSelectedStopQuickInfo)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (!_isLoadingSelectedStopQuickInfo && lines.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: lines.map(_buildStopRouteBadge).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStopRouteBadge(_StopQuickRoute line) {
    return Container(
      padding: line.usesSpanFont
          ? const EdgeInsets.symmetric(horizontal: 0, vertical: 0)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: line.backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        line.label,
        style: TextStyle(
          color: line.textColor,
          fontSize: line.usesSpanFont ? 12 * _MapViewState._spanFontScale : 12,
          fontWeight: FontWeight.w700,
          fontFamily: line.usesSpanFont ? _MapViewState._spanFontFamily : null,
          leadingDistribution: line.usesSpanFont
              ? TextLeadingDistribution.even
              : null,
          height: line.usesSpanFont ? 1.0 : null,
        ),
      ),
    );
  }
}
