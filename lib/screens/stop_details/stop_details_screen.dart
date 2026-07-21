import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../injection_container.dart';
import '../../controllers/stop_details_cubit.dart';
import '../../utils/stop_details_utils.dart';
import '../../widgets/layout/desktop_sidebar_wrapper.dart';
import '../../widgets/layout/screen_header.dart';
import '../../theme/app_texts.dart';
import '../../utils/adaptive_dialog_utils.dart';
import '../../utils/layout_provider.dart';

import 'widgets/stop_details_mobile_sheet.dart';
import 'widgets/stop_details_tabs.dart';

class StopDetailsScreen extends StatelessWidget {
  static const double desktopBreakpoint = 600;

  final String stopId;
  final String? initialStopName;
  final LatLng? initialStopPoint;
  final List<String>? groupedStopIds;
  final VoidCallback? onCloseRequested;
  final void Function(String stopName, LatLng stopPoint, [String? stopId])? onPlanRouteToStop;
  final bool closeAfterOpenTripRequest;

  const StopDetailsScreen({
    super.key,
    required this.stopId,
    this.initialStopName,
    this.initialStopPoint,
    this.groupedStopIds,
    this.onCloseRequested,
    this.onPlanRouteToStop,
    this.closeAfterOpenTripRequest = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = LayoutProvider.isDesktop(context, breakpoint: 600);
    final content = SafeArea(
      child: StopDetailsView(
        stopId: stopId,
        initialStopName: initialStopName,
        initialStopPoint: initialStopPoint,
        onCloseRequested: onCloseRequested,
        onPlanRouteToStop: onPlanRouteToStop,
      ),
    );

    return isDesktop
        ? DesktopSidebarWrapper(child: content)
        : Scaffold(body: content);
  }
}

class StopDetailsView extends StatefulWidget {
  final String stopId;
  final String? initialStopName;
  final LatLng? initialStopPoint;
  final VoidCallback? onCloseRequested;
  final void Function(String stopName, LatLng stopPoint, [String? stopId])? onPlanRouteToStop;

  const StopDetailsView({
    super.key,
    required this.stopId,
    this.initialStopName,
    this.initialStopPoint,
    this.onCloseRequested,
    this.onPlanRouteToStop,
  });

  @override
  State<StopDetailsView> createState() => _StopDetailsViewState();
}

class _StopDetailsViewState extends State<StopDetailsView> with RouteAware {
  static const String _spanFontFamily = 'MNR2007';
  static const double _spanFontScale = 28 / 16;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      AppRouter.routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (mounted) {
      context.read<StopDetailsCubit>().forceRefreshMap();
    }
  }

  @override
  void didPushNext() {
    if (mounted) {
      context.read<StopDetailsCubit>().clearMapHighlight();
    }
  }



  void _updateUrl(BuildContext context, {
    DateTime? newDate,
    bool? newPast,
    Set<String>? newLines,
  }) {
    final state = GoRouterState.of(context);
    final currentQuery = Map<String, dynamic>.from(state.uri.queryParameters);
    
    if (newDate != null) {
      currentQuery['date'] = '${newDate.year.toString().padLeft(4, '0')}-${newDate.month.toString().padLeft(2, '0')}-${newDate.day.toString().padLeft(2, '0')}';
    }
    
    if (newPast != null) {
      if (newPast) {
        currentQuery['past'] = 'true';
      } else {
        currentQuery.remove('past');
      }
    }
    
    if (newLines != null) {
      if (newLines.isEmpty) {
        currentQuery.remove('lines');
      } else {
        currentQuery['lines'] = newLines.join(',');
      }
    }
    
    final uri = state.uri.replace(queryParameters: currentQuery.isEmpty ? null : currentQuery);
    context.go(uri.toString());
  }

  Future<void> _pickDate(BuildContext context, DateTime selectedDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }

    final normalized = DateTime.utc(picked.year, picked.month, picked.day);
    if (_isSameDate(selectedDate, normalized)) {
      return;
    }

