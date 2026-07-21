import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../controllers/route_details_cubit.dart';
import '../../widgets/layout/screen_header.dart';
import 'package:terka/theme/app_texts.dart';
import '../../utils/stop_details_utils.dart';
import '../../utils/trip_details_utils.dart';
import '../../widgets/line_badge.dart';
import 'widgets/route_trip_card.dart';
import '../../widgets/layout/desktop_sidebar_wrapper.dart';
import '../../utils/layout_provider.dart';
import 'widgets/route_details_mobile_sheet.dart';
import 'package:terka/theme/app_tokens.dart';

class RouteDetailsScreen extends StatelessWidget {
  final String routeId;
  final VoidCallback? onCloseRequested;
  final void Function(String tripId, String serviceDay)? onOpenTripDetailsRequested;

  const RouteDetailsScreen({
    super.key,
    required this.routeId,
    this.onCloseRequested,
    this.onOpenTripDetailsRequested,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = LayoutProvider.isDesktop(context, breakpoint: 600);
    final content = SafeArea(
      child: RouteDetailsView(
        routeId: routeId,
        onCloseRequested: onCloseRequested,
        onOpenTripDetailsRequested: onOpenTripDetailsRequested,
      ),
    );

    return isDesktop
        ? DesktopSidebarWrapper(child: content)
        : Scaffold(body: content);
  }
}

class RouteDetailsView extends StatefulWidget {
  final String routeId;
  final VoidCallback? onCloseRequested;
  final void Function(String tripId, String serviceDay)? onOpenTripDetailsRequested;

  const RouteDetailsView({
    super.key,
    required this.routeId,
    this.onCloseRequested,
    this.onOpenTripDetailsRequested,
  });

  @override
  State<RouteDetailsView> createState() => _RouteDetailsViewState();
}

class _RouteDetailsViewState extends State<RouteDetailsView> with RouteAware {
  static const double _desktopBreakpoint = 600;

  bool _useMobileMapSheet(BuildContext context) {
    return !LayoutProvider.isDesktop(context, breakpoint: _desktopBreakpoint);
  }

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
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          context.read<RouteDetailsCubit>().forceRefreshMap();
        }
      });
    }
  }

  String _formatDateForActiveDates(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy$mm$dd';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final todayDateString = _formatDateForActiveDates(StopDetailsUtils.budapestToday());

    return BlocConsumer<RouteDetailsCubit, RouteDetailsState>(
      listener: (context, state) {
        if (state is RouteDetailsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppTexts.routeNotFound(widget.routeId))),
          );
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/');
          }
        }
      },
      builder: (context, state) {
        Widget headerTitleWidget = Text(AppTexts.routeDetailsTitle);
        if (state is RouteDetailsLoaded) {
          final shortName = state.routeData['shortName']?.toString();
          final longName = state.routeData['longName']?.toString();
          
          if (shortName != null && shortName.isNotEmpty) {
            final colorHex = state.routeData['color']?.toString() ?? '0A84FF';
            final textColorHex = state.routeData['textColor']?.toString() ?? 'FFFFFF';
            final plainShortName = TripDetailsUtils.plainText(shortName).trim();
            final useSpanFont = TripDetailsUtils.containsSpanMarkup(shortName);
            
            final badge = LineBadge(
              lineLabel: plainShortName,
              routeColor: StopDetailsUtils.hexColor(colorHex),
              routeTextColor: StopDetailsUtils.hexColor(textColorHex),
              useSpanFont: useSpanFont,
            );
            
            if (longName != null && longName.isNotEmpty) {
              final plainLongName = TripDetailsUtils.plainText(longName).trim();
              headerTitleWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  badge,
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      plainLongName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            } else {
              headerTitleWidget = badge;
            }
          } else if (longName != null && longName.isNotEmpty) {
            headerTitleWidget = Text(TripDetailsUtils.plainText(longName).trim());
          }
        }

        final useMobileSheet = _useMobileMapSheet(context);
        if (useMobileSheet) {
          headerTitleWidget = Text(AppTexts.routeDetailsTitle);
        }

        return Column(
          children: [
            ScreenHeader(
              title: headerTitleWidget,
              onBack: widget.onCloseRequested ?? () => Navigator.of(context).pop(),
            ),
            Flexible(
              child: state is RouteDetailsLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state is RouteDetailsError
                      ? const SizedBox.shrink()
                      : state is RouteDetailsLoaded
                          ? useMobileSheet
                              ? RouteDetailsMobileSheet(
                                  routeData: state.routeData,
                                  todayDateString: todayDateString,
                                  onOpenTripDetailsRequested: widget.onOpenTripDetailsRequested ?? (tripId, serviceDay) {
                                    final encodedTripId = Uri.encodeComponent(tripId);
                                    if (serviceDay.isNotEmpty) {
                                      context.push('/trip/$encodedTripId?date=$serviceDay');
                                    } else {
                                      context.push('/trip/$encodedTripId');
                                    }
                                  },
                                )
                              : _buildContent(context, state.routeData, todayDateString)
                          : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> routeData, String todayDateString) {
    final patterns = routeData['patterns'];
    if (patterns is! List || patterns.isEmpty) {
      return Center(
        child: Text(AppTexts.noData),
      );
    }

    final allTrips = <Map<String, dynamic>>[];
    for (final pattern in patterns) {
      if (pattern is Map) {
        final trips = pattern['trips'];
        if (trips is List) {
          allTrips.addAll(trips.whereType<Map<String, dynamic>>());
        }
      }
    }

    if (allTrips.isEmpty) {
      return Center(
        child: Text(AppTexts.noData),
      );
    }

    // Sort trips: first the ones running today, then the rest.
    allTrips.sort((a, b) {
      final aActive = (a['activeDates'] as List?)?.contains(todayDateString) ?? false;
      final bActive = (b['activeDates'] as List?)?.contains(todayDateString) ?? false;
      if (aActive && !bActive) return -1;
      if (!aActive && bActive) return 1;

      final aName = a['tripShortName']?.toString() ?? a['tripHeadsign']?.toString() ?? '';
      final bName = b['tripShortName']?.toString() ?? b['tripHeadsign']?.toString() ?? '';
      return aName.compareTo(bName);
    });

    return ListView.builder(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xl),
      itemCount: allTrips.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final trip = allTrips[index];
        final activeDates = trip['activeDates'] as List?;
        final runsToday = activeDates?.contains(todayDateString) ?? false;

        return RouteTripCard(
          trip: trip,
          runsToday: runsToday,
          onTap: () {
            final tripId = trip['gtfsId']?.toString();
            if (tripId == null) return;

            final serviceDay = runsToday ? todayDateString : (activeDates?.isNotEmpty == true ? activeDates!.first.toString() : '');
            
            if (widget.onOpenTripDetailsRequested != null) {
              widget.onOpenTripDetailsRequested!(tripId, serviceDay);
            } else {
              final encodedTripId = Uri.encodeComponent(tripId);
              if (serviceDay.isNotEmpty) {
                context.push('/trip/$encodedTripId?date=$serviceDay');
              } else {
                context.push('/trip/$encodedTripId');
              }
            }
          },
        );
      },
    );
  }
}
