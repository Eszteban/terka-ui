import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../repositories/transit_repository.dart';
import '../../../injection_container.dart';
import '../../../models/trip_stop_quick_info.dart';
import '../../../widgets/maps/route_map_data.dart';
import '../../../widgets/line_badge.dart';
import 'package:terka/theme/app_tokens.dart';

class TripDetailsStopCard extends StatefulWidget {
  final RouteStopMarker stop;
  final void Function({
    required String stopId,
    required String stopName,
    required LatLng? initialStopPoint,
  }) onOpenStopDetails;

  const TripDetailsStopCard({
    super.key,
    required this.stop,
    required this.onOpenStopDetails,
  });

  @override
  State<TripDetailsStopCard> createState() => _TripDetailsStopCardState();
}

class _TripDetailsStopCardState extends State<TripDetailsStopCard> {
  final TransitRepository _transitRepository = sl<TransitRepository>();
  TripStopQuickInfo? _selectedStopQuickInfo;
  bool _isLoadingSelectedStopQuickInfo = false;
  String? _selectedStopQuickInfoStopId;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  @override
  void didUpdateWidget(covariant TripDetailsStopCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stop.stopId != oldWidget.stop.stopId) {
      _loadInfo();
    }
  }

  Future<void> _loadInfo() async {
    final stopId = widget.stop.stopId?.trim() ?? '';
    final fallbackName = widget.stop.label;
    if (stopId.isEmpty) return;

    setState(() {
      _isLoadingSelectedStopQuickInfo = true;
      _selectedStopQuickInfoStopId = stopId;
      _selectedStopQuickInfo = null;
    });

    try {
      final info = await _transitRepository.fetchStopQuickInfo(
        stopId: stopId,
        fallbackName: fallbackName,
      );

      if (!mounted || _selectedStopQuickInfoStopId != stopId) {
        return;
      }

      setState(() {
        _isLoadingSelectedStopQuickInfo = false;
        _selectedStopQuickInfo = info ??
            TripStopQuickInfo(
              stopId: stopId,
              stopName: fallbackName,
              lines: const [],
            );
      });
    } catch (_) {
      if (!mounted || _selectedStopQuickInfoStopId != stopId) {
        return;
      }
      setState(() {
        _isLoadingSelectedStopQuickInfo = false;
        _selectedStopQuickInfo = TripStopQuickInfo(
          stopId: stopId,
          stopName: fallbackName,
          lines: const [],
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stopId = widget.stop.stopId?.trim() ?? '';
    final stopName = _selectedStopQuickInfo?.stopName.trim().isNotEmpty == true
        ? _selectedStopQuickInfo!.stopName.trim()
        : widget.stop.label;
    final lines = _selectedStopQuickInfo?.lines ?? const <TripStopQuickRoute>[];

    return Material(
      color: AppColors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: stopId.isEmpty
            ? null
            : () {
                widget.onOpenStopDetails(
                  stopId: stopId,
                  stopName: stopName,
                  initialStopPoint: widget.stop.point,
                );
              },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.stop.label,
                textAlign: TextAlign.center,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (_isLoadingSelectedStopQuickInfo && stopId.isNotEmpty)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (lines.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: lines
                      .map((l) => LineBadge(
                            lineLabel: l.label,
                            routeColor: l.backgroundColor,
                            routeTextColor: l.textColor,
                            useSpanFont: l.usesSpanFont,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
