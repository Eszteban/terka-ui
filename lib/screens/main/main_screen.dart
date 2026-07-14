import 'package:flutter/material.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../controllers/navigation_cubit.dart';
import '../../controllers/route_planner_cubit.dart';
import '../../controllers/map_cubit.dart';
import '../news_screen.dart';
import '../profile_screen.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_texts.dart';
import '../../widgets/maps/map_view.dart';
import '../../widgets/maps/route_map_data.dart';
import '../../widgets/navigation/top_navbar.dart';
import '../../models/ticket_item.dart';
import '../../models/pass_type.dart';
import '../../repositories/ticket_repository.dart';
import '../../injection_container.dart';
import '../../widgets/forms/route_plan_form.dart';
import '../../services/graphql/graphql_client.dart';
import '../../services/graphql/graphql_queries.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/tables/route_planner_results_view.dart';
import '../../widgets/line_badge.dart';
import '../../widgets/forms/autocomplete_search_field.dart';
import 'general_search_screen.dart';
import '../../utils/markup_text_utils.dart' as markup;
import '../../utils/stop_details_utils.dart';

import 'widgets/main_desktop_map_layout.dart';
import 'widgets/main_planner_content.dart';
import '../tickets_screen.dart';
import '../add_ticket_screen.dart';
import '../manage_pass_types_screen.dart';
import '../pass_type_editor_screen.dart';
import '../about_screen.dart';
import '../trip_details/trip_details_screen.dart';
import '../stop_details/stop_details_screen.dart';

