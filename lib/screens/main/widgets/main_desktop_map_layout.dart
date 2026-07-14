import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/maps/map_view.dart';
import '../../../widgets/maps/route_map_data.dart';
import '../../../widgets/tables/route_planner_results_view.dart';
import 'main_selected_map_card.dart';

class MainDesktopMapLayout extends StatelessWidget {
  final bool showMap;
  final bool showResultCard;

  final RouteMapData desktopRouteOverlayData;
  final RouteVehicleMarker? desktopRouteVehicleMarker;
  final SelectedItineraryMapPayload? desktopSelectedMapPayload;

  final Widget sidebarContent;
  final VoidCallback onClearDesktopRouteSelection;
  final Function(RouteMapData, RouteVehicleMarker?) onShowTripOnBackgroundMap;
  final Function(String, String)? onOpenTripDetailsRequested;
  final Function(String, String?, LatLng?, List<String>?)? onOpenStopDetailsRequested;
  final bool hideGeneralStopsAndVehicles;
  final LatLng? searchHighlightPoint;
  final void Function(String stopName, LatLng stopPoint, String stopId)? onPlanRouteToStop;
  final String? desktopSelectedRouteName;

  const MainDesktopMapLayout({
    super.key,
    required this.showMap,
    required this.showResultCard,
    required this.desktopRouteOverlayData,
    required this.desktopRouteVehicleMarker,
    required this.desktopSelectedMapPayload,
    required this.sidebarContent,
    required this.onClearDesktopRouteSelection,
    required this.onShowTripOnBackgroundMap,
    this.onOpenTripDetailsRequested,
    this.onOpenStopDetailsRequested,
    this.hideGeneralStopsAndVehicles = false,
    this.searchHighlightPoint,
    this.onPlanRouteToStop,
    this.desktopSelectedRouteName,
  });

  Widget _buildDesktopOverlayPanel({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: AppColors.getSurface(context).withValues(alpha: 0.84),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const panelWidth = 430.0;
    final showPlannerPanel = !showMap;
    final hasRouteOverlay =
        desktopRouteOverlayData.hasContent ||
        desktopRouteVehicleMarker != null;

    return Stack(
      children: [
        Positioned.fill(
          child: MapView(
            controlsBottomInset: showPlannerPanel && showResultCard ? 220 : 0,
            routeOverlayData: hasRouteOverlay ? desktopRouteOverlayData : null,
            routeVehicleMarker: desktopRouteVehicleMarker,
            routeFitPadding: showPlannerPanel
                ? const EdgeInsets.fromLTRB(520, 48, 48, 260)
                : const EdgeInsets.fromLTRB(48, 48, 48, 220),
            showRouteStopLabels: false,
            useBaseMapStopIcon: true,
            onShowTripOnBackgroundMap: onShowTripOnBackgroundMap,
            onOpenTripDetailsRequested: onOpenTripDetailsRequested,
            onOpenStopDetailsRequested: onOpenStopDetailsRequested,
            hideGeneralStopsAndVehicles: hideGeneralStopsAndVehicles,
            searchHighlightPoint: searchHighlightPoint,
            onPlanRouteToStop: onPlanRouteToStop,
            selectedRouteName: desktopSelectedRouteName,
          ),
        ),
        if (showPlannerPanel)
          Positioned(
            left: AppSpacing.xl,
            top: AppSpacing.xl,
            bottom: AppSpacing.xl,
            width: panelWidth,
            child: Column(
              children: [
                Expanded(
                  child: _buildDesktopOverlayPanel(
                    context: context,
                    child: sidebarContent,
                  ),
                ),
                if (showResultCard) ...[
                  const SizedBox(height: 12),
                  _buildDesktopOverlayPanel(
                    context: context,
                    padding: EdgeInsets.zero,
                    child: MainSelectedMapResultCard(
                      payload: desktopSelectedMapPayload,
                      onBack: onClearDesktopRouteSelection,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
