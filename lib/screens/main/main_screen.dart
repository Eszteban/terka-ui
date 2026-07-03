import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:latlong2/latlong.dart';

import '../news_screen.dart';
import '../profile_screen.dart';
import '../../utils/main_screen_utils.dart';
import '../../controllers/plan_response_controller.dart';
import '../../services/transit_api_service.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_texts.dart';
import '../../widgets/maps/map_view.dart';
import '../../widgets/maps/route_map_data.dart';
import '../../widgets/navigation/top_navbar.dart';
import '../../models/ticket_item.dart';
import '../../models/pass_type.dart';
import '../../services/ticket_api_service.dart';
import '../../widgets/forms/route_plan_form.dart';
import '../../widgets/tables/dummy_table.dart';

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

  final TransitApiService _transitApiService = const TransitApiService();
  final TextEditingController _searchController1 = TextEditingController();
  final TextEditingController _searchController2 = TextEditingController();

  DateTime? _selectedDate;
  bool _showTable = false;
  bool _showMap = false;
  bool _showNews = false;
  bool _showProfile = false;
  bool _isPlanLoading = false;
  bool _isLoadingMorePlans = false;
  bool _hasMeaningfulPlanResponse = false;
  String _planResponseText = '';
  Map<String, dynamic>? _planResponseJson;
  String _lastPlanQuery = '';
  Map<String, dynamic>? _lastPlanVariables;
  String? _nextPageCursor;
  RouteMapData _desktopRouteOverlayData = _emptyRouteMapData;
  RouteVehicleMarker? _desktopRouteVehicleMarker;
  SelectedItineraryMapPayload? _desktopSelectedMapPayload;
  TicketItem? _editingTicket;
  PassType? _editingPassType;
  String? _activeTripId;
  String? _activeTripServiceDay;
  String? _activeStopId;
  String? _activeStopName;
  LatLng? _activeStopPoint;
  List<String>? _activeGroupedStopIds;
  final List<_MainSection> _navigationHistory = [_MainSection.home];

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

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    final result = await const TicketApiService().fetchTickets();
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

  void _navigateTo(_MainSection section, {bool addToHistory = true}) {
    setState(() {
      _showTable = section == _MainSection.table;
      _showMap = section == _MainSection.map;
      _showNews = section == _MainSection.news;
      _showProfile = section == _MainSection.profile;

      _desktopRouteOverlayData = _emptyRouteMapData;
      _desktopRouteVehicleMarker = null;
      _desktopSelectedMapPayload = null;

      if (addToHistory) {
        final current = _navigationHistory.isNotEmpty
            ? _navigationHistory.last
            : _MainSection.home;
        if (current != section) {
          _navigationHistory.add(section);
        }
      }
    });
    _loadTickets();
  }

  bool _handleBackNavigation() {
    if (_showTable && _hasPlannerResultsPayload) {
      _showMainScreen();
      _navigationHistory.clear();
      _navigationHistory.add(_MainSection.home);
      return false;
    }
    if (_navigationHistory.length <= 1) {
      return true;
    }

    _navigationHistory.removeLast();
    final previousSection = _navigationHistory.last;
    _navigateTo(previousSection, addToHistory: false);
    return false;
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

  void _showMainScreen() {
    setState(() {
      _searchController1.clear();
      _searchController2.clear();
      _hasMeaningfulPlanResponse = false;
      _planResponseText = '';
      _planResponseJson = null;
      _lastPlanQuery = '';
      _lastPlanVariables = null;
      _nextPageCursor = null;
      _isLoadingMorePlans = false;
    });
    _navigateTo(_MainSection.home);
  }

  void _showMapScreen() {
    _navigateTo(_MainSection.map);
  }

  void _showNewsScreen() {
    _navigateTo(_MainSection.news);
  }

  void _showProfileScreen() {
    _navigateTo(_MainSection.profile);
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

  Future<void> _loadMorePlans() async {
    if (_isLoadingMorePlans) {
      return;
    }
    if (_lastPlanQuery.trim().isEmpty ||
        _lastPlanVariables == null ||
        _nextPageCursor == null ||
        _nextPageCursor!.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoadingMorePlans = true;
    });

    try {
      final nextJson = await _transitApiService.loadMorePlans(
        query: _lastPlanQuery,
        variables: _lastPlanVariables!,
        nextPageCursor: _nextPageCursor,
      );

      if (nextJson == null) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTexts.mainLoadMoreFailed),
          ),
        );
        return;
      }

      final merged = _mergePlanResponses(_planResponseJson, nextJson);
      final plan = PlanResponseController.extractPlan(nextJson);
      final nextCursor = PlanResponseController.extractNextPageCursor(plan);

      if (!mounted) {
        return;
      }

      setState(() {
        _planResponseJson = merged;
        _planResponseText = const JsonEncoder.withIndent('  ').convert(merged);
        _hasMeaningfulPlanResponse = _hasItineraries(merged);
        _lastPlanVariables = Map<String, dynamic>.from(_lastPlanVariables!)
          ..['pageCursor'] = _nextPageCursor;
        _nextPageCursor = nextCursor;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTexts.mainLoadMoreFailed),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMorePlans = false;
        });
      }
    }
  }

  bool _hasItineraries(Map<String, dynamic>? json) {
    return MainScreenUtils.hasItineraries(json);
  }

  Map<String, dynamic> _mergePlanResponses(
    Map<String, dynamic>? current,
    Map<String, dynamic> next,
  ) {
    return MainScreenUtils.mergePlanResponses(current, next);
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
    setState(() {
      _desktopRouteOverlayData = _emptyRouteMapData;
      _desktopRouteVehicleMarker = null;
      _desktopSelectedMapPayload = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _desktopRouteOverlayData = routeData;
          _desktopRouteVehicleMarker = vehicleMarker;
          _desktopSelectedMapPayload = selectedPayload;
        });
      }
    });
  }

  void _clearDesktopRouteSelection() {
    setState(() {
      _desktopRouteOverlayData = _emptyRouteMapData;
      _desktopRouteVehicleMarker = null;
      _desktopSelectedMapPayload = null;
    });
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
      isPlanLoading: _isPlanLoading,
      showTable: _showTable,
      hasPlannerResultsPayload: _hasPlannerResultsPayload,
      planResponseText: _planResponseText,
      hasDesktopMapSelection: _desktopRouteOverlayData.hasContent ||
          _desktopRouteVehicleMarker != null ||
          _desktopSelectedMapPayload != null,
      canLoadMore: (_nextPageCursor?.trim().isNotEmpty ?? false),
      isLoadingMore: _isLoadingMorePlans,
      onLoadMore: _loadMorePlans,
      ticketWatch: _jegyfigyeles,
      tickets: _tickets,
      onShowOnMap: (payload) {
        _showDesktopRouteOnBackgroundMap(
          routeData: payload.routeData,
          selectedPayload: payload,
        );
      },
      onShowTripOnMap: (routeData, vehicleMarker) {
        _showDesktopRouteOnBackgroundMap(
          routeData: routeData,
          vehicleMarker: vehicleMarker,
        );
      },
      onOpenTripDetailsRequested: isDesktop
          ? (tripId, serviceDay) {
              setState(() {
                _activeTripId = tripId;
                _activeTripServiceDay = serviceDay;
              });
              _navigateTo(_MainSection.tripDetails);
            }
          : null,
      fromController: _searchController1,
      toController: _searchController2,
      selectedDate: _selectedDate,
      transfers: _currentSliderValue,
      maxWalk: _currentWalkingValue,
      selectedTransportModes: _selectedKozlekedes,
      onSearch: (PlanSearchResult result) {
        setState(() {
          _hasMeaningfulPlanResponse = result.hasMeaningfulResponse;
          _planResponseText = result.responseText;
          _planResponseJson = result.responseJson;
          _lastPlanQuery = result.query;
          _lastPlanVariables = result.requestVariables;
          _nextPageCursor = result.nextPageCursor;
          if (isDesktop) {
            _desktopRouteOverlayData = _emptyRouteMapData;
            _desktopRouteVehicleMarker = null;
            _desktopSelectedMapPayload = null;
          }
        });
        _navigateTo(_MainSection.table);
      },
      onLoadingChanged: (isLoading) {
        setState(() {
          _isPlanLoading = isLoading;
        });
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
    );
  }

  Widget _buildSidebarContent(BuildContext context) {
    final activeSection = _navigationHistory.last;
    switch (activeSection) {
      case _MainSection.profile:
        return ProfileScreen(
          selectedThemeMode: widget.selectedThemeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
          selectedLanguage: widget.selectedLanguage,
          onLanguageChanged: widget.onLanguageChanged,
          onOpenTickets: () => _navigateTo(_MainSection.tickets),
          onOpenAddTicket: () => _navigateTo(_MainSection.addTicket),
          onOpenManagePassTypes: () => _navigateTo(_MainSection.managePassTypes),
          onOpenAbout: () => _navigateTo(_MainSection.about),
        );
      case _MainSection.news:
        return const NewsScreen();
      case _MainSection.tickets:
        return TicketsScreen(
          onBack: _handleBackNavigation,
          onEditTicket: (ticket) {
            setState(() {
              _editingTicket = ticket;
            });
            _navigateTo(_MainSection.editTicket);
          },
        );
      case _MainSection.addTicket:
        return AddTicketScreen(
          onBack: _handleBackNavigation,
          onSaved: () {
            _handleBackNavigation();
          },
        );
      case _MainSection.editTicket:
        return AddTicketScreen(
          ticket: _editingTicket,
          onBack: _handleBackNavigation,
          onSaved: () {
            _handleBackNavigation();
          },
        );
      case _MainSection.managePassTypes:
        return ManagePassTypesScreen(
          onBack: _handleBackNavigation,
          onOpenPassTypeEditor: (passType) {
            setState(() {
              _editingPassType = passType;
            });
            _navigateTo(_MainSection.passTypeEditor);
          },
        );
      case _MainSection.passTypeEditor:
        return PassTypeEditorScreen(
          passType: _editingPassType,
          onBack: _handleBackNavigation,
          onSaved: () {
            _handleBackNavigation();
          },
        );
      case _MainSection.about:
        return AboutScreen(
          onBack: _handleBackNavigation,
        );
      case _MainSection.tripDetails:
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
            _navigateTo(_MainSection.stopDetails);
          },
          onCloseRequested: _handleBackNavigation,
        );
      case _MainSection.stopDetails:
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
            _navigateTo(_MainSection.tripDetails);
          },
          onCloseRequested: _handleBackNavigation,
        );
      case _MainSection.home:
      case _MainSection.table:
      default:
        return _buildPlannerContent(isDesktop: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 700;
    final currentMobileTab = _currentMobileTab();
    final currentDesktopTabIndex = _currentDesktopTabIndex();
    final currentMobileSectionTitle = _currentMobileSectionTitle();
    final horizontalPadding = isDesktop ? AppSpacing.xxl : AppSpacing.md;
    final isMapFullscreen = _showMap;
    final useDesktopMapLayout = isDesktop;

    return PopScope(
      canPop: _navigationHistory.length <= 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleBackNavigation();
      },
      child: Scaffold(
        body: Column(
          children: [
            if (!isMapFullscreen || isDesktop)
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
                        mobileCurrentSectionTitle: currentMobileSectionTitle,
                      ),
                    ),
            Expanded(
              child: useDesktopMapLayout
                  ? MainDesktopMapLayout(
                      showMap: _showMap,
                      showResultCard: (_navigationHistory.last == _MainSection.home || _navigationHistory.last == _MainSection.table) &&
                          _desktopSelectedMapPayload != null,
                      desktopRouteOverlayData: _navigationHistory.last == _MainSection.stopDetails
                          ? _buildStopRouteMapData()
                          : _desktopRouteOverlayData,
                      desktopRouteVehicleMarker: _desktopRouteVehicleMarker,
                      desktopSelectedMapPayload: _desktopSelectedMapPayload,
                      sidebarContent: _buildSidebarContent(context),
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
                        _navigateTo(_MainSection.tripDetails);
                      },
                      onOpenStopDetailsRequested: (stopId, stopName, initialStopPoint, groupedStopIds) {
                        setState(() {
                          _activeStopId = stopId;
                          _activeStopName = stopName;
                          _activeStopPoint = initialStopPoint;
                          _activeGroupedStopIds = groupedStopIds;
                        });
                        _navigateTo(_MainSection.stopDetails);
                      },
                      hideGeneralStopsAndVehicles: _navigationHistory.last == _MainSection.tripDetails ||
                          _navigationHistory.last == _MainSection.stopDetails ||
                          _desktopRouteOverlayData.hasContent ||
                          _desktopSelectedMapPayload != null,
                    )
                  : isMapFullscreen
                      ? Column(
                          children: [
                            ColoredBox(
                              color: AppColors.getSurface(context),
                              child: const SafeArea(
                                bottom: false,
                                child: SizedBox.shrink(),
                              ),
                            ),
                            const Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(child: MapView())
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
                                maxWidth: isDesktop ? 1120 : double.infinity,
                              ),
                              child: _showProfile
                                  ? ProfileScreen(
                                      selectedThemeMode:
                                          widget.selectedThemeMode,
                                      onThemeModeChanged:
                                          widget.onThemeModeChanged,
                                      selectedLanguage: widget.selectedLanguage,
                                      onLanguageChanged:
                                          widget.onLanguageChanged,
                                    )
                                  : _showNews
                                      ? const NewsScreen()
                                      : _buildPlannerContent(isDesktop: false),
                            ),
                          ),
                        ),
            ),
          ],
        ),
        bottomNavigationBar: isDesktop
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
}

enum _MobileTab { home, news, map, profile }

enum _MainSection {
  home,
  table,
  map,
  news,
  profile,
  tickets,
  addTicket,
  editTicket,
  managePassTypes,
  passTypeEditor,
  about,
  tripDetails,
  stopDetails,
}
