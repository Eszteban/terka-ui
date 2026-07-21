import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../app.dart';
import '../../theme/app_texts.dart';
import '../../utils/layout_provider.dart';
import '../../screens/main/main_screen.dart';
import '../../screens/main/home_screen.dart';
import '../../screens/main/plan_screen.dart';
import '../../widgets/tables/route_planner_results_view.dart';
import '../../screens/stop_details/stop_details_screen.dart';
import '../../screens/route_details/route_details_screen.dart';
import '../../screens/trip_details/trip_details_screen.dart';
import '../../screens/news_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/map_cubit.dart';
import '../../controllers/stop_details_cubit.dart';
import '../../controllers/route_details_cubit.dart';
import '../../controllers/trip_details_cubit.dart';
import '../../repositories/transit_repository.dart';
import '../../injection_container.dart';
import '../../screens/profile_screen.dart';
import '../../screens/tickets_screen.dart';
import '../../screens/add_ticket_screen.dart';
import '../../screens/manage_pass_types_screen.dart';
import '../../screens/pass_type_editor_screen.dart';
import '../../screens/about_screen.dart';
import 'transparent_route.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

class AppRouter {
    static Page<dynamic> _buildPage(BuildContext context, GoRouterState state, Widget child) {
    if (LayoutProvider.isDesktop(context)) {
      return TransparentPage(
        key: state.pageKey,
        child: child,
      );
    }
    return MaterialPage(key: state.pageKey, child: child);
  }

  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  static GoRouter createRouter({
    required ValueNotifier<ThemeMode> themeModeNotifier,
    required void Function(ThemeMode) onThemeModeChanged,
    required ValueNotifier<AppLanguage> languageNotifier,
    required void Function(AppLanguage) onLanguageChanged,
    required ValueNotifier<AppLayoutMode> layoutModeNotifier,
    required void Function(AppLayoutMode) onLayoutModeChanged,
  }) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      errorBuilder: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/');
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
      routes: [
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          observers: [routeObserver],
          builder: (context, state, child) {
            return MainScreen(child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => _buildPage(context, state, Builder(builder: (context) {
                final isDesktop = LayoutProvider.isDesktop(context);
                final queryParams = state.uri.queryParameters;
                return HomeScreen(
                  isDesktop: isDesktop,
                  initialFrom: queryParams['from'],
                  initialTo: queryParams['to'],
                  initialFromCoords: queryParams['fromCoords'],
                  initialToCoords: queryParams['toCoords'],
                );
              })),
            ),
            GoRoute(
              path: '/map',
              pageBuilder: (context, state) => _buildPage(context, state, const SizedBox.shrink()),
            ),
            GoRoute(
              path: '/plan',
              pageBuilder: (context, state) => _buildPage(context, state, Builder(builder: (context) {
                final queryParams = state.uri.queryParameters;
                return PlanScreen(
                  from: queryParams['from'],
                  to: queryParams['to'],
                  fromCoords: queryParams['fromCoords'],
                  toCoords: queryParams['toCoords'],
                  date: queryParams['date'],
                  transfers: queryParams['transfers'],
                  maxWalk: queryParams['maxWalk'],
                  modes: queryParams['modes'],
                  ticketWatch: queryParams['ticketWatch'],
                );
              })),
            ),
            GoRoute(
              path: '/stop/:stopId',
              pageBuilder: (context, state) => _buildPage(context, state, Builder(builder: (context) {
                final mapCubit = context.read<MapCubit>();
                final stopId = state.pathParameters['stopId']!;

                final dateStr = state.uri.queryParameters['date'];
                final pastStr = state.uri.queryParameters['past'];
                final linesStr = state.uri.queryParameters['lines'];

                DateTime? date;
                if (dateStr != null && dateStr.isNotEmpty) {
                  try {
                    date = DateTime.parse(dateStr);
                  } catch (_) {}
                }

                final past = pastStr == 'true';
                final lines = linesStr
                    ?.split(',')
                    .where((s) => s.isNotEmpty)
                    .toSet();

                return BlocProvider(
                  key: ValueKey(state.uri.toString()),
                  create: (context) => StopDetailsCubit(
                    transitRepository: sl<TransitRepository>(),
                    mapCubit: mapCubit,
                    stopId: stopId,
                    date: date,
                    past: past,
                    lines: lines,
                  ),
                  child: StopDetailsScreen(
                    stopId: stopId,
                    onCloseRequested: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                );
              })),
            ),
            GoRoute(
              path: '/routes/:routeId',
              redirect: (context, state) {
                final routeId = state.pathParameters['routeId']!;
                return '/route/$routeId';
              },
            ),
            GoRoute(
              path: '/route/:routeId',
              pageBuilder: (context, state) => _buildPage(context, state, Builder(builder: (context) {
                final mapCubit = context.read<MapCubit>();
                final routeId = state.pathParameters['routeId']!;
                return BlocProvider(
                  key: ValueKey(state.uri.toString()),
                  create: (context) => RouteDetailsCubit(
                    transitRepository: sl<TransitRepository>(),
                    mapCubit: mapCubit,
                    routeId: routeId,
                  ),
                  child: RouteDetailsScreen(
                    routeId: routeId,
                    onCloseRequested: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                    onOpenTripDetailsRequested: (tripId, serviceDay) async {
                      final encodedTripId = Uri.encodeComponent(tripId);
                      if (serviceDay.isNotEmpty) {
                        await context.push(
                          '/trip/$encodedTripId?date=$serviceDay',
                        );
                      } else {
                        await context.push('/trip/$encodedTripId');
                      }
                    },
                  ),
                );
              })),
            ),
            GoRoute(
              path: '/trip/:tripId',
              pageBuilder: (context, state) => _buildPage(context, state, Builder(builder: (context) {
                final mapCubit = context.read<MapCubit>();
                final tripId = state.pathParameters['tripId']!;
                final rawServiceDay =
                    state.uri.queryParameters['date'] ??
                    state.uri.queryParameters['serviceDay'] ??
                    '';
                final now = DateTime.now();
                final serviceDay = rawServiceDay.isEmpty
                    ? '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}'
                    : rawServiceDay;
                return BlocProvider(
                  key: ValueKey(state.uri.toString()),
                  create: (context) => TripDetailsCubit(
                    transitRepository: sl<TransitRepository>(),
                    mapCubit: mapCubit,
                    tripId: tripId,
                    serviceDay: serviceDay,
                  ),
                  child: TripDetailsScreen(
                    tripId: tripId,
                    serviceDay: serviceDay,
                    onCloseRequested: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                    onOpenStopDetailsRequested: (stopId, stopName) async {
                      final encodedStopId = Uri.encodeComponent(stopId);
                      await context.push('/stop/$encodedStopId');
                    },
                  ),
                );
              })),
            ),
            GoRoute(
              path: '/news',
              pageBuilder: (context, state) => _buildPage(context, state, const NewsScreen()),
            ),
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) => _buildPage(context, state, ValueListenableBuilder<ThemeMode>(
                valueListenable: themeModeNotifier,
                builder: (context, themeMode, _) =>
                    ValueListenableBuilder<AppLanguage>(
                      valueListenable: languageNotifier,
                      builder: (context, language, _) =>
                          ValueListenableBuilder<AppLayoutMode>(
                            valueListenable: layoutModeNotifier,
                            builder: (context, layoutMode, _) => ProfileScreen(
                              selectedThemeMode: themeMode,
                              onThemeModeChanged: onThemeModeChanged,
                              selectedLanguage: language,
                              onLanguageChanged: onLanguageChanged,
                              selectedLayoutMode: layoutMode,
                              onLayoutModeChanged: onLayoutModeChanged,
                              onOpenTickets: () => context.push('/tickets'),
                              onOpenAddTicket: () =>
                                  context.push('/tickets/add'),
                              onOpenManagePassTypes: () =>
                                  context.push('/pass-types'),
                              onOpenAbout: () => context.push('/about'),
                            ),
                          ),
                    ),
              )),
            ),
            GoRoute(
              path: '/tickets',
              pageBuilder: (context, state) => _buildPage(context, state, TicketsScreen(
                onBack: () {
                  if (context.canPop())
                    context.pop();
                  else
                    context.go('/profile');
                },
                onEditTicket: (ticket) {
                  context.push('/tickets/add', extra: ticket);
                },
              )),
            ),
            GoRoute(
              path: '/tickets/add',
              pageBuilder: (context, state) => _buildPage(context, state, AddTicketScreen(
                ticket: state.extra as dynamic,
                onBack: () {
                  if (context.canPop())
                    context.pop();
                  else
                    context.go('/tickets');
                },
                onSaved: () {
                  if (context.canPop())
                    context.pop();
                  else
                    context.go('/tickets');
                },
              )),
            ),
            GoRoute(
              path: '/pass-types',
              pageBuilder: (context, state) => _buildPage(context, state, ManagePassTypesScreen(
                onBack: () {
                  if (context.canPop())
                    context.pop();
                  else
                    context.go('/profile');
                },
                onOpenPassTypeEditor: (passType) {
                  context.push('/pass-types/edit', extra: passType);
                },
              )),
            ),
            GoRoute(
              path: '/pass-types/edit',
              pageBuilder: (context, state) => _buildPage(context, state, PassTypeEditorScreen(
                passType: state.extra as dynamic,
                onBack: () {
                  if (context.canPop())
                    context.pop();
                  else
                    context.go('/pass-types');
                },
                onSaved: () {
                  if (context.canPop())
                    context.pop();
                  else
                    context.go('/pass-types');
                },
              )),
            ),
            GoRoute(
              path: '/about',
              pageBuilder: (context, state) => _buildPage(context, state, AboutScreen(
                onBack: () {
                  if (context.canPop())
                    context.pop();
                  else
                    context.go('/profile');
                },
              )),
            ),
          ],
        ),
      ],
    );
  }
}
