part of 'map_view.dart';

extension _MapViewOverlays on _MapViewState {
  String _formatDelay(int? delaySeconds) {
    if (delaySeconds == null) {
      return 'késés: n/a';
    }
    if (delaySeconds.abs() < 60) {
      return 'késés: 0p';
    }
    final minutes = (delaySeconds / 60).round();
    if (minutes > 0) {
      return 'késés: +${minutes}p';
    }
    return 'késés: ${minutes}p';
  }

  String _vehicleInfoLabel(_VehicleMarkerData vehicle) {
    final service = vehicle.serviceLabel.trim().isNotEmpty
        ? vehicle.serviceLabel.trim()
        : 'ismeretlen';
    final delayPart = _formatDelay(vehicle.arrivalDelaySeconds);
    final nextStop = (vehicle.nextStopName ?? vehicle.tripHeadsign).trim();
    final nextStopPart = nextStop.isNotEmpty ? 'köv: $nextStop' : 'köv: -';
    final fallbackModel = vehicle.mode == 'RAIL_REPLACEMENT_BUS'
        ? 'vonatpótló busz'
        : 'Ismeretlen';
    final model = vehicle.vehicleModel.trim().isNotEmpty
        ? vehicle.vehicleModel.trim()
        : fallbackModel;
    return '$service\n$model\n$delayPart\n$nextStopPart';
  }

  Widget _buildVehicleInfoCard(_VehicleMarkerData vehicle) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardTextColor = colorScheme.onSurface;
    final lineLabel = vehicle.routeShortName.trim().isNotEmpty
        ? vehicle.routeShortName.trim()
        : (vehicle.serviceLabel.trim().isNotEmpty
              ? vehicle.serviceLabel.trim()
              : '-');
    final tripNumberLabel = vehicle.tripNumber.trim().isNotEmpty
        ? vehicle.tripNumber.trim()
        : '-';
    final tripHeadsignLabel = vehicle.tripHeadsign.trim();

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: vehicle.routeShortNameUsesSpanFont
                      ? const EdgeInsets.symmetric(horizontal: 0, vertical: 0)
                      : const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: vehicle.markerColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    lineLabel,
                    style: TextStyle(
                      fontSize: vehicle.routeShortNameUsesSpanFont
                          ? 12 * _MapViewState._spanFontScale
                          : 12,
                      fontWeight: FontWeight.w700,
                      color: vehicle.markerTextColor,
                      fontFamily: vehicle.routeShortNameUsesSpanFont
                          ? _MapViewState._spanFontFamily
                          : null,
                      leadingDistribution: vehicle.routeShortNameUsesSpanFont
                          ? TextLeadingDistribution.even
                          : null,
                      height: vehicle.routeShortNameUsesSpanFont ? 1.0 : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tripNumberLabel,
                    softWrap: true,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: vehicle.tripNumberUsesSpanFont
                          ? 12 * _MapViewState._spanFontScale
                          : 12,
                      fontWeight: FontWeight.w700,
                      color: cardTextColor,
                      fontFamily: vehicle.tripNumberUsesSpanFont
                          ? _MapViewState._spanFontFamily
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            if (tripHeadsignLabel.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                tripHeadsignLabel,
                softWrap: true,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: vehicle.tripHeadsignUsesSpanFont
                      ? 12 * _MapViewState._spanFontScale
                      : 12,
                  fontWeight: FontWeight.w600,
                  color: cardTextColor,
                  fontFamily: vehicle.tripHeadsignUsesSpanFont
                      ? _MapViewState._spanFontFamily
                      : null,
                  leadingDistribution: vehicle.tripHeadsignUsesSpanFont
                      ? TextLeadingDistribution.even
                      : null,
                  height: vehicle.tripHeadsignUsesSpanFont ? 1.0 : 1.2,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _vehicleInfoLabel(vehicle),
              maxLines: 5,
              style: TextStyle(
                fontSize: vehicle.serviceLabelUsesSpanFont
                    ? 12 * _MapViewState._spanFontScale
                    : 12,
                height: 1.15,
                fontWeight: FontWeight.w600,
                color: cardTextColor,
                fontFamily: vehicle.serviceLabelUsesSpanFont
                    ? _MapViewState._spanFontFamily
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                _consumeNextMapTapClose();
                _openTripDetails(vehicle);
              },
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 28),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Járat adatai'),
            ),
          ],
        ),
      ),
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

  Widget _buildMapStopDot() {
    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
            ),
          ),
          const Icon(Icons.apartment, size: 12, color: Colors.black),
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
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
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
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _openStopDetails(stop),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 28),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Megálló adatai'),
            ),
          ],
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
