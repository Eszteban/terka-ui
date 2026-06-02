import 'package:flutter/material.dart';
import 'dart:convert';

import 'news_screen.dart';
import 'profile_screen.dart';
import '../controllers/plan_response_controller.dart';
import '../services/graphql/graphql_client.dart';
import '../theme/app_tokens.dart';
import '../widgets/forms/route_plan_form.dart';
import '../widgets/maps/map_view.dart';
import '../widgets/maps/plan_map_view.dart';
import '../widgets/maps/route_map_data.dart';
import '../widgets/navigation/top_navbar.dart';
import '../widgets/tables/dummy_table.dart';

class MainScreen extends StatefulWidget {
  final ThemeMode selectedThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const MainScreen({
    super.key,
    required this.selectedThemeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const String _defaultPlanResponseText = 'Még nincs lekérdezés.';
  static const RouteMapData _emptyRouteMapData = RouteMapData(
    segments: [],
    stops: [],
  );

  final GraphqlClient _graphqlClient = const GraphqlClient();
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
  String _planResponseText = _defaultPlanResponseText;
  Map<String, dynamic>? _planResponseJson;
  String _lastPlanQuery = '';
  Map<String, dynamic>? _lastPlanVariables;
  String? _nextPageCursor;
  RouteMapData _desktopRouteOverlayData = _emptyRouteMapData;
  RouteVehicleMarker? _desktopRouteVehicleMarker;
  SelectedItineraryMapPayload? _desktopSelectedMapPayload;
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

  bool get _hasPlannerResultsPayload =>
      _planResponseJson != null ||
      _hasMeaningfulPlanResponse ||
      _planResponseText.trim() != _defaultPlanResponseText;

  void _navigateTo(_MainSection section, {bool addToHistory = true}) {
    setState(() {
      _showTable = section == _MainSection.table;
      _showMap = section == _MainSection.map;
      _showNews = section == _MainSection.news;
      _showProfile = section == _MainSection.profile;

      if (addToHistory) {
        final current = _navigationHistory.isNotEmpty
            ? _navigationHistory.last
            : _MainSection.home;
        if (current != section) {
          _navigationHistory.add(section);
        }
      }
    });
  }

  bool _handleBackNavigation() {
    // Ha dummy listán vagyunk, vissza főoldalra
    if (_showTable && _hasPlannerResultsPayload) {
      _showMainScreen();
      // Töröljük a history-t, hogy ne lehessen visszalépni még egyszer
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
      _planResponseText = _defaultPlanResponseText;
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
      final variables = Map<String, dynamic>.from(_lastPlanVariables!);
      variables['pageCursor'] = _nextPageCursor;

      final response = await _graphqlClient.execute(
        query: _lastPlanQuery,
        variables: variables,
      );

      if (!response.isSuccess) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'További betöltés sikertelen (HTTP ${response.statusCode}).',
            ),
          ),
        );
        return;
      }

