import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../widgets/layout/desktop_sidebar_wrapper.dart';
import '../../controllers/trip_details_cubit.dart';
import 'widgets/trip_details_mobile_sheet.dart';
import '../../theme/app_texts.dart';
import '../../utils/layout_provider.dart';
import 'widgets/trip_details_table_view.dart';
import 'widgets/trip_details_stop_card.dart';

class TripDetailsScreen extends StatelessWidget {
  final String tripId;
  final String serviceDay;
  final VoidCallback? onCloseRequested;
  final void Function(String stopId, String stopName)? onOpenStopDetailsRequested;

  const TripDetailsScreen({
    super.key,
    required this.tripId,
    required this.serviceDay,
    this.onCloseRequested,
    this.onOpenStopDetailsRequested,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = LayoutProvider.isDesktop(context, breakpoint: 600);
    final content = SafeArea(
      bottom: false,
      child: TripDetailsView(
        tripId: tripId,
        serviceDay: serviceDay,
        onCloseRequested: onCloseRequested,
        onOpenStopDetailsRequested: onOpenStopDetailsRequested,
      ),
    );

    return isDesktop
        ? DesktopSidebarWrapper(child: content)
        : Scaffold(body: content);
  }
}

class TripDetailsView extends StatefulWidget {
  final String tripId;
  final String serviceDay;
  final VoidCallback? onCloseRequested;
  final void Function(String stopId, String stopName)? onOpenStopDetailsRequested;

  const TripDetailsView({
    super.key,
    required this.tripId,
    required this.serviceDay,
    this.onCloseRequested,
    this.onOpenStopDetailsRequested,
  });

  @override
  State<TripDetailsView> createState() => _TripDetailsViewState();
}

class _TripDetailsViewState extends State<TripDetailsView> with RouteAware {
  static const double _desktopBreakpoint = 600;

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
          context.read<TripDetailsCubit>().forceRefreshMap();
        }
      });
    }
  }

  bool _useMobileMapSheet(BuildContext context) {
    return !LayoutProvider.isDesktop(context, breakpoint: _desktopBreakpoint);
  }

  void _openStopDetails(BuildContext context, {
    required String stopId,
    required String stopName,
    LatLng? initialStopPoint,
  }) {
    if (widget.onOpenStopDetailsRequested != null) {
      widget.onOpenStopDetailsRequested!(stopId, stopName);
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      final encodedStopId = Uri.encodeComponent(stopId);
      context.push('/stop/$encodedStopId');
    }
  }

  Widget _buildHeader(BuildContext context, bool isRefreshing) {
    final title = AppTexts.tripDetails;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (widget.onCloseRequested != null) {
                widget.onCloseRequested!();
              } else {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/');
                }
              }
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          if (isRefreshing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<TripDetailsCubit, TripDetailsState>(
          builder: (context, state) {
            final isRefreshing = state is TripDetailsLoaded && state.isRefreshing;
            return _buildHeader(context, isRefreshing);
          },
        ),
        Flexible(
          child: _buildBody(context),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocConsumer<TripDetailsCubit, TripDetailsState>(
      listener: (context, state) {
        if (state is TripDetailsLoaded && state.refreshError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppTexts.stopErrorUpdate(state.refreshError!))),
          );
        }
      },
      builder: (context, state) {
        if (state is TripDetailsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TripDetailsError) {
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

        if (state is TripDetailsLoaded) {
          final trip = state.trip;
          if (_useMobileMapSheet(context)) {
            return TripDetailsMobileSheet(
              trip: trip,
              tripId: widget.tripId,
              serviceDay: widget.serviceDay,
              onStopTap: ({
                required stopId,
                required stopName,
                required initialStopPoint,
              }) {
                _openStopDetails(
                  context,
                  stopId: stopId,
                  stopName: stopName,
                  initialStopPoint: initialStopPoint,
                );
              },
              stopInfoCardBuilder: (context, stop) => TripDetailsStopCard(
                stop: stop,
                onOpenStopDetails: ({
                  required stopId,
                  required stopName,
                  required initialStopPoint,
                }) {
                  _openStopDetails(
                    context,
                    stopId: stopId,
                    stopName: stopName,
                    initialStopPoint: initialStopPoint,
                  );
                },
              ),
            );
          }

          return TripDetailsTableView(
            trip: trip,
            serviceDay: widget.serviceDay,
            onStopTap: ({
              required stopId,
              required stopName,
              required initialStopPoint,
            }) {
              _openStopDetails(
                context,
                stopId: stopId,
                stopName: stopName,
                initialStopPoint: initialStopPoint,
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
