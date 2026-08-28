import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terka/theme/app_texts.dart';
import '../repositories/transit_repository.dart';
import '../services/graphql/graphql_queries.dart';
import '../utils/main_screen_utils.dart';
import '../utils/route_data_utils.dart';
import 'plan_response_controller.dart';
import '../widgets/forms/route_plan_form.dart';

class RoutePlannerState {
  final Map<String, dynamic>? planResponseJson;
  final String planResponseText;
  final List<Map<String, dynamic>> itineraries;
  final String lastPlanQuery;
  final String? lastFromPlace;
  final String? lastToPlace;
  final DateTime? lastPlanDateTime;
  final bool isPlanLoading;
  final bool isLoadingMore;
  final String? nextPageCursor;
  final bool hasMeaningfulPlanResponse;
  final Map<String, dynamic>? lastPlanVariables;

  const RoutePlannerState({
    this.planResponseJson,
    required this.planResponseText,
    this.itineraries = const [],
    required this.lastPlanQuery,
    this.lastFromPlace,
    this.lastToPlace,
    this.lastPlanDateTime,
    required this.isPlanLoading,
    required this.isLoadingMore,
    this.nextPageCursor,
    required this.hasMeaningfulPlanResponse,
    this.lastPlanVariables,
  });

  factory RoutePlannerState.initial() {
    return const RoutePlannerState(
      planResponseText: '',
      itineraries: [],
      lastPlanQuery: '',
      isPlanLoading: false,
      isLoadingMore: false,
      hasMeaningfulPlanResponse: false,
    );
  }

  RoutePlannerState copyWith({
    Map<String, dynamic>? planResponseJson,
    bool clearPlanResponseJson = false,
    String? planResponseText,
    List<Map<String, dynamic>>? itineraries,
    bool clearItineraries = false,
    String? lastPlanQuery,
    String? lastFromPlace,
    bool clearLastFromPlace = false,
    String? lastToPlace,
    bool clearLastToPlace = false,
    DateTime? lastPlanDateTime,
    bool clearLastPlanDateTime = false,
    bool? isPlanLoading,
    bool? isLoadingMore,
    String? nextPageCursor,
    bool clearNextPageCursor = false,
    bool? hasMeaningfulPlanResponse,
    Map<String, dynamic>? lastPlanVariables,
    bool clearLastPlanVariables = false,
  }) {
    return RoutePlannerState(
      planResponseJson: clearPlanResponseJson ? null : (planResponseJson ?? this.planResponseJson),
      planResponseText: planResponseText ?? this.planResponseText,
      itineraries: clearItineraries ? const [] : (itineraries ?? this.itineraries),
      lastPlanQuery: lastPlanQuery ?? this.lastPlanQuery,
      lastFromPlace: clearLastFromPlace ? null : (lastFromPlace ?? this.lastFromPlace),
      lastToPlace: clearLastToPlace ? null : (lastToPlace ?? this.lastToPlace),
      lastPlanDateTime: clearLastPlanDateTime ? null : (lastPlanDateTime ?? this.lastPlanDateTime),
      isPlanLoading: isPlanLoading ?? this.isPlanLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      nextPageCursor: clearNextPageCursor ? null : (nextPageCursor ?? this.nextPageCursor),
      hasMeaningfulPlanResponse: hasMeaningfulPlanResponse ?? this.hasMeaningfulPlanResponse,
      lastPlanVariables: clearLastPlanVariables ? null : (lastPlanVariables ?? this.lastPlanVariables),
    );
  }
}

class RoutePlannerCubit extends Cubit<RoutePlannerState> {
  final TransitRepository _transitRepository;

  RoutePlannerCubit({
    required TransitRepository transitRepository,
  })  : _transitRepository = transitRepository,
        super(RoutePlannerState.initial());

