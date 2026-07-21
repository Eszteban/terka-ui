import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../controllers/route_planner_cubit.dart';
import '../../controllers/map_cubit.dart';
import 'package:terka/theme/app_tokens.dart';
import 'package:terka/theme/app_texts.dart';
import '../../widgets/maps/map_view.dart';
import '../../widgets/navigation/top_navbar.dart';
import '../../widgets/forms/autocomplete_search_field.dart';
import '../../injection_container.dart';
import '../../utils/layout_provider.dart';
import 'widgets/main_desktop_map_layout.dart';
import 'general_search_screen.dart';

class MainScreen extends StatefulWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final RoutePlannerCubit _routePlannerCubit;
  late final MapCubit _mapCubit;

  @override
  void initState() {
    super.initState();
    _routePlannerCubit = sl<RoutePlannerCubit>();
    _mapCubit = sl<MapCubit>();
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/news')) return 1;
    if (location.startsWith('/map')) return 2;
    if (location.startsWith('/profile') ||
        location.startsWith('/tickets') ||
        location.startsWith('/pass-types') ||
        location.startsWith('/about'))
      return 3;
    return 0; // default to Home
  }

  int _currentDesktopTabIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/map')) return -1;
    if (location.startsWith('/news')) return 1;
    if (location.startsWith('/profile') ||
        location.startsWith('/tickets') ||
        location.startsWith('/pass-types') ||
        location.startsWith('/about'))
      return 2;
    return 0;
  }

  String _currentMobileSectionTitle(BuildContext context) {
    final idx = _calculateSelectedIndex(context);
    switch (idx) {
      case 0:
        return AppTexts.mainRoutePlanning;
      case 1:
        return AppTexts.mainMavNews;
      case 2:
        return AppTexts.mainMap;
      case 3:
        return AppTexts.mainProfile;
      default:
        return AppTexts.mainRoutePlanning;
    }
  }

  void _onGeneralSearchSuggestionSelected(
    SuggestionEntry suggestion,
    BuildContext context,
  ) {
    if (suggestion.type == SuggestionType.route && suggestion.rawData != null) {
      final routeId = suggestion.rawData!['gtfsId']?.toString();
      if (routeId != null) {
        context.go('/route/$routeId');
      } else {
        context.go('/');
      }
      return;
    }

    if (suggestion.type == SuggestionType.stop && suggestion.id != null) {
      _mapCubit.setSearchHighlight(
        LatLng(suggestion.coordinates![1], suggestion.coordinates![0]),
        suggestion.name,
      );
      final encodedStopId = Uri.encodeComponent(suggestion.id!);
      context.push('/stop/$encodedStopId');
      return;
    }

    if (suggestion.coordinates != null && suggestion.coordinates!.length == 2) {
      _mapCubit.setSearchHighlight(
        LatLng(suggestion.coordinates![1], suggestion.coordinates![0]),
        suggestion.name,
      );
      final isDesktop = LayoutProvider.isDesktop(context);
      if (!isDesktop) {
        context.go('/map');
      } else {
        context.go('/');
      }
    }
  }

  void _planRouteToDestination(
    String name,
    LatLng coordinates, [
    String? stopId,
  ]) async {
    // For map markers routing shortcut
    final queryParams = <String, String>{};
    final destinationToken = stopId == null
        ? '$name::${coordinates.latitude},${coordinates.longitude}'
        : '$name::$stopId';

    queryParams['to'] = destinationToken;
    queryParams['toCoords'] =
        '${coordinates.longitude},${coordinates.latitude}';

    bool hasLocation = false;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          final position =
              await Geolocator.getLastKnownPosition() ??
              await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.high,
                  timeLimit: Duration(seconds: 2),
                ),
              );
          final locName = AppTexts.isHungarian
              ? 'Jelenlegi helyzet'
              : 'Current location';
          queryParams['from'] =
              '$locName::${position.latitude},${position.longitude}';
          queryParams['fromCoords'] =
              '${position.longitude},${position.latitude}';
          hasLocation = true;
        }
      }
    } catch (_) {}

    if (!mounted) return;

    context.go(Uri(path: '/', queryParameters: queryParams).toString());
  }

  void _planRouteFromMap(String name, LatLng coordinates, bool isDestination) {
    final queryParams = Map<String, String>.from(
      GoRouterState.of(context).uri.queryParameters,
    );
    final token = '$name::${coordinates.latitude},${coordinates.longitude}';
    final coordsStr = '${coordinates.longitude},${coordinates.latitude}';

    if (isDestination) {
      queryParams['to'] = token;
      queryParams['toCoords'] = coordsStr;
    } else {
      queryParams['from'] = token;
      queryParams['fromCoords'] = coordsStr;
    }

    if (!mounted) return;
    context.go(Uri(path: '/', queryParameters: queryParams).toString());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RoutePlannerCubit>.value(value: _routePlannerCubit),
        BlocProvider<MapCubit>.value(value: _mapCubit),
      ],
      child: BlocBuilder<MapCubit, MapState>(
        builder: (context, mapState) {
          return NativeDeviceOrientationReader(
            builder: (context) {
              final orientation = NativeDeviceOrientationReader.orientation(
                context,
              );
              final isDesktop = LayoutProvider.isDesktop(context);
              final location = GoRouterState.of(context).uri.path;
              final isMapFullscreen = location == '/map';
              final showMobileTopNavbar =
                  location != '/map' &&
                  !location.startsWith('/plan') &&
                  !location.startsWith('/stop/') &&
                  !location.startsWith('/route/') &&
                  !location.startsWith('/routes/') &&
                  !location.startsWith('/trip/') &&
                  !location.startsWith('/about') &&
                  !location.startsWith('/tickets') &&
                  !location.startsWith('/pass-types');
              final useDesktopMapLayout = isDesktop;
              final colorScheme = Theme.of(context).colorScheme;
              final isDark = Theme.of(context).brightness == Brightness.dark;

              final isPhoneLandscape =
                  !isDesktop &&
                  (orientation == NativeDeviceOrientation.landscapeLeft ||
                      orientation == NativeDeviceOrientation.landscapeRight);

              return Scaffold(
                body: isDesktop
                    ? Stack(
                        children: [
                          Positioned.fill(
                            child: TerkaTabletLayout(
                              showMap: isMapFullscreen,
                              desktopRouteOverlayData:
                                  mapState.routeOverlayData,
                              desktopRouteVehicleMarker:
                                  mapState.routeVehicleMarker,
                              desktopSelectedMapPayload:
                                  mapState.selectedMapPayload,
                              sidebarContent: widget.child,
                              onClearDesktopRouteSelection:
                                  _mapCubit.clearDesktopRouteSelection,
                              onOpenTripDetailsRequested: (tripId, serviceDay) {
                                final encodedTripId = Uri.encodeComponent(
                                  tripId,
                                );
                                if (serviceDay.isNotEmpty) {
                                  context.push(
                                    '/trip/$encodedTripId?date=$serviceDay',
                                  );
                                } else {
                                  context.push('/trip/$encodedTripId');
                                }
                              },
                              onOpenStopDetailsRequested:
                                  (
                                    stopId,
                                    stopName,
                                    initialStopPoint,
                                    groupedStopIds,
                                  ) async {
                                    await context.push(
                                      '/stop/${Uri.encodeComponent(stopId)}',
                                    );
                                  },
                              desktopSelectedRouteColor:
                                  mapState.selectedRouteColor,
                              desktopSelectedRouteTextColor:
                                  mapState.selectedRouteTextColor,
                              desktopSelectedRouteName:
                                  mapState.selectedRouteName,
                              hideGeneralStopsAndVehicles:
                                  location.startsWith('/trip/') ||
                                  location.startsWith('/stop/') ||
                                  (mapState.selectedMapPayload != null &&
                                      mapState.selectedRouteName == null),
                              searchHighlightPoint:
                                  mapState.searchHighlightPoint,
                              searchHighlightName: mapState.searchHighlightName,
                              stopHighlightPoint: mapState.stopHighlightPoint,
                              onPlanRouteToStop: _planRouteToDestination,
                              onPlanRouteFromMap: _planRouteFromMap,
                              onSearchSuggestionSelected: (suggestion) {
                                _onGeneralSearchSuggestionSelected(
                                  suggestion,
                                  context,
                                );
                              },
                            ),
                          ),
                          TopNavbar(
                            isDesktop: isDesktop,
                            onHomeTap: () {
                              _mapCubit.clearDesktopRouteSelection();
                              context.go('/');
                            },
                            onNewsTap: () {
                              _mapCubit.clearDesktopRouteSelection();
                              context.go('/news');
                            },
                            onProfileTap: () {
                              _mapCubit.clearDesktopRouteSelection();
                              context.go('/profile');
                            },
                            selectedDesktopTabIndex: _currentDesktopTabIndex(
                              context,
                            ),
                            mobileCurrentSectionTitle:
                                _currentMobileSectionTitle(context),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          if (!isPhoneLandscape && showMobileTopNavbar)
                            TopNavbar(
                              isDesktop: isDesktop,
                              onHomeTap: () => context.go('/'),
                              onNewsTap: () => context.go('/news'),
                              onProfileTap: () => context.go('/profile'),
                              mobileCurrentSectionTitle:
                                  _currentMobileSectionTitle(context),
                            ),
                          Expanded(
                            child: useDesktopMapLayout
                                ? const SizedBox.shrink()
                                : Row(
                                    children: [
                                      if (isPhoneLandscape &&
                                          orientation ==
                                              NativeDeviceOrientation
                                                  .landscapeRight)
                                        _buildRotatedNavBar(
                                          context,
                                          orientation,
                                        ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            if (isPhoneLandscape &&
                                                showMobileTopNavbar)
                                              TopNavbar(
                                                isDesktop: isDesktop,
                                                onHomeTap: () {
                                                  _mapCubit.clearDesktopRouteSelection();
                                                  context.go('/');
                                                },
                                                onNewsTap: () {
                                                  _mapCubit.clearDesktopRouteSelection();
                                                  context.go('/news');
                                                },
                                                onProfileTap: () {
                                                  _mapCubit.clearDesktopRouteSelection();
                                                  context.go('/profile');
                                                },
                                                mobileCurrentSectionTitle:
                                                    _currentMobileSectionTitle(
                                                      context,
                                                    ),
                                              ),
                                            Expanded(
                                              child: isMapFullscreen
                                                  ? Stack(
                                                      children: [
                                                        Positioned.fill(
                                                          child: MapView(
                                                            controlsBottomInset:
                                                                (mapState.searchHighlightPoint !=
                                                                        null ||
                                                                    mapState.selectedRouteName !=
                                                                        null)
                                                                ? 156.0
                                                                : 88.0,
                                                            routeOverlayData:
                                                                mapState
                                                                    .routeOverlayData,
                                                            routeVehicleMarker:
                                                                mapState
                                                                    .routeVehicleMarker,
                                                            onOpenTripDetailsRequested:
                                                                (
                                                                  tripId,
                                                                  serviceDay,
                                                                ) {
                                                                  final encodedTripId =
                                                                      Uri.encodeComponent(
                                                                        tripId,
                                                                      );
                                                                  if (serviceDay
                                                                      .isNotEmpty) {
                                                                    context.push(
                                                                      '/trip/$encodedTripId?date=$serviceDay',
                                                                    );
                                                                  } else {
                                                                    context.push(
                                                                      '/trip/$encodedTripId',
                                                                    );
                                                                  }
                                                                },
                                                            onOpenStopDetailsRequested:
                                                                (
                                                                  stopId,
                                                                  stopName,
                                                                  initialStopPoint,
                                                                  groupedStopIds,
                                                                ) async {
                                                                  await context
                                                                      .push(
                                                                        '/stop/${Uri.encodeComponent(stopId)}',
                                                                      );
                                                                },
                                                            hideGeneralStopsAndVehicles:
                                                                (location
                                                                    .startsWith(
                                                                      '/trip/',
                                                                    ) ||
                                                                location
                                                                    .startsWith(
                                                                      '/stop/',
                                                                    ) ||
                                                                (mapState.selectedMapPayload !=
                                                                        null &&
                                                                    mapState.selectedRouteName ==
                                                                        null)),
                                                            searchHighlightPoint:
                                                                mapState
                                                                    .searchHighlightPoint,
                                                            onPlanRouteToStop:
                                                                _planRouteToDestination,
                                                            onPlanRouteFromMap:
                                                                _planRouteFromMap,
                                                            selectedRouteName:
                                                                mapState
                                                                    .selectedRouteName,
                                                          ),
                                                        ),
                                                        if (mapState.searchHighlightPoint !=
                                                                null &&
                                                            mapState.searchHighlightName !=
                                                                null)
                                                          Positioned(
                                                            left: 16,
                                                            right: 16,
                                                            bottom: 88,
                                                            child: Card(
                                                              elevation: 6,
                                                              shadowColor: Colors
                                                                  .black
                                                                  .withValues(
                                                                    alpha: 0.15,
                                                                  ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      16,
                                                                    ),
                                                                side: BorderSide(
                                                                  color: colorScheme
                                                                      .outlineVariant
                                                                      .withValues(
                                                                        alpha:
                                                                            isDark
                                                                            ? 0.3
                                                                            : 0.4,
                                                                      ),
                                                                ),
                                                              ),
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          AppSpacing.lg,
                                                                      vertical:
                                                                          AppSpacing.sm,
                                                                    ),
                                                                child: Row(
                                                                  children: [
                                                                    Container(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                            8,
                                                                          ),
                                                                      decoration: BoxDecoration(
                                                                        color: colorScheme
                                                                            .primary
                                                                            .withValues(
                                                                              alpha: 0.1,
                                                                            ),
                                                                        shape: BoxShape
                                                                            .circle,
                                                                      ),
                                                                      child: Icon(
                                                                        Icons
                                                                            .place,
                                                                        color: colorScheme
                                                                            .primary,
                                                                        size:
                                                                            20,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 12,
                                                                    ),
                                                                    Expanded(
                                                                      child: Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          Text(
                                                                            mapState.searchHighlightName!,
                                                                            style: const TextStyle(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 14,
                                                                            ),
                                                                            maxLines:
                                                                                1,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                          ),
                                                                          Text(
                                                                            AppTexts.isHungarian
                                                                                ? 'Kiválasztott hely'
                                                                                : 'Selected location',
                                                                            style: TextStyle(
                                                                              fontSize: 12,
                                                                              color: colorScheme.onSurfaceVariant.withValues(
                                                                                alpha: 0.7,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    IconButton(
                                                                      icon: Icon(
                                                                        Icons
                                                                            .directions,
                                                                        color: colorScheme
                                                                            .primary,
                                                                      ),
                                                                      onPressed: () {
                                                                        _planRouteToDestination(
                                                                          mapState
                                                                              .searchHighlightName!,
                                                                          mapState
                                                                              .searchHighlightPoint!,
                                                                        );
                                                                      },
                                                                      tooltip:
                                                                          AppTexts
                                                                              .isHungarian
                                                                          ? 'Útvonaltervezés ide'
                                                                          : 'Plan route here',
                                                                    ),
                                                                    IconButton(
                                                                      icon: const Icon(
                                                                        Icons
                                                                            .close,
                                                                      ),
                                                                      onPressed: () {
                                                                        _mapCubit
                                                                            .clearSearchHighlight();
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),

                                                        Positioned(
                                                          left: 16,
                                                          right: 16,
                                                          bottom: 16,
                                                          child: GestureDetector(
                                                            onTap: () async {
                                                              final suggestion =
                                                                  await Navigator.of(
                                                                    context,
                                                                  ).push<
                                                                    SuggestionEntry
                                                                  >(
                                                                    MaterialPageRoute(
                                                                      builder:
                                                                          (_) =>
                                                                              const GeneralSearchScreen(),
                                                                    ),
                                                                  );
                                                              if (suggestion !=
                                                                      null &&
                                                                  context
                                                                      .mounted) {
                                                                _onGeneralSearchSuggestionSelected(
                                                                  suggestion,
                                                                  context,
                                                                );
                                                              }
                                                            },
                                                            child: Card(
                                                              elevation: 6,
                                                              shadowColor: Colors
                                                                  .black
                                                                  .withValues(
                                                                    alpha: 0.15,
                                                                  ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      24,
                                                                    ),
                                                                side: BorderSide(
                                                                  color: colorScheme
                                                                      .outlineVariant
                                                                      .withValues(
                                                                        alpha:
                                                                            isDark
                                                                            ? 0.3
                                                                            : 0.4,
                                                                      ),
                                                                ),
                                                              ),
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          AppSpacing.lg,
                                                                      vertical:
                                                                          AppSpacing.md,
                                                                    ),
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .search,
                                                                      color: colorScheme
                                                                          .primary,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 12,
                                                                    ),
                                                                    Expanded(
                                                                      child: Text(
                                                                        AppTexts.isHungarian
                                                                            ? 'Hova utazol?'
                                                                            : 'Where to?',
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              16,
                                                                          color: colorScheme.onSurfaceVariant.withValues(
                                                                            alpha:
                                                                                0.7,
                                                                          ),
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Icon(
                                                                      Icons
                                                                          .tune,
                                                                      color: colorScheme
                                                                          .primary,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : widget.child,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isPhoneLandscape &&
                                          orientation ==
                                              NativeDeviceOrientation
                                                  .landscapeLeft)
                                        _buildRotatedNavBar(
                                          context,
                                          orientation,
                                        ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                bottomNavigationBar: isDesktop || isPhoneLandscape
                    ? null
                    : SafeArea(
                        top: false,
                        child: NavigationBar(
                          selectedIndex: _calculateSelectedIndex(context),
                          onDestinationSelected: (index) {
                            switch (index) {
                              case 0:
                                _mapCubit.clearDesktopRouteSelection();
                                context.go('/');
                                break;
                              case 1:
                                _mapCubit.clearDesktopRouteSelection();
                                context.go('/news');
                                break;
                              case 2:
                                context.go('/map');
                                break;
                              case 3:
                                _mapCubit.clearDesktopRouteSelection();
                                context.go('/profile');
                                break;
                            }
                          },
                          destinations: [
                            NavigationDestination(
                              icon: const Icon(Icons.home_outlined),
                              selectedIcon: const Icon(Icons.home),
                              label: AppTexts.mainHome,
                            ),
                            NavigationDestination(
                              icon: const Icon(Icons.newspaper_outlined),
                              selectedIcon: const Icon(Icons.newspaper),
                              label: AppTexts.mainNews,
                            ),
                            NavigationDestination(
                              icon: const Icon(Icons.map_outlined),
                              selectedIcon: const Icon(Icons.map),
                              label: AppTexts.mainMap,
                            ),
                            NavigationDestination(
                              icon: const Icon(Icons.person_outline),
                              selectedIcon: const Icon(Icons.person),
                              label: AppTexts.mainProfile,
                            ),
                          ],
                        ),
                      ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRotatedNavBar(
    BuildContext context,
    NativeDeviceOrientation orientation,
  ) {
    final quarterTurns = orientation == NativeDeviceOrientation.landscapeLeft
        ? 3
        : 1;
    final oppositeTurns = orientation == NativeDeviceOrientation.landscapeLeft
        ? 1
        : 3;

    Widget buildDestinationItem({
      required IconData icon,
      required IconData selectedIcon,
      required String label,
      required bool isSelected,
    }) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

      final textStyle = TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        color: isSelected
            ? colorScheme.onSurface
            : colorScheme.onSurfaceVariant,
      );

      final iconWidget = Icon(
        isSelected ? selectedIcon : icon,
        color: isSelected
            ? colorScheme.onSurface
            : colorScheme.onSurfaceVariant,
      );

      return RotatedBox(
        quarterTurns: oppositeTurns,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(height: AppSpacing.none),
            Text(
              label,
              style: textStyle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    final selectedIdx = _calculateSelectedIndex(context);

    return SafeArea(
      top: true,
      bottom: true,
      left: true,
      right: true,
      child: RotatedBox(
        quarterTurns: quarterTurns,
        child: NavigationBar(
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          selectedIndex: selectedIdx,
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                _mapCubit.clearDesktopRouteSelection();
                context.go('/');
                break;
              case 1:
                _mapCubit.clearDesktopRouteSelection();
                context.go('/news');
                break;
              case 2:
                context.go('/map');
                break;
              case 3:
                _mapCubit.clearDesktopRouteSelection();
                context.go('/profile');
                break;
            }
          },
          destinations: [
            NavigationDestination(
              icon: buildDestinationItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: AppTexts.mainHome,
                isSelected: selectedIdx == 0,
              ),
              label: '',
            ),
            NavigationDestination(
              icon: buildDestinationItem(
                icon: Icons.newspaper_outlined,
                selectedIcon: Icons.newspaper,
                label: AppTexts.mainNews,
                isSelected: selectedIdx == 1,
              ),
              label: '',
            ),
            NavigationDestination(
              icon: buildDestinationItem(
                icon: Icons.map_outlined,
                selectedIcon: Icons.map,
                label: AppTexts.mainMap,
                isSelected: selectedIdx == 2,
              ),
              label: '',
            ),
            NavigationDestination(
              icon: buildDestinationItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: AppTexts.mainProfile,
                isSelected: selectedIdx == 3,
              ),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}