class MainScreen extends StatefulWidget {
  final ThemeMode selectedThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final AppLanguage selectedLanguage;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const MainScreen({
    super.key,
    required this.selectedThemeMode,
    required this.onThemeModeChanged,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const RouteMapData _emptyRouteMapData = RouteMapData(
    segments: [],
    stops: [],
  );

  final TextEditingController _searchController1 = TextEditingController();
  final TextEditingController _searchController2 = TextEditingController();

  DateTime? _selectedDate;
  TicketItem? _editingTicket;
  PassType? _editingPassType;
  String? _activeTripId;
  String? _activeTripServiceDay;
  String? _activeStopId;
  String? _activeStopName;
  LatLng? _activeStopPoint;
  List<String>? _activeGroupedStopIds;

  LatLng? _searchHighlightPoint;
  String? _searchHighlightName;
  String? _selectedRouteName;
  Color? _selectedRouteColor;
  Color? _selectedRouteTextColor;

  String? _preSelectedFromToken;
  String? _preSelectedToToken;
  List<double>? _preSelectedFromCoords;
  List<double>? _preSelectedToCoords;

  double _currentSliderValue = 5;
  double _currentWalkingValue = 1000;
  final Set<String> _selectedKozlekedes = {
    'Helyi busz',
    'Helyközi busz',
    'Vonat',
    'Metró',
    'Troli',
    'Villamos',
    'Hajó',
  };
  bool _jegyfigyeles = false;
  List<TicketItem> _tickets = const [];

  late final NavigationCubit _navigationCubit;
  late final RoutePlannerCubit _routePlannerCubit;
  late final MapCubit _mapCubit;

  bool get _showMap =>
      _navigationCubit.state.currentSection == MainSection.map;
  bool get _showNews =>
      _navigationCubit.state.currentSection == MainSection.news;
  bool get _showProfile =>
      _navigationCubit.state.currentSection == MainSection.profile;

  bool get _hasMeaningfulPlanResponse => _routePlannerCubit.state.hasMeaningfulPlanResponse;
  String get _planResponseText => _routePlannerCubit.state.planResponseText;
  Map<String, dynamic>? get _planResponseJson => _routePlannerCubit.state.planResponseJson;

  @override
  void initState() {
    super.initState();
    _navigationCubit = sl<NavigationCubit>();
    _routePlannerCubit = sl<RoutePlannerCubit>();
    _mapCubit = sl<MapCubit>();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    final result = await sl<TicketRepository>().fetchTickets();
    if (mounted) {
      setState(() {
        _tickets = result.tickets;
      });
    }
  }

  bool get _hasPlannerResultsPayload =>
      _planResponseJson != null ||
      _hasMeaningfulPlanResponse ||
      _planResponseText.isNotEmpty;

  void _showMainScreen() {
    setState(() {
      _searchController1.clear();
      _searchController2.clear();
    });
    _routePlannerCubit.clearSearch();
    _navigationCubit.navigateTo(MainSection.home);
  }

  void _showMapScreen() {
    _navigationCubit.navigateTo(MainSection.map);
  }

  void _showNewsScreen() {
    _navigationCubit.navigateTo(MainSection.news);
  }

  void _showProfileScreen() {
    _navigationCubit.navigateTo(MainSection.profile);
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  bool _handleBackNavigation() {
    return _navigationCubit.handleBackNavigation(
          hasPlannerResultsPayload: _hasPlannerResultsPayload,
          onShowMainScreen: _showMainScreen,
        );
  }

  void _toggleTransportMode(String label) {
    setState(() {
      if (_selectedKozlekedes.contains(label)) {
        _selectedKozlekedes.remove(label);
      } else {
        _selectedKozlekedes.add(label);
      }
    });
  }


  _MobileTab _currentMobileTab() {
    if (_showProfile) {
      return _MobileTab.profile;
    }
    if (_showMap) {
      return _MobileTab.map;
    }
    if (_showNews) {
      return _MobileTab.news;
    }
    return _MobileTab.home;
  }

  String _currentMobileSectionTitle() {
    switch (_currentMobileTab()) {
      case _MobileTab.home:
        return AppTexts.mainRoutePlanning;
      case _MobileTab.news:
        return AppTexts.mainMavNews;
      case _MobileTab.map:
        return AppTexts.mainMap;
      case _MobileTab.profile:
        return AppTexts.mainProfile;
    }
  }

  int _currentDesktopTabIndex() {
    if (_showMap) {
      return -1;
    }
    if (_showNews) {
      return 1;
    }
    if (_showProfile) {
      return 2;
    }
    return 0;
  }

  void _showDesktopRouteOnBackgroundMap({
    required RouteMapData routeData,
    RouteVehicleMarker? vehicleMarker,
    SelectedItineraryMapPayload? selectedPayload,
  }) {
    _mapCubit.showDesktopRouteOnBackgroundMap(
      routeData: routeData,
      vehicleMarker: vehicleMarker,
      selectedPayload: selectedPayload,
    );
  }

  void _clearDesktopRouteSelection() {
    setState(() {
      _selectedRouteName = null;
      _selectedRouteColor = null;
      _selectedRouteTextColor = null;
      _searchHighlightPoint = null;
      _searchHighlightName = null;
    });
    _mapCubit.clearDesktopRouteSelection();
  }

  Future<void> _showRouteOnMap(Map<String, dynamic> rawRouteData) async {
    final gtfsId = rawRouteData['gtfsId']?.toString();
    final shortName = rawRouteData['shortName']?.toString() ?? '-';
    final colorHex = rawRouteData['color']?.toString() ?? '0A84FF';
    final textColorHex = rawRouteData['textColor']?.toString() ?? 'FFFFFF';

    if (gtfsId == null) return;

    final defaultColor = Theme.of(context).colorScheme.primary;

    setState(() {
      _selectedRouteName = shortName;
      _selectedRouteColor = StopDetailsUtils.hexColor(colorHex);
      _selectedRouteTextColor = StopDetailsUtils.hexColor(textColorHex);
    });

    try {
      const queryStr = r'''
        query RoutePattern($id: String!) {
          route(id: $id) {
            patterns {
              geometry {
                lat
                lon
              }
              stops {
                gtfsId
                name
                lat
                lon
              }
            }
          }
        }
      ''';

      final response = await const GraphqlClient().execute(
        query: queryStr,
        variables: {'id': gtfsId},
      );

      if (response.isSuccess && response.json != null) {
        final data = response.json!['data'];
        final route = data is Map ? data['route'] : null;
        final patterns = route is Map ? route['patterns'] : null;
        if (patterns is List && patterns.isNotEmpty) {
          final segments = <RouteSegment>[];
          final stops = <RouteStopMarker>[];

          for (final pattern in patterns) {
            if (pattern is Map) {
              final geom = pattern['geometry'];
              final patternStops = pattern['stops'];

              final points = <LatLng>[];
              if (geom is List) {
                for (final p in geom) {
                  if (p is Map) {
                    final lat = StopDetailsUtils.asNum(p['lat'])?.toDouble();
                    final lon = StopDetailsUtils.asNum(p['lon'])?.toDouble();
                    if (lat != null && lon != null) {
                      points.add(LatLng(lat, lon));
                    }
                  }
                }
              }
              if (points.isNotEmpty) {
                segments.add(
                  RouteSegment(
                    points: points,
                    color: _selectedRouteColor ?? defaultColor,
                  ),
                );
              }

              if (patternStops is List) {
                for (final s in patternStops) {
                  if (s is Map) {
                    final sId = s['gtfsId']?.toString();
                    final sName = s['name']?.toString() ?? '';
                    final lat = StopDetailsUtils.asNum(s['lat'])?.toDouble();
                    final lon = StopDetailsUtils.asNum(s['lon'])?.toDouble();
                    if (sId != null && lat != null && lon != null) {
                      if (!stops.any((marker) => marker.stopId == sId)) {
                        stops.add(
                          RouteStopMarker(
                            stopId: sId,
                            label: sName,
                            point: LatLng(lat, lon),
                            type: RouteStopType.transfer,
                          ),
                        );
                      }
                    }
                  }
                }
              }
            }
          }

          if (segments.isNotEmpty) {
            final routeOverlay = RouteMapData(
              segments: segments,
              stops: stops,
            );

            _showDesktopRouteOnBackgroundMap(
              routeData: routeOverlay,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error showing route on map: $e');
    }
  }

  Future<void> _planRouteToDestination(String name, LatLng coordinates, [String? stopId]) async {
    bool gpsSuccess = false;
    LatLng? currentLoc;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 4),
            ),
          );
          currentLoc = LatLng(position.latitude, position.longitude);
          gpsSuccess = true;
        }
      }
    } catch (_) {}

    final gpsName = AppTexts.isHungarian ? 'Jelenlegi helyzet' : 'Current location';
    final destinationToken = stopId == null
        ? '$name::${coordinates.latitude},${coordinates.longitude}'
        : '$name::$stopId';

    final localLoc = currentLoc;
    if (gpsSuccess && localLoc != null) {
      final fromToken = '$gpsName::${localLoc.latitude},${localLoc.longitude}';
      setState(() {
        _preSelectedFromToken = fromToken;
        _preSelectedFromCoords = [localLoc.longitude, localLoc.latitude];
        _searchController1.text = gpsName;

        _preSelectedToToken = destinationToken;
        _preSelectedToCoords = [coordinates.longitude, coordinates.latitude];
        _searchController2.text = name;
      });

      _routePlannerCubit.setLoading(true);
      _navigationCubit.navigateTo(MainSection.table);

        Map<String, dynamic>? variables;
        try {
          final now = DateTime.now();
          final dateString = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

          variables = <String, dynamic>{
            'arriveBy': false,
            'banned': <String, dynamic>{},
            'bikeReluctance': 1.0,
            'carReluctance': 1.0,
            'date': dateString,
            'fromPlace': fromToken,
            'modes': [{'mode': 'TRANSIT'}, {'mode': 'WALK'}],
            'numItineraries': 15,
            'preferred': <String, dynamic>{},
            'time': timeString,
            'toPlace': destinationToken,
            'unpreferred': <String, dynamic>{},
            'walkReluctance': 1.0,
            'walkSpeed': 1.3888888888888888,
            'wheelchair': false,
            'minTransferTime': 0,
            'transitPassFilter': <String>[],
            'comfortLevels': <String>[],
            'searchParameters': <String>[],
            'distributionChannel': 'ERTEKESITESI_CSATORNA#INTERNET',
            'distributionSubChannel': 'ERTEKESITESI_ALCSATORNA#EMMA',
            'pageCursor': '',
          };

          final response = await const GraphqlClient().execute(
            query: planQuery,
            variables: variables,
          );

          if (response.isSuccess) {
            final isHungarian = AppTexts.isHungarian;
            final plan = response.json?['data']?['plan'];
            final itineraries = plan?['itineraries'];
            final bool hasMeaning = itineraries is List && itineraries.isNotEmpty;

            _routePlannerCubit.setPlanResult(PlanSearchResult(
              hasMeaningfulResponse: hasMeaning,
              responseText: hasMeaning
                  ? response.rawBody
                  : (isHungarian
                      ? 'Nem találtunk útvonalat. Kérjük, próbáld meg más beállításokkal vagy időponttal!'
                      : 'No routes found. Please try with different settings or times!'),
              query: planQuery,
              requestVariables: variables,
              responseJson: response.json,
              nextPageCursor: plan?['pageCursor']?.toString(),
              fromPlaceToken: fromToken,
              toPlaceToken: destinationToken,
              fromCoordinates: _preSelectedFromCoords,
              toCoordinates: _preSelectedToCoords,
            ));
          } else {
            _routePlannerCubit.setPlanResult(PlanSearchResult(
              hasMeaningfulResponse: false,
              responseText: AppTexts.isHungarian
                  ? 'Hiba történt a tervezés során. Kérjük, próbáld újra!'
                  : 'An error occurred during planning. Please try again!',
              query: planQuery,
              requestVariables: variables,
              fromPlaceToken: fromToken,
              toPlaceToken: destinationToken,
              fromCoordinates: _preSelectedFromCoords,
              toCoordinates: _preSelectedToCoords,
            ));
          }
        } catch (e) {
          _routePlannerCubit.setPlanResult(PlanSearchResult(
            hasMeaningfulResponse: false,
            responseText: e.toString(),
            query: planQuery,
            requestVariables: variables,
            fromPlaceToken: fromToken,
            toPlaceToken: destinationToken,
            fromCoordinates: _preSelectedFromCoords,
            toCoordinates: _preSelectedToCoords,
          ));
        } finally {
          _routePlannerCubit.setLoading(false);
        }
    } else {
      setState(() {
        _preSelectedFromToken = null;
        _preSelectedFromCoords = null;
        _searchController1.text = '';

        _preSelectedToToken = destinationToken;
        _preSelectedToCoords = [coordinates.longitude, coordinates.latitude];
        _searchController2.text = name;
      });

      _navigationCubit.navigateTo(MainSection.home);
    }
  }

  RouteMapData _buildStopRouteMapData() {
    if (_activeStopId == null || _activeStopPoint == null) {
      return _emptyRouteMapData;
    }
    return RouteMapData(
      segments: const [],
      stops: [
        RouteStopMarker(
          stopId: _activeStopId!,
          label: _activeStopName ?? '',
          point: _activeStopPoint!,
          type: RouteStopType.transfer,
        ),
      ],
    );
  }

  Widget _buildPlannerContent({required bool isDesktop}) {
    return MainPlannerContent(
      isDesktop: isDesktop,
      ticketWatch: _jegyfigyeles,
      tickets: _tickets,
      onOpenTripDetailsRequested: isDesktop
          ? (tripId, serviceDay) {
              setState(() {
                _activeTripId = tripId;
                _activeTripServiceDay = serviceDay;
              });
              _navigationCubit.navigateTo(MainSection.tripDetails);
            }
          : null,
      fromController: _searchController1,
      toController: _searchController2,
      selectedDate: _selectedDate,
      transfers: _currentSliderValue,
      maxWalk: _currentWalkingValue,
      selectedTransportModes: _selectedKozlekedes,
      initialFromPlaceToken: _preSelectedFromToken,
      initialToPlaceToken: _preSelectedToToken,
      initialFromCoordinates: _preSelectedFromCoords,
      initialToCoordinates: _preSelectedToCoords,
      autofocusFrom: _preSelectedFromToken == null && _preSelectedToToken != null,
      onSearch: (PlanSearchResult result) {
        _routePlannerCubit.setPlanResult(result);
        setState(() {
          _preSelectedFromToken = result.fromPlaceToken;
          _preSelectedToToken = result.toPlaceToken;
          _preSelectedFromCoords = result.fromCoordinates;
          _preSelectedToCoords = result.toCoordinates;
        });
        if (isDesktop) {
          _mapCubit.clearDesktopRouteSelection();
        }
        _navigationCubit.navigateTo(MainSection.table);
      },
      onLoadingChanged: (isLoading) {
        _routePlannerCubit.setLoading(isLoading);
      },
      onPickDate: () => _pickDate(context),
      onTransfersChanged: (value) {
        setState(() {
          _currentSliderValue = value;
        });
      },
      onMaxWalkChanged: (value) {
        setState(() {
          _currentWalkingValue = value;
        });
      },
      onTransportModeToggle: _toggleTransportMode,
      onTicketWatchChanged: (value) {
        setState(() {
          _jegyfigyeles = value;
        });
      },
      onFromPlaceChanged: (token, coords) {
        debugPrint('DEBUG MainScreen: onFromPlaceChanged callback triggered with token: $token');
        setState(() {
          _preSelectedFromToken = token;
          _preSelectedFromCoords = coords;
          debugPrint('DEBUG MainScreen: setState updated _preSelectedFromToken to: $_preSelectedFromToken');
        });
      },
      onToPlaceChanged: (token, coords) {
        debugPrint('DEBUG MainScreen: onToPlaceChanged callback triggered with token: $token');
        setState(() {
          _preSelectedToToken = token;
          _preSelectedToCoords = coords;
          debugPrint('DEBUG MainScreen: setState updated _preSelectedToToken to: $_preSelectedToToken');
        });
      },
    );
  }

  Widget _buildSidebarContent(BuildContext context, MainSection activeSection) {
    switch (activeSection) {
      case MainSection.profile:
        return ProfileScreen(
          selectedThemeMode: widget.selectedThemeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
          selectedLanguage: widget.selectedLanguage,
          onLanguageChanged: widget.onLanguageChanged,
          onOpenTickets: () => _navigationCubit.navigateTo(MainSection.tickets),
          onOpenAddTicket: () => _navigationCubit.navigateTo(MainSection.addTicket),
          onOpenManagePassTypes: () => _navigationCubit.navigateTo(MainSection.managePassTypes),
          onOpenAbout: () => _navigationCubit.navigateTo(MainSection.about),
        );
      case MainSection.news:
        return const NewsScreen();
      case MainSection.tickets:
        return TicketsScreen(
          onBack: _handleBackNavigation,
          onEditTicket: (ticket) {
            setState(() {
              _editingTicket = ticket;
            });
            _navigationCubit.navigateTo(MainSection.editTicket);
          },
        );
      case MainSection.addTicket:
        return AddTicketScreen(
          onBack: _handleBackNavigation,
          onSaved: () {
            _handleBackNavigation();
          },
        );
      case MainSection.editTicket:
        return AddTicketScreen(
          ticket: _editingTicket,
          onBack: _handleBackNavigation,
          onSaved: () {
            _handleBackNavigation();
          },
        );
      case MainSection.managePassTypes:
        return ManagePassTypesScreen(
          onBack: _handleBackNavigation,
          onOpenPassTypeEditor: (passType) {
            setState(() {
              _editingPassType = passType;
            });
            _navigationCubit.navigateTo(MainSection.passTypeEditor);
          },
        );
      case MainSection.passTypeEditor:
        return PassTypeEditorScreen(
          passType: _editingPassType,
          onBack: _handleBackNavigation,
          onSaved: () {
            _handleBackNavigation();
          },
        );
      case MainSection.about:
        return AboutScreen(
          onBack: _handleBackNavigation,
        );
      case MainSection.tripDetails:
        return TripDetailsScreen(
          tripId: _activeTripId ?? '',
          serviceDay: _activeTripServiceDay ?? '',
          onShowOnBackgroundMap: (routeData, vehicleMarker) {
            _showDesktopRouteOnBackgroundMap(
              routeData: routeData,
              vehicleMarker: vehicleMarker,
            );
          },
          onOpenStopDetailsRequested: (stopId, stopName) {
            setState(() {
              _activeStopId = stopId;
              _activeStopName = stopName;
              _activeStopPoint = null;
              _activeGroupedStopIds = null;
            });
            _navigationCubit.navigateTo(MainSection.stopDetails);
          },
          onCloseRequested: _handleBackNavigation,
        );
      case MainSection.stopDetails:
        return StopDetailsScreen(
          stopId: _activeStopId ?? '',
          initialStopName: _activeStopName,
          initialStopPoint: _activeStopPoint,
          groupedStopIds: _activeGroupedStopIds,
          onShowTripOnBackgroundMap: (routeData, vehicleMarker) {
            _showDesktopRouteOnBackgroundMap(
              routeData: routeData,
              vehicleMarker: vehicleMarker,
            );
          },
          onOpenTripDetailsRequested: (tripId, serviceDay) {
            setState(() {
              _activeTripId = tripId;
              _activeTripServiceDay = serviceDay;
            });
            _navigationCubit.navigateTo(MainSection.tripDetails);
          },
          onCloseRequested: _handleBackNavigation,
          onPlanRouteToStop: (stopName, stopPoint, stopId) {
            _planRouteToDestination(stopName, stopPoint, stopId);
          },
        );
      case MainSection.home:
      case MainSection.table:
      default:
        return _buildPlannerContent(isDesktop: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NavigationCubit>.value(value: _navigationCubit),
        BlocProvider<RoutePlannerCubit>.value(value: _routePlannerCubit),
        BlocProvider<MapCubit>.value(value: _mapCubit),
      ],
      child: BlocListener<NavigationCubit, NavigationState>(
        listener: (context, state) {
          _clearDesktopRouteSelection();
          _loadTickets();
        },
        child: BlocBuilder<NavigationCubit, NavigationState>(
          builder: (context, state) {
            return BlocBuilder<RoutePlannerCubit, RoutePlannerState>(
              builder: (context, plannerState) {
                return BlocBuilder<MapCubit, MapState>(
                  builder: (context, mapState) {
                    return NativeDeviceOrientationReader(
                      builder: (context) {
                final orientation = NativeDeviceOrientationReader.orientation(context);
                final isDesktop = MediaQuery.of(context).size.shortestSide > 600;
                final currentMobileTab = _currentMobileTab();
                final currentDesktopTabIndex = _currentDesktopTabIndex();
                final currentMobileSectionTitle = _currentMobileSectionTitle();
                final horizontalPadding = isDesktop ? AppSpacing.xxl : AppSpacing.md;
                final isMapFullscreen = _showMap;
                final useDesktopMapLayout = isDesktop;
                final colorScheme = Theme.of(context).colorScheme;
                final isDark = Theme.of(context).brightness == Brightness.dark;

                final isPhoneLandscape =
                    !isDesktop &&
                    (orientation == NativeDeviceOrientation.landscapeLeft ||
                        orientation == NativeDeviceOrientation.landscapeRight);

                return PopScope(
                  canPop: state.history.length <= 1,
                  onPopInvokedWithResult: (didPop, result) {
                    if (didPop) {
                      return;
                    }
                    _handleBackNavigation();
                  },
                  child: Scaffold(
                    body: Column(
                      children: [
                        if ((!isMapFullscreen || isDesktop) && !isPhoneLandscape)
                          isDesktop
                              ? TopNavbar(
                                  isDesktop: isDesktop,
                                  onHomeTap: _showMainScreen,
                                  onNewsTap: _showNewsScreen,
                                  onProfileTap: _showProfileScreen,
                                  selectedDesktopTabIndex: currentDesktopTabIndex,
                                  mobileCurrentSectionTitle: currentMobileSectionTitle,
                                )
                              : SafeArea(
                                  top: true,
                                  bottom: false,
                                  child: TopNavbar(
                                    isDesktop: isDesktop,
                                    onHomeTap: _showMainScreen,
                                    onNewsTap: _showNewsScreen,
                                    onProfileTap: _showProfileScreen,
                                    mobileCurrentSectionTitle:
                                        currentMobileSectionTitle,
                                  ),
                                ),
                        Expanded(
                          child: useDesktopMapLayout
                              ? MainDesktopMapLayout(
                                  showMap: _showMap,
                                  showResultCard: (state.currentSection == MainSection.home || state.currentSection == MainSection.table) &&
                                      mapState.selectedMapPayload != null,
                                  desktopRouteOverlayData: state.currentSection == MainSection.stopDetails
                                      ? _buildStopRouteMapData()
                                      : mapState.routeOverlayData,
                                  desktopRouteVehicleMarker: mapState.routeVehicleMarker,
                                  desktopSelectedMapPayload: mapState.selectedMapPayload,
                                  sidebarContent: _buildSidebarContent(context, state.currentSection),
                                  onClearDesktopRouteSelection: _clearDesktopRouteSelection,
                                  onShowTripOnBackgroundMap: (routeData, vehicleMarker) {
                                    _showDesktopRouteOnBackgroundMap(
                                      routeData: routeData,
                                      vehicleMarker: vehicleMarker,
                                    );
                                  },
                                  onOpenTripDetailsRequested: (tripId, serviceDay) {
                                    setState(() {
                                      _activeTripId = tripId;
                                      _activeTripServiceDay = serviceDay;
                                    });
                                    _navigationCubit.navigateTo(MainSection.tripDetails);
                                  },
                                  onOpenStopDetailsRequested: (stopId, stopName, initialStopPoint, groupedStopIds) {
                                    setState(() {
                                      _activeStopId = stopId;
                                      _activeStopName = stopName;
                                      _activeStopPoint = initialStopPoint;
                                      _activeGroupedStopIds = groupedStopIds;
                                    });
                                    _navigationCubit.navigateTo(MainSection.stopDetails);
                                  },
                                  hideGeneralStopsAndVehicles: state.currentSection == MainSection.tripDetails ||
                                      state.currentSection == MainSection.stopDetails ||
                                      (mapState.selectedMapPayload != null && _selectedRouteName == null),
                                  searchHighlightPoint: _searchHighlightPoint,
                                  onPlanRouteToStop: (stopName, stopPoint, stopId) {
                                    _planRouteToDestination(stopName, stopPoint, stopId);
                                  },
                                  desktopSelectedRouteName: _selectedRouteName,
                                )
                      : Row(
                          children: [
                            if (isPhoneLandscape &&
                                orientation ==
                                    NativeDeviceOrientation.landscapeRight)
                              _buildRotatedNavBar(
                                context,
                                orientation,
                                currentMobileTab,
                              ),
                            Expanded(
                              child: Column(
                                children: [
                                  if (isPhoneLandscape && !isMapFullscreen)
                                    SafeArea(
                                      top: true,
                                      bottom: false,
                                      child: TopNavbar(
                                        isDesktop: isDesktop,
                                        onHomeTap: _showMainScreen,
                                        onNewsTap: _showNewsScreen,
                                        onProfileTap: _showProfileScreen,
                                        mobileCurrentSectionTitle:
                                            currentMobileSectionTitle,
                                      ),
                                    ),
                                  Expanded(
                                    child: isMapFullscreen
                                        ? Column(
                                            children: [
                                              ColoredBox(
                                                color: AppColors.getSurface(context),
                                                child: const SafeArea(
                                                  bottom: false,
                                                  child: SizedBox.shrink(),
                                                ),
                                              ),
                                              Expanded(
                                                child: Stack(
                                                  children: [
                                                    Positioned.fill(
                                                      child: MapView(
                                                        controlsBottomInset: (_searchHighlightPoint != null || _selectedRouteName != null) ? 156.0 : 88.0,
                                                        routeOverlayData: state.currentSection == MainSection.stopDetails
                                                            ? _buildStopRouteMapData()
                                                            : mapState.routeOverlayData,
                                                        routeVehicleMarker: mapState.routeVehicleMarker,
                                                        onShowTripOnBackgroundMap: (routeData, vehicleMarker) {
                                                          _showDesktopRouteOnBackgroundMap(
                                                            routeData: routeData,
                                                            vehicleMarker: vehicleMarker,
                                                          );
                                                        },
                                                        onOpenTripDetailsRequested: null,
                                                        onOpenStopDetailsRequested: null,
                                                        hideGeneralStopsAndVehicles: (state.currentSection == MainSection.tripDetails ||
                                                            state.currentSection == MainSection.stopDetails ||
                                                            (mapState.selectedMapPayload != null && _selectedRouteName == null)),
                                                        searchHighlightPoint: _searchHighlightPoint,
                                                        onPlanRouteToStop: (stopName, stopPoint, stopId) {
                                                          _planRouteToDestination(stopName, stopPoint, stopId);
                                                        },
                                                        selectedRouteName: _selectedRouteName,
                                                      ),
                                                    ),
                                                    if (_searchHighlightPoint != null && _searchHighlightName != null)
                                                      Positioned(
                                                        left: 16,
                                                        right: 16,
                                                        bottom: 88,
                                                        child: Card(
                                                          elevation: 6,
                                                          shadowColor: Colors.black.withValues(alpha: 0.15),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(16),
                                                            side: BorderSide(
                                                              color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.4),
                                                            ),
                                                          ),
                                                          child: Padding(
                                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                            child: Row(
                                                              children: [
                                                                Container(
                                                                  padding: const EdgeInsets.all(8),
                                                                  decoration: BoxDecoration(
                                                                    color: colorScheme.primary.withValues(alpha: 0.1),
                                                                    shape: BoxShape.circle,
                                                                  ),
                                                                  child: Icon(Icons.place, color: colorScheme.primary, size: 20),
                                                                ),
                                                                const SizedBox(width: 12),
                                                                Expanded(
                                                                  child: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Text(
                                                                        _searchHighlightName!,
                                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                                        maxLines: 1,
                                                                        overflow: TextOverflow.ellipsis,
                                                                      ),
                                                                      Text(
                                                                        AppTexts.isHungarian ? 'Kiválasztott hely' : 'Selected location',
                                                                        style: TextStyle(
                                                                          fontSize: 12,
                                                                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                IconButton(
                                                                  icon: Icon(Icons.directions, color: colorScheme.primary),
                                                                  onPressed: () {
                                                                    _planRouteToDestination(_searchHighlightName!, _searchHighlightPoint!);
                                                                  },
                                                                  tooltip: AppTexts.isHungarian ? 'Útvonaltervezés ide' : 'Plan route here',
                                                                ),
                                                                IconButton(
                                                                  icon: const Icon(Icons.close),
                                                                  onPressed: () {
                                                                    setState(() {
                                                                      _searchHighlightPoint = null;
                                                                      _searchHighlightName = null;
                                                                    });
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    if (_selectedRouteName != null)
                                                      Positioned(
                                                        left: 16,
                                                        right: 16,
                                                        bottom: 88,
                                                        child: Card(
                                                          elevation: 6,
                                                          shadowColor: Colors.black.withValues(alpha: 0.15),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(16),
                                                            side: BorderSide(
                                                              color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.4),
                                                            ),
                                                          ),
                                                          child: Padding(
                                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                            child: Row(
                                                              children: [
                                                                LineBadge(
                                                                  lineLabel: markup.plainTextFromHtml(_selectedRouteName!).trim(),
                                                                  routeColor: _selectedRouteColor ?? colorScheme.primary,
                                                                  routeTextColor: _selectedRouteTextColor ?? Colors.white,
                                                                  useSpanFont: markup.containsSpanMarkup(_selectedRouteName!),
                                                                ),
                                                                const SizedBox(width: 12),
                                                                Expanded(
                                                                  child: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Text(
                                                                        AppTexts.isHungarian ? 'Járat kirajzolva' : 'Line plotted',
                                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                                      ),
                                                                      Text(
                                                                        AppTexts.isHungarian
                                                                            ? 'Mutatás a térképen'
                                                                            : 'Shown on the map',
                                                                        style: TextStyle(
                                                                          fontSize: 12,
                                                                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                IconButton(
                                                                  icon: const Icon(Icons.close),
                                                                  onPressed: _clearDesktopRouteSelection,
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
                                                          final suggestion = await Navigator.of(context).push<SuggestionEntry>(
                                                            MaterialPageRoute(builder: (_) => const GeneralSearchScreen()),
                                                          );
                                                          if (suggestion != null) {
                                                            if (suggestion.type == SuggestionType.stop) {
                                                              if (isDesktop) {
                                                                setState(() {
                                                                  _activeStopId = suggestion.id;
                                                                  _activeStopName = suggestion.name;
                                                                  _activeStopPoint = suggestion.coordinates != null
                                                                      ? LatLng(suggestion.coordinates![1], suggestion.coordinates![0])
                                                                      : null;
                                                                  _activeGroupedStopIds = null;
                                                                });
                                                                _navigationCubit.navigateTo(MainSection.stopDetails);
                                                              } else {
                                                                if (context.mounted) {
                                                                  Navigator.of(context).push(
                                                                    MaterialPageRoute(
                                                                      builder: (_) => StopDetailsScreen(
                                                                        stopId: suggestion.id ?? '',
                                                                        initialStopName: suggestion.name,
                                                                        initialStopPoint: suggestion.coordinates != null
                                                                            ? LatLng(suggestion.coordinates![1], suggestion.coordinates![0])
                                                                            : null,
                                                                        onPlanRouteToStop: (stopName, stopPoint, stopId) {
                                                                          _planRouteToDestination(stopName, stopPoint, stopId);
                                                                        },
                                                                      ),
                                                                    ),
                                                                  );
                                                                }
                                                              }
                                                            } else if (suggestion.type == SuggestionType.address && suggestion.coordinates != null) {
                                                              setState(() {
                                                                _searchHighlightPoint = LatLng(suggestion.coordinates![1], suggestion.coordinates![0]);
                                                                _searchHighlightName = suggestion.name;
                                                              });
                                                            } else if (suggestion.type == SuggestionType.route && suggestion.rawData != null) {
                                                              _showRouteOnMap(suggestion.rawData!);
                                                            }
                                                          }
                                                        },
                                                        child: Card(
                                                          elevation: 6,
                                                          shadowColor: Colors.black.withValues(alpha: 0.15),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(24),
                                                            side: BorderSide(
                                                              color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.4),
                                                            ),
                                                          ),
                                                          child: Padding(
                                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                            child: Row(
                                                              children: [
                                                                Icon(Icons.search, color: colorScheme.primary),
                                                                const SizedBox(width: 12),
                                                                Expanded(
                                                                  child: Text(
                                                                    AppTexts.isHungarian
                                                                        ? 'Hova utazol?'
                                                                        : 'Where to?',
                                                                    style: TextStyle(
                                                                      fontSize: 16,
                                                                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                                                      fontWeight: FontWeight.w500,
                                                                    ),
                                                                  ),
                                                                ),
                                                                Icon(Icons.tune, color: colorScheme.primary),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          )
                                        : Padding(
                                            padding: EdgeInsets.fromLTRB(
                                              horizontalPadding,
                                              AppSpacing.xl,
                                              horizontalPadding,
                                              AppSpacing.xl,
                                            ),
                                            child: Center(
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxWidth: isDesktop
                                                      ? 1120
                                                      : double.infinity,
                                                ),
                                                child: _showProfile
                                                    ? ProfileScreen(
                                                        selectedThemeMode:
                                                            widget.selectedThemeMode,
                                                        onThemeModeChanged:
                                                            widget.onThemeModeChanged,
                                                        selectedLanguage:
                                                            widget.selectedLanguage,
                                                        onLanguageChanged:
                                                            widget.onLanguageChanged,
                                                      )
                                                    : _showNews
                                                    ? const NewsScreen()
                                                    : _buildPlannerContent(
                                                        isDesktop: false,
                                                      ),
                                              ),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            if (isPhoneLandscape &&
                                orientation ==
                                    NativeDeviceOrientation.landscapeLeft)
                              _buildRotatedNavBar(
                                context,
                                orientation,
                                currentMobileTab,
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
                      selectedIndex: _mobileTabIndex(currentMobileTab),
                      onDestinationSelected: (index) {
                        switch (index) {
                          case 0:
                            _showMainScreen();
                            break;
                          case 1:
                            _showNewsScreen();
                            break;
                          case 2:
                            _showMapScreen();
                            break;
                          case 3:
                            _showProfileScreen();
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
          ),
        );
      },
    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  int _mobileTabIndex(_MobileTab tab) {
    switch (tab) {
      case _MobileTab.home:
        return 0;
      case _MobileTab.news:
        return 1;
      case _MobileTab.map:
        return 2;
      case _MobileTab.profile:
        return 3;
    }
  }

  Widget _buildRotatedNavBar(
    BuildContext context,
    NativeDeviceOrientation orientation,
    _MobileTab currentMobileTab,
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
        color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
      );

      final iconWidget = Icon(
        isSelected ? selectedIcon : icon,
        color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
      );

      return RotatedBox(
        quarterTurns: oppositeTurns,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(height: 2),
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

    return SafeArea(
      top: true,
      bottom: true,
      left: true,
      right: true,
      child: RotatedBox(
        quarterTurns: quarterTurns,
        child: NavigationBar(
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          selectedIndex: _mobileTabIndex(currentMobileTab),
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                _showMainScreen();
                break;
              case 1:
                _showNewsScreen();
                break;
              case 2:
                _showMapScreen();
                break;
              case 3:
                _showProfileScreen();
                break;
            }
          },
          destinations: [
            NavigationDestination(
              icon: buildDestinationItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: AppTexts.mainHome,
                isSelected: _mobileTabIndex(currentMobileTab) == 0,
              ),
              label: '',
            ),
            NavigationDestination(
              icon: buildDestinationItem(
                icon: Icons.newspaper_outlined,
                selectedIcon: Icons.newspaper,
                label: AppTexts.mainNews,
                isSelected: _mobileTabIndex(currentMobileTab) == 1,
              ),
              label: '',
            ),
            NavigationDestination(
              icon: buildDestinationItem(
                icon: Icons.map_outlined,
                selectedIcon: Icons.map,
                label: AppTexts.mainMap,
                isSelected: _mobileTabIndex(currentMobileTab) == 2,
              ),
              label: '',
            ),
            NavigationDestination(
              icon: buildDestinationItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: AppTexts.mainProfile,
                isSelected: _mobileTabIndex(currentMobileTab) == 3,
              ),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}

enum _MobileTab { home, news, map, profile }
