import 'package:get_it/get_it.dart';
import 'services/ticket_api_service.dart';
import 'services/transit_api_service.dart';
import 'services/pass_type_api_service.dart';
import 'repositories/ticket_repository.dart';
import 'repositories/http_ticket_repository.dart';
import 'repositories/transit_repository.dart';
import 'repositories/http_transit_repository.dart';
import 'repositories/pass_type_repository.dart';
import 'repositories/http_pass_type_repository.dart';
import 'repositories/news_repository.dart';
import 'repositories/rss_news_repository.dart';
import 'controllers/navigation_cubit.dart';
import 'controllers/route_planner_cubit.dart';
import 'controllers/map_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Services
  sl.registerLazySingleton<TicketApiService>(() => const TicketApiService());
  sl.registerLazySingleton<TransitApiService>(() => const TransitApiService());
  sl.registerLazySingleton<PassTypeApiService>(() => const PassTypeApiService());

  // Repositories
  sl.registerLazySingleton<TicketRepository>(
    () => HttpTicketRepository(apiService: sl<TicketApiService>()),
  );
  sl.registerLazySingleton<TransitRepository>(
    () => HttpTransitRepository(apiService: sl<TransitApiService>()),
  );
  sl.registerLazySingleton<PassTypeRepository>(
    () => HttpPassTypeRepository(apiService: sl<PassTypeApiService>()),
  );
  sl.registerLazySingleton<NewsRepository>(
    () => RssNewsRepository(),
  );


  // Cubits
  sl.registerFactory(() => NavigationCubit());
  sl.registerFactory(() => RoutePlannerCubit(transitRepository: sl<TransitRepository>()));
  sl.registerFactory(() => MapCubit());
}