  Future<PlanSearchResult> searchRoutes({
    required String fromPlaceToken,
    required String toPlaceToken,
    List<double>? fromCoordinates,
    List<double>? toCoordinates,
    DateTime? selectedDate,
    TimeOfDay? departureTime,
    TimeOfDay? arrivalTime,
    bool planForNow = true,
    Set<String>? selectedTransportModes,
  }) async {
    emit(state.copyWith(isPlanLoading: true));

    final now = DateTime.now();
    final effectiveDate = planForNow ? now : (selectedDate ?? now);
    final fallbackTime = TimeOfDay.fromDateTime(now);
    final effectiveTime = planForNow
        ? fallbackTime
        : (arrivalTime ?? departureTime ?? fallbackTime);
    final arriveBy = !planForNow && arrivalTime != null;

    final dateString =
        '${effectiveDate.year.toString().padLeft(4, '0')}-${effectiveDate.month.toString().padLeft(2, '0')}-${effectiveDate.day.toString().padLeft(2, '0')}';
    final timeString =
        '${effectiveTime.hour.toString().padLeft(2, '0')}:${effectiveTime.minute.toString().padLeft(2, '0')}';

    final modes = selectedTransportModes != null && selectedTransportModes.isNotEmpty
        ? RouteDataUtils.toApiTransportModes(selectedTransportModes)
        : RouteDataUtils.toApiTransportModes(const {});

    final variables = <String, dynamic>{
      'arriveBy': arriveBy,
      'banned': <String, dynamic>{},
      'bikeReluctance': 1.0,
      'carReluctance': 1.0,
      'date': dateString,
      'fromPlace': fromPlaceToken,
      'modes': modes,
      'numItineraries': 15,
      'preferred': <String, dynamic>{},
      'time': timeString,
      'toPlace': toPlaceToken,
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

    try {
      final bodyMap = await _transitRepository.searchRoutePlans(variables: variables);
      if (bodyMap == null) {
        final errorResult = PlanSearchResult(
          hasMeaningfulResponse: false,
          responseText: AppTexts.apiResponseNotJson,
          query: planQuery,
          requestVariables: variables,
          fromPlaceToken: fromPlaceToken,
          toPlaceToken: toPlaceToken,
          fromCoordinates: fromCoordinates,
          toCoordinates: toCoordinates,
        );
        setPlanResult(errorResult);
        return errorResult;
      }

      final data = bodyMap['data'];
      final plan = data is Map ? data['plan'] : null;
      final itinerariesList = plan is Map ? plan['itineraries'] : null;
      final nextPageCursor = plan is Map
          ? PlanResponseController.extractNextPageCursor(plan.cast<String, dynamic>())
          : null;

      final result = PlanSearchResult(
        hasMeaningfulResponse: itinerariesList is List && itinerariesList.isNotEmpty,
        responseText: const JsonEncoder.withIndent('  ').convert(bodyMap),
        query: planQuery,
        requestVariables: variables,
        responseJson: bodyMap,
        nextPageCursor: nextPageCursor,
        fromPlaceToken: fromPlaceToken,
        toPlaceToken: toPlaceToken,
        fromCoordinates: fromCoordinates,
        toCoordinates: toCoordinates,
      );

      setPlanResult(result);
      return result;
    } catch (e) {
      final exResult = PlanSearchResult(
        hasMeaningfulResponse: false,
        responseText: AppTexts.apiException(e.toString()),
        query: planQuery,
        requestVariables: variables,
        fromPlaceToken: fromPlaceToken,
        toPlaceToken: toPlaceToken,
        fromCoordinates: fromCoordinates,
        toCoordinates: toCoordinates,
      );
      setPlanResult(exResult);
      return exResult;
    } finally {
      emit(state.copyWith(isPlanLoading: false));
    }
  }

  void setPlanResult(PlanSearchResult result) {
    final vars = result.requestVariables;
    String? fromPlace;
    String? toPlace;
    DateTime? dateTime;

    if (vars != null) {
      fromPlace = vars['fromPlace']?.toString();
      toPlace = vars['toPlace']?.toString();
      final dateStr = vars['date']?.toString() ?? '';
      final timeStr = vars['time']?.toString() ?? '';
      if (dateStr.isNotEmpty && timeStr.isNotEmpty) {
        try {
          final dateParts = dateStr.split('-');
          final timeParts = timeStr.split(':');
          dateTime = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );
        } catch (_) {}
      }
    }

    final extractedItineraries = result.responseJson != null
        ? RouteDataUtils.extractItinerariesFromJson(result.responseJson)
        : RouteDataUtils.extractItineraries(result.responseText);

    emit(state.copyWith(
      planResponseJson: result.responseJson,
      planResponseText: result.responseText,
      itineraries: extractedItineraries,
      lastPlanQuery: result.query,
      lastFromPlace: fromPlace,
      lastToPlace: toPlace,
      lastPlanDateTime: dateTime,
      nextPageCursor: result.nextPageCursor,
      hasMeaningfulPlanResponse: result.hasMeaningfulResponse,
      lastPlanVariables: vars,
    ));
  }

  void setLoading(bool isLoading) {
    emit(state.copyWith(isPlanLoading: isLoading));
  }

  void clearSearch() {
    emit(state.copyWith(
      clearPlanResponseJson: true,
      planResponseText: '',
      clearItineraries: true,
      lastPlanQuery: '',
      clearLastFromPlace: true,
      clearLastToPlace: true,
      clearLastPlanDateTime: true,
      clearNextPageCursor: true,
      isPlanLoading: false,
      isLoadingMore: false,
      hasMeaningfulPlanResponse: false,
      clearLastPlanVariables: true,
    ));
  }

  Future<bool> loadMorePlans() async {
    if (state.isLoadingMore) return false;
    final cursor = state.nextPageCursor;
    final lastVars = state.lastPlanVariables;

    if (cursor == null || cursor.trim().isEmpty || lastVars == null) {
      return false;
    }

    emit(state.copyWith(isLoadingMore: true));

    try {
      final nextJson = await _transitRepository.fetchRoutePlans(
        originalVariables: lastVars,
        nextPageCursor: cursor,
      );

      if (nextJson == null) {
        emit(state.copyWith(isLoadingMore: false));
        return false;
      }

      final merged = MainScreenUtils.mergePlanResponses(state.planResponseJson, nextJson);
      final plan = PlanResponseController.extractPlan(nextJson);
      final nextCursor = PlanResponseController.extractNextPageCursor(plan);
      final mergedItineraries = RouteDataUtils.extractItinerariesFromJson(merged);

      emit(state.copyWith(
        planResponseJson: merged,
        planResponseText: const JsonEncoder.withIndent('  ').convert(merged),
        itineraries: mergedItineraries,
        hasMeaningfulPlanResponse: MainScreenUtils.hasItineraries(merged),
        nextPageCursor: nextCursor,
        isLoadingMore: false,
      ));
      return true;
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
      return false;
    }
  }
}