    _updateUrl(context, newDate: normalized, newPast: false);
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isOnSelectedDate(Map<String, dynamic> departure, DateTime selectedDate) {
    final occurrence = StopDetailsUtils.resolveDepartureInstant(
      serviceDay: StopDetailsUtils.asNum(departure['serviceDay']),
      secondsOfDay: StopDetailsUtils.eventSecondsOfDay(departure),
    );
    if (occurrence == null) {
      return false;
    }
    final occurrenceBudapest = StopDetailsUtils.toBudapestTime(occurrence);
    return occurrenceBudapest.year == selectedDate.year &&
        occurrenceBudapest.month == selectedDate.month &&
        occurrenceBudapest.day == selectedDate.day;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StopDetailsCubit, StopDetailsState>(
      listener: (context, state) {
        if (state is StopDetailsLoaded && state.refreshError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppTexts.stopErrorUpdate(state.refreshError!))),
          );
        }
      },
      builder: (context, state) {
        String stopName = widget.initialStopName?.trim().isNotEmpty == true
            ? widget.initialStopName!.trim()
            : AppTexts.stopDetailsLabel;
        bool stopNameUsesSpanFont = false;

        if (state is StopDetailsLoaded) {
          final rawStopName = state.stop['name']?.toString().trim().isNotEmpty == true
              ? state.stop['name'].toString()
              : stopName;
          stopName = StopDetailsUtils.plainText(rawStopName);
          stopNameUsesSpanFont = StopDetailsUtils.containsSpanMarkup(rawStopName);
        }

        final isRefreshing = state is StopDetailsLoaded && state.isRefreshing;

        return Column(
          children: [
            ScreenHeader(
              title: Text(
                stopName,
                style: TextStyle(
                  fontFamily: stopNameUsesSpanFont ? _spanFontFamily : null,
                  fontSize: stopNameUsesSpanFont ? 20 * _spanFontScale : null,
                  leadingDistribution: stopNameUsesSpanFont ? TextLeadingDistribution.even : null,
                ),
              ),
              onBack: () {
                if (widget.onCloseRequested != null) {
                  widget.onCloseRequested!();
                } else if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/');
                }
              },
              actions: [
                if (widget.onPlanRouteToStop != null)
                  IconButton(
                    icon: const Icon(Icons.directions),
                    tooltip: AppTexts.isHungarian ? 'Útvonaltervezés ide' : 'Plan route here',
                    onPressed: () {
                      final lat = state is StopDetailsLoaded
                          ? StopDetailsUtils.asNum(state.stop['lat'])?.toDouble()
                          : null;
                      final lon = state is StopDetailsLoaded
                          ? StopDetailsUtils.asNum(state.stop['lon'])?.toDouble()
                          : null;
                      final finalLat = lat ?? widget.initialStopPoint?.latitude;
                      final finalLon = lon ?? widget.initialStopPoint?.longitude;

                      if (finalLat != null && finalLon != null) {
                        widget.onPlanRouteToStop!(
                          stopName,
                          LatLng(finalLat, finalLon),
                          widget.stopId,
                        );
                        if (widget.onCloseRequested == null && Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
                  ),
                if (isRefreshing)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
              ],
            ),
            Flexible(
              child: _buildBody(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, StopDetailsState state) {
    if (state is StopDetailsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is StopDetailsError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.message, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (state is StopDetailsLoaded) {
      final stop = state.stop;
      final now = DateTime.now();
      final isTodayView = StopDetailsUtils.isSameBudapestDay(state.selectedDate, now);
      
      final allDepartures = StopDetailsUtils.departures(stop).where((d) => _isOnSelectedDate(d, state.selectedDate));
      final departures = (state.selectedLines.isEmpty
          ? allDepartures
          : allDepartures.where((d) {
              final trip = d['trip'];
              final route = trip is Map ? trip['route'] : null;
              final rawRouteShortName =
                  route is Map ? (route['shortName']?.toString() ?? '-') : '-';
              final routeShortName = StopDetailsUtils.plainText(rawRouteShortName);
              return state.selectedLines.contains(routeShortName);
            })).toList();
            
      final hasPast = isTodayView &&
          departures.any((d) => StopDetailsUtils.isPastDeparture(d, now));
      final arrivals = departures.where(StopDetailsUtils.isArrivalEntry).toList();
      final departuresOnly =
          departures.where(StopDetailsUtils.isDepartureEntry).toList();
      final hidePastInToday = isTodayView && !state.showPastDepartures;
      
      final visibleArrivals = hidePastInToday
          ? arrivals
              .where((d) => !StopDetailsUtils.isPastDeparture(d, now))
              .toList()
          : arrivals;
      final visibleDepartures = hidePastInToday
          ? departuresOnly
              .where((d) => !StopDetailsUtils.isPastDeparture(d, now))
              .toList()
          : departuresOnly;

      final isMobile = MediaQuery.of(context).size.width <= StopDetailsScreen.desktopBreakpoint;

      if (isMobile) {
        return StopDetailsMobileSheet(
          stop: stop,
          initialStopPoint: widget.initialStopPoint,
          initialStopName: widget.initialStopName,
          now: now,
          hasPast: hasPast,
          visibleArrivals: visibleArrivals,
          visibleDepartures: visibleDepartures,
          selectedDate: state.selectedDate,
          showPastDepartures: state.showPastDepartures,
          selectedLines: state.selectedLines,
          uniqueLines: state.uniqueLines,
          onLineSelected: (line, selected) {
            final newLines = Set<String>.from(state.selectedLines);
            if (selected) {
              newLines.add(line);
            } else {
              newLines.remove(line);
            }
            _updateUrl(context, newLines: newLines);
          },
          onClearLineSelection: () {
            _updateUrl(context, newLines: {});
          },
          onPickDate: () => _pickDate(context, state.selectedDate),
          onTogglePastDepartures: () {
            _updateUrl(context, newPast: !state.showPastDepartures);
          },
          onStepSelectedDate: (dayDelta) {
            final stepped = state.selectedDate.add(Duration(days: dayDelta));
            _updateUrl(context, newDate: stepped, newPast: false);
          },
          onGoToToday: () {
            _updateUrl(context, newDate: StopDetailsUtils.budapestToday(), newPast: false);
          },
          onOpenTripDetails: ({required tripId, required serviceDay}) {
            if (widget.onCloseRequested == null && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            final encodedTripId = Uri.encodeComponent(tripId);
            context.push('/trip/$encodedTripId?date=$serviceDay');
          },
        );
      }

      return StopDetailsTabs(
        now: now,
        hasPast: hasPast,
        visibleArrivals: visibleArrivals,
        visibleDepartures: visibleDepartures,
        selectedDate: state.selectedDate,
        showPastDepartures: state.showPastDepartures,
        stop: stop,
        selectedLines: state.selectedLines,
        uniqueLines: state.uniqueLines,
        onLineSelected: (line, selected) {
          final newLines = Set<String>.from(state.selectedLines);
          if (selected) {
            newLines.add(line);
          } else {
            newLines.remove(line);
          }
          _updateUrl(context, newLines: newLines);
        },
        onClearLineSelection: () {
          _updateUrl(context, newLines: {});
        },
        onPickDate: () => _pickDate(context, state.selectedDate),
        onTogglePastDepartures: () {
          _updateUrl(context, newPast: !state.showPastDepartures);
        },
        onStepSelectedDate: (dayDelta) {
          final stepped = state.selectedDate.add(Duration(days: dayDelta));
          _updateUrl(context, newDate: stepped, newPast: false);
        },
        onGoToToday: () {
          _updateUrl(context, newDate: StopDetailsUtils.budapestToday(), newPast: false);
        },
        onOpenTripDetails: ({required tripId, required serviceDay}) {
          if (widget.onCloseRequested == null && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          final encodedTripId = Uri.encodeComponent(tripId);
          context.push('/trip/$encodedTripId?date=$serviceDay');
        },
      );
    }
    
    return const SizedBox.shrink();
  }
}