      final nextJson = response.json;
      if (nextJson == null) {
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
        _lastPlanVariables = variables;
        _nextPageCursor = nextCursor;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nem sikerült további találatokat betölteni.'),
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingMorePlans = false;
      });
    }
  }

  Map<String, dynamic>? _extractPlan(Map<String, dynamic>? json) {
    return PlanResponseController.extractPlan(json);
  }

  String? _extractNextPageCursor(Map<String, dynamic>? plan) {
    return PlanResponseController.extractNextPageCursor(plan);
  }

  bool _hasItineraries(Map<String, dynamic>? json) {
    final plan = _extractPlan(json);
    final itineraries = plan?['itineraries'];
    return itineraries is List && itineraries.isNotEmpty;
  }

  Map<String, dynamic> _mergePlanResponses(
    Map<String, dynamic>? current,
    Map<String, dynamic> next,
  ) {
    if (current == null) {
      return next;
    }

    final merged = jsonDecode(jsonEncode(current)) as Map<String, dynamic>;

    final currentPlan = _extractPlan(merged);
    final nextPlan = _extractPlan(next);
    if (currentPlan == null || nextPlan == null) {
      return next;
    }

    final currentItineraries = currentPlan['itineraries'];
    final nextItineraries = nextPlan['itineraries'];
    if (currentItineraries is List && nextItineraries is List) {
      currentItineraries.addAll(nextItineraries);
    }

    currentPlan['pageCursor'] = _extractNextPageCursor(nextPlan) ?? '';
    return merged;
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
        return 'Tervezés';
      case _MobileTab.news:
        return 'Hírek';
      case _MobileTab.map:
        return 'Térkép';
      case _MobileTab.profile:
        return 'Profil';
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
      _desktopRouteOverlayData = routeData;
      _desktopRouteVehicleMarker = vehicleMarker;
      _desktopSelectedMapPayload = selectedPayload;
    });
  }

  void _clearDesktopRouteSelection() {
    setState(() {
      _desktopRouteOverlayData = _emptyRouteMapData;
      _desktopRouteVehicleMarker = null;
      _desktopSelectedMapPayload = null;
    });
  }

  Widget _buildPlannerContent({required bool isDesktop}) {
    if (_isPlanLoading) {
      return _PlanLoadingView();
    }

    if (_showTable && _hasPlannerResultsPayload) {
      return DummyTable(
        responseText: _planResponseText,
        desktopInlineMapMode: isDesktop,
        hasDesktopMapSelection:
            _desktopRouteOverlayData.hasContent ||
            _desktopRouteVehicleMarker != null ||
            _desktopSelectedMapPayload != null,
        canLoadMore: (_nextPageCursor?.trim().isNotEmpty ?? false),
        isLoadingMore: _isLoadingMorePlans,
        onLoadMore: _loadMorePlans,
        onShowOnMap: (payload) {
          if (isDesktop) {
            _showDesktopRouteOnBackgroundMap(
              routeData: payload.routeData,
              selectedPayload: payload,
            );
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _SelectedItineraryMapScreen(payload: payload),
            ),
          );
        },
        onShowTripOnMap: isDesktop
            ? (routeData, vehicleMarker) {
                _showDesktopRouteOnBackgroundMap(
                  routeData: routeData,
                  vehicleMarker: vehicleMarker,
                );
              }
            : null,
      );
    }

    return RoutePlanForm(
      fromController: _searchController1,
      toController: _searchController2,
      selectedDate: _selectedDate,
      transfers: _currentSliderValue,
      maxWalk: _currentWalkingValue,
      selectedTransportModes: _selectedKozlekedes,
      ticketWatch: _jegyfigyeles,
      onSearch: (result) {
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

  Widget _buildDesktopOverlayPanel({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: AppColors.getSurface(context).withOpacity(0.84),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.7),
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }

  Widget _buildDesktopMapPlannerLayout() {
    const panelWidth = 430.0;
    final showPlannerPanel = !_showMap;
    final showResultCard =
        !_showNews && !_showProfile && _desktopSelectedMapPayload != null;
    final hasRouteOverlay =
        _desktopRouteOverlayData.hasContent ||
        _desktopRouteVehicleMarker != null;

    return Stack(
      children: [
        Positioned.fill(
          child: MapView(
            controlsBottomInset: showPlannerPanel && showResultCard ? 220 : 0,
            routeOverlayData: hasRouteOverlay ? _desktopRouteOverlayData : null,
            routeVehicleMarker: _desktopRouteVehicleMarker,
            routeFitPadding: showPlannerPanel
                ? const EdgeInsets.fromLTRB(520, 48, 48, 260)
                : const EdgeInsets.fromLTRB(48, 48, 48, 220),
            showRouteStopLabels: false,
            useBaseMapStopIcon: true,
            onShowTripOnBackgroundMap: (routeData, vehicleMarker) {
              _showDesktopRouteOnBackgroundMap(
                routeData: routeData,
                vehicleMarker: vehicleMarker,
              );
            },
          ),
        ),
        if (showPlannerPanel)
          Positioned(
            left: AppSpacing.xl,
            top: AppSpacing.xl,
            bottom: AppSpacing.xl,
            width: panelWidth,
            child: Column(
              children: [
                Expanded(
                  child: _buildDesktopOverlayPanel(
                    child: _showProfile
                        ? ProfileScreen(
                            selectedThemeMode: widget.selectedThemeMode,
                            onThemeModeChanged: widget.onThemeModeChanged,
                          )
                        : _showNews
                        ? const NewsScreen()
                        : _buildPlannerContent(isDesktop: true),
                  ),
                ),
                if (showResultCard) ...[
                  const SizedBox(height: 12),
                  _buildDesktopOverlayPanel(
                    padding: EdgeInsets.zero,
                    child: _SelectedMapResultCard(
                      payload: _desktopSelectedMapPayload,
                      onBack: _clearDesktopRouteSelection,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
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
                  ? _buildDesktopMapPlannerLayout()
                  : isMapFullscreen
                  ? Column(
                      children: [
                        ColoredBox(
                          color: AppColors.getSurface(context),
                          child: SafeArea(
                            bottom: false,
                            child: const SizedBox.shrink(),
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            children: [Positioned.fill(child: const MapView())],
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
                                  selectedThemeMode: widget.selectedThemeMode,
                                  onThemeModeChanged: widget.onThemeModeChanged,
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
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Főoldal',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.newspaper_outlined),
                      selectedIcon: Icon(Icons.newspaper),
                      label: 'Hírek',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.map_outlined),
                      selectedIcon: Icon(Icons.map),
                      label: 'Térkép',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: 'Profil',
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

class _SelectedMapResultCard extends StatelessWidget {
  static const double _legTileExtent = 64;
  static const int _maxVisibleLegs = 5;

  final SelectedItineraryMapPayload? payload;
  final VoidCallback onBack;

  const _SelectedMapResultCard({required this.payload, required this.onBack});

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
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.08)) : null,
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              label: const Text('Vissza'),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _SelectedItineraryMapScreen extends StatelessWidget {
  final SelectedItineraryMapPayload payload;

  const _SelectedItineraryMapScreen({required this.payload});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Útvonal térképen')),
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
              child: _SelectedMapResultCard(
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

class _PlanLoadingView extends StatefulWidget {
  @override
  State<_PlanLoadingView> createState() => _PlanLoadingViewState();
}

class _PlanLoadingViewState extends State<_PlanLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final skeletonColor = isDark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.7);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.35 + (_controller.value * 0.4);
        return Opacity(
          opacity: opacity,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row Skeleton
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: skeletonColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 180,
                            height: 16,
                            decoration: BoxDecoration(
                              color: skeletonColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Bento Grid Skeleton
                      _buildSkeletonTile(skeletonColor, height: 80),
                      const SizedBox(height: 6),
                      _buildSkeletonTile(skeletonColor, height: 60),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSkeletonTile(Color color, {required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

enum _MobileTab { home, news, map, profile }

enum _MainSection { home, table, map, news, profile }
