import 'package:flutter/material.dart';
import '../../../theme/app_texts.dart';
import '../../../widgets/maps/plan_map_view.dart';
import '../../../widgets/tables/dummy_table.dart';

class MainSelectedMapResultCard extends StatelessWidget {
  static const double _legTileExtent = 64;
  static const int _maxVisibleLegs = 5;

  final SelectedItineraryMapPayload? payload;
  final VoidCallback onBack;

  const MainSelectedMapResultCard({
    super.key,
    required this.payload,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final current = payload;
    if (current == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.08))
            : null,
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          title: Text(
            current.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(
            current.subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: [
            SizedBox(
              height:
                  (current.legDetails.length > _maxVisibleLegs
                      ? _maxVisibleLegs
                      : current.legDetails.length) *
                  _legTileExtent,
              child: ListView.builder(
                itemCount: current.legDetails.length,
                itemBuilder: (context, index) {
                  final detail = current.legDetails[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(detail.icon),
                    title: Text('${detail.fromName} → ${detail.toName}'),
                    subtitle: Text(detail.subtitle),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                label: Text(AppTexts.back),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectedItineraryMapScreen extends StatelessWidget {
  final SelectedItineraryMapPayload payload;

  const SelectedItineraryMapScreen({
    super.key,
    required this.payload,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppTexts.mainRouteOnMap)),
      body: Stack(
        children: [
          Positioned.fill(
            child: PlanMapView(
              routeData: payload.routeData,
              controlsBottomInset: 220,
              fitPadding: const EdgeInsets.fromLTRB(48, 48, 48, 320),
              showRotationControls: false,
              useBaseMapStopIcon: true,
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: MainSelectedMapResultCard(
                payload: payload,
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
