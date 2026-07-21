import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:terka/theme/app_texts.dart';
import 'package:terka/theme/app_tokens.dart';
import '../../../utils/markup_text_utils.dart' as markup;
import '../../../widgets/maps/map_view.dart';
import '../../../widgets/maps/route_map_data.dart';
import '../../../widgets/tables/route_planner_results_view.dart';
import '../../../widgets/forms/autocomplete_search_field.dart';
import '../../../widgets/line_badge.dart';
import 'main_desktop_search_overlay.dart';
import 'main_selected_map_card.dart';

class TerkaTabletLayout extends StatefulWidget {
  final bool showMap;

  final RouteMapData desktopRouteOverlayData;
  final RouteVehicleMarker? desktopRouteVehicleMarker;
  final SelectedItineraryMapPayload? desktopSelectedMapPayload;

  final Widget sidebarContent;
  final VoidCallback onClearDesktopRouteSelection;
  final Function(String, String)? onOpenTripDetailsRequested;
  final Function(String, String?, LatLng?, List<String>?)?
  onOpenStopDetailsRequested;
  final bool hideGeneralStopsAndVehicles;
  final LatLng? searchHighlightPoint;
  final String? searchHighlightName;
  final LatLng? stopHighlightPoint;
  final void Function(String stopName, LatLng stopPoint, [String? stopId])?
  onPlanRouteToStop;
  final void Function(String name, LatLng point, bool isDestination)? onPlanRouteFromMap;
  final String? desktopSelectedRouteName;
  final Color? desktopSelectedRouteColor;
  final Color? desktopSelectedRouteTextColor;
  final ValueChanged<SuggestionEntry>? onSearchSuggestionSelected;

  const TerkaTabletLayout({
    super.key,
    required this.showMap,
    required this.desktopRouteOverlayData,
    required this.desktopRouteVehicleMarker,
    required this.desktopSelectedMapPayload,
    required this.sidebarContent,
    required this.onClearDesktopRouteSelection,
    this.onOpenTripDetailsRequested,
    this.onOpenStopDetailsRequested,
    this.hideGeneralStopsAndVehicles = false,
    this.searchHighlightPoint,
    this.searchHighlightName,
    this.stopHighlightPoint,
    this.onPlanRouteToStop,
    this.onPlanRouteFromMap,
    this.desktopSelectedRouteName,
    this.desktopSelectedRouteColor,
    this.desktopSelectedRouteTextColor,
    this.onSearchSuggestionSelected,
  });

  @override
  State<TerkaTabletLayout> createState() => _TerkaTabletLayoutState();
}

class _TerkaTabletLayoutState extends State<TerkaTabletLayout> {
  bool _isPanelVisible = true;

  Widget _buildTabButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isPanelVisible = !_isPanelVisible;
        });
      },
      child: Container(
        width: 40.0,
        height: 60.0,
        decoration: BoxDecoration(
          color: AppColors.getSurface(context).withValues(alpha: 0.84),
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
            right: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            _isPanelVisible ? Icons.chevron_left : Icons.chevron_right,
            color: colorScheme.onSurface,
            size: 28,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showPlannerPanel = !widget.showMap;
    final hasRouteOverlay =
        widget.desktopRouteOverlayData.hasContent ||
        widget.desktopRouteVehicleMarker != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxPanelWidth = (constraints.maxWidth - 39.0).clamp(200.0, double.infinity);
        final panelWidth = 430.0.clamp(0.0, maxPanelWidth);

        final topOffset =
            MediaQuery.of(context).viewPadding.top +
            88.0 +
            52.0 +
            AppSpacing.md;
        final bottomOffset = MediaQuery.of(context).viewPadding.bottom + 48.0;
        final maxPanelHeight =
            (constraints.maxHeight - topOffset - bottomOffset).clamp(
              200.0,
              double.infinity,
            );

        final maxLeftPadding = (constraints.maxWidth - 100.0).clamp(48.0, double.infinity);
        final leftPadding = (panelWidth + 90.0).clamp(48.0, maxLeftPadding);

        return Stack(
          children: [
            Positioned.fill(
              child: MapView(
                controlsBottomInset: 0,
                routeOverlayData: hasRouteOverlay
                    ? widget.desktopRouteOverlayData
                    : null,
                routeVehicleMarker: widget.desktopRouteVehicleMarker,
                routeFitPadding: showPlannerPanel && _isPanelVisible
                    ? EdgeInsets.fromLTRB(leftPadding, 48, 48, 260)
                    : const EdgeInsets.fromLTRB(AppSpacing.touchTarget, AppSpacing.touchTarget, AppSpacing.touchTarget, 220),
                showRouteStopLabels: false,
                useBaseMapStopIcon: true,
                onOpenTripDetailsRequested: widget.onOpenTripDetailsRequested,
                onOpenStopDetailsRequested: widget.onOpenStopDetailsRequested,
                hideGeneralStopsAndVehicles: widget.hideGeneralStopsAndVehicles,
                searchHighlightPoint: widget.searchHighlightPoint,
                stopHighlightPoint: widget.stopHighlightPoint,
                onPlanRouteToStop: widget.onPlanRouteToStop,
                onPlanRouteFromMap: widget.onPlanRouteFromMap,
                selectedRouteName: widget.desktopSelectedRouteName,
              ),
            ),
            if (showPlannerPanel)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                left: _isPanelVisible ? 0.0 : -panelWidth,
                top:
                    MediaQuery.of(context).viewPadding.top +
                    88.0 +
                    52.0 +
                    AppSpacing.md,
                child: SizedBox(
                  width: panelWidth + 39.0,
                  child: Stack(
                    children: [
                      Container(
                        width: panelWidth,
                        padding: const EdgeInsets.only(left: AppSpacing.lg),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: maxPanelHeight,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Flexible(
                                fit: FlexFit.loose,
                                child: widget.sidebarContent,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0.0,
                        top: 40.0,
                        child: _buildTabButton(context),
                      ),
                    ],
                  ),
                ),
              ),
            if (showPlannerPanel && widget.onSearchSuggestionSelected != null)
              Positioned(
                top: MediaQuery.of(context).viewPadding.top + 88.0,
                left: 16.0,
                child: MainDesktopSearchOverlay(
                  onSuggestionSelected: widget.onSearchSuggestionSelected!,
                  width: panelWidth - 16.0,
                ),
              ),
            if (showPlannerPanel &&
                widget.searchHighlightPoint != null &&
                widget.searchHighlightName != null)
              Positioned(
                left: panelWidth + 16.0,
                top: MediaQuery.of(context).viewPadding.top + 88.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.searchHighlightPoint != null &&
                        widget.searchHighlightName != null)
                      Card(
                        elevation: 6,
                        shadowColor: AppColors.black.withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant
                                .withValues(
                                  alpha:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? 0.3
                                      : 0.4,
                                ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.place,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 200,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.searchHighlightName!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      AppTexts.isHungarian
                                          ? 'Kiválasztott hely'
                                          : 'Selected location',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              if (widget.onPlanRouteToStop != null)
                                IconButton(
                                  icon: Icon(
                                    Icons.directions,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  onPressed: () {
                                    widget.onPlanRouteToStop!(
                                      widget.searchHighlightName!,
                                      widget.searchHighlightPoint!,
                                    );
                                  },
                                  tooltip: AppTexts.isHungarian
                                      ? 'Útvonaltervezés ide'
                                      : 'Plan route here',
                                ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: widget.onClearDesktopRouteSelection,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
