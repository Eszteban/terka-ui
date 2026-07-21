import 'package:flutter/material.dart';
import 'package:terka/theme/app_tokens.dart';

class _MapControlButton {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Widget? customIcon;

  _MapControlButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.customIcon,
  });
}

class MapControls extends StatefulWidget {
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
  State<MapControls> createState() => _MapControlsState();
}

class _MapControlsState extends State<MapControls> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasCompass = widget.showRotationControls && widget.isRotated;
    final hasRotateToggle = widget.showRotationControls;
    final hasLocationToggle = widget.onToggleLocationDot != null;
    final hasMyLocation = widget.showMyLocationButton;

    final hasLeftColumn =
        hasCompass || hasRotateToggle || hasLocationToggle || hasMyLocation;

    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final safeBottom = bottomPadding + 12 + widget.controlsBottomInset;

    final buttons = <_MapControlButton>[];

    if (hasLeftColumn) {
      if (_isExpanded) {
        if (widget.showRotationControls && widget.isRotated) {
          buttons.add(_MapControlButton(
            icon: Icons.explore,
            onTap: widget.onResetNorth,
          ));
        }
        if (widget.showRotationControls) {
          buttons.add(_MapControlButton(
            icon: widget.isRotationGestureEnabled
                ? Icons.screen_rotation
                : Icons.screen_lock_rotation,
            iconColor: widget.isRotationGestureEnabled
                ? Theme.of(context).colorScheme.primary
                : null,
            onTap: widget.onToggleRotation,
          ));
        }
        if (widget.onToggleLocationDot != null) {
          buttons.add(_MapControlButton(
            icon: MapControls.showUserLocation
                ? Icons.location_on
                : Icons.location_off,
            iconColor: MapControls.showUserLocation
                ? Theme.of(context).colorScheme.primary
                : null,
            onTap: widget.onToggleLocationDot!,
          ));
        }
        if (widget.showMyLocationButton) {
          buttons.add(_MapControlButton(
            icon: Icons.my_location,
            customIcon: widget.isLocating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xs),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            onTap: widget.onJumpToCurrentLocation,
          ));
        }
        buttons.add(_MapControlButton(
          icon: Icons.keyboard_arrow_down,
          onTap: () => setState(() => _isExpanded = false),
        ));
      } else {
        buttons.add(_MapControlButton(
          icon: Icons.layers,
          onTap: () => setState(() => _isExpanded = true),
        ));
      }
    }

    buttons.add(_MapControlButton(
      icon: Icons.add,
      onTap: widget.onZoomIn,
    ));
    buttons.add(_MapControlButton(
      icon: Icons.remove,
      onTap: widget.onZoomOut,
    ));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Attribution Info Button (moved fully left since buttons moved to right)
        Positioned(
          left: 12,
          bottom: safeBottom,
          child: ClipOval(
            child: Material(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
              child: InkWell(
                onTap: widget.onShowAttribution,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
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

        // Bottom-right controls column
        Positioned(
          right: 12,
          bottom: safeBottom,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < buttons.length; i++) ...[
                    Material(
                      color: AppColors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.vertical(
                          top: i == 0 ? const Radius.circular(12) : Radius.zero,
                          bottom: i == buttons.length - 1 ? const Radius.circular(12) : Radius.zero,
                        ),
                        onTap: buttons[i].onTap,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: buttons[i].customIcon ?? Icon(
                            buttons[i].icon,
                            color: buttons[i].iconColor ?? Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    if (i < buttons.length - 1)
                      Container(
                        width: 24,
                        height: 1,
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                      ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

