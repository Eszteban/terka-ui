import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_texts.dart';
import '../../../widgets/maps/plan_map_view.dart';
import '../../../widgets/tables/route_planner_results_view.dart';

class SelectedItineraryMapScreen extends StatelessWidget {
  static const double _mobileSheetMinSize = 0.16;
  static const double _mobileSheetInitialSize = 0.24;
  static const double _mobileSheetMaxSize = 0.9;

  final SelectedItineraryMapPayload payload;

  const SelectedItineraryMapScreen({
    super.key,
    required this.payload,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final controlsBottomInset = screenHeight * _mobileSheetInitialSize + 24;

    return Scaffold(
      appBar: AppBar(title: Text(AppTexts.mainRouteOnMap)),
      body: Stack(
        children: [
          Positioned.fill(
            child: PlanMapView(
              routeData: payload.routeData,
              controlsBottomInset: controlsBottomInset,
              fitPadding: EdgeInsets.fromLTRB(48, 48, 48, controlsBottomInset + 120),
              showRotationControls: false,
              useBaseMapStopIcon: true,
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: _mobileSheetInitialSize,
            minChildSize: _mobileSheetMinSize,
            maxChildSize: _mobileSheetMaxSize,
            snap: true,
            snapSizes: const [_mobileSheetInitialSize, 0.5, _mobileSheetMaxSize],
            builder: (context, scrollController) {
              final colorScheme = Theme.of(context).colorScheme;
              return Material(
                elevation: 8,
                color: colorScheme.surface.withValues(alpha: 0.97),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    SingleChildScrollView(
                      controller: scrollController,
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 42,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: colorScheme.outlineVariant,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            RoutePlannerResultsView.buildBentoHeader(
                              context,
                              payload.itinerary,
                              payload.summary,
                              payload.lineBadges,
                              payload.missingAgencies,
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...RoutePlannerResultsView.buildLegTiles(
                              context, 
                              payload.itinerary,
                              onOpenTripDetailsRequested: (tripId, serviceDay) {
                                final encodedTripId = Uri.encodeComponent(tripId);
                                if (serviceDay.isNotEmpty) {
                                  context.push('/trip/$encodedTripId?date=$serviceDay');
                                } else {
                                  context.push('/trip/$encodedTripId');
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
