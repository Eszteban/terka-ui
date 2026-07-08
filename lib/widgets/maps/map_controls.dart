import 'package:flutter/material.dart';

class MapControls extends StatelessWidget {
  static bool showUserLocation = true;

  final double controlsBottomInset;
  final bool showRotationControls;
  final bool isRotationGestureEnabled;
  final bool isRotated;
  final bool showMyLocationButton;
  final bool isLocating;

  final VoidCallback onResetNorth;
  final VoidCallback onToggleRotation;
  final VoidCallback? onToggleLocationDot;
  final VoidCallback onJumpToCurrentLocation;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onShowAttribution;

  const MapControls({
    super.key,
    required this.controlsBottomInset,
    required this.showRotationControls,
    required this.isRotationGestureEnabled,
    required this.isRotated,
    required this.showMyLocationButton,
    required this.isLocating,
    required this.onResetNorth,
    required this.onToggleRotation,
    this.onToggleLocationDot,
    required this.onJumpToCurrentLocation,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onShowAttribution,
  });

  @override
  Widget build(BuildContext context) {
    final hasCompass = showRotationControls && isRotated;
    final hasRotateToggle = showRotationControls;
    final hasLocationToggle = onToggleLocationDot != null;
    final hasMyLocation = showMyLocationButton;

    final hasLeftColumn =
        hasCompass || hasRotateToggle || hasLocationToggle || hasMyLocation;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Bottom-left column of FABs
        if (hasLeftColumn)
          Positioned(
            left: 12,
            bottom: 12 + controlsBottomInset,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showRotationControls) ...[
                  if (isRotated) ...[
                    FloatingActionButton.small(
                      heroTag: null,
                      onPressed: onResetNorth,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      child: const Icon(Icons.explore),
                    ),
                    const SizedBox(height: 8),
                  ],
                  FloatingActionButton.small(
                    heroTag: null,
                    onPressed: onToggleRotation,
                    backgroundColor: isRotationGestureEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    foregroundColor: isRotationGestureEnabled
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    child: Icon(
                      isRotationGestureEnabled
                          ? Icons.screen_rotation
                          : Icons.screen_lock_rotation,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (onToggleLocationDot != null) ...[
                  FloatingActionButton.small(
                    heroTag: null,
                    onPressed: onToggleLocationDot,
                    backgroundColor: MapControls.showUserLocation
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    foregroundColor: MapControls.showUserLocation
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    child: Icon(
                      MapControls.showUserLocation
                          ? Icons.location_on
                          : Icons.location_off,
                    ),
                  ),
                ],
                if (showMyLocationButton) ...[
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: null,
                    onPressed: onJumpToCurrentLocation,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    child: isLocating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                  ),
                ],
              ],
            ),
          ),

        // Attribution Info Button
        Positioned(
          left: hasLeftColumn ? 64 : 12,
          bottom: 12 + controlsBottomInset,
          child: ClipOval(
            child: Material(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
              child: InkWell(
                onTap: onShowAttribution,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Bottom-right zoom controls column
        Positioned(
          right: 12,
          bottom: 12 + controlsBottomInset,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    onTap: onZoomIn,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Icon(
                        Icons.add,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 24,
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    onTap: onZoomOut,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Icon(
                        Icons.remove,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
