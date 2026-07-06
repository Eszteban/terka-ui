import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/transit_repository.dart';
import '../utils/main_screen_utils.dart';
import 'plan_response_controller.dart';
import '../widgets/forms/route_plan_form.dart';

class RoutePlannerState {
  final Map<String, dynamic>? planResponseJson;
  final String planResponseText;
  final String lastPlanQuery;
  final String? lastFromPlace;
  final String? lastToPlace;
  final DateTime? lastPlanDateTime;
  final bool isPlanLoading;
  final bool isLoadingMore;
  final String? nextPageCursor;
  final bool hasMeaningfulPlanResponse;

  const RoutePlannerState({
    this.planResponseJson,
    required this.planResponseText,
    required this.lastPlanQuery,
    this.lastFromPlace,
    this.lastToPlace,
    this.lastPlanDateTime,
    required this.isPlanLoading,
    required this.isLoadingMore,
    this.nextPageCursor,
    required this.hasMeaningfulPlanResponse,
  });

  factory RoutePlannerState.initial() {
    return const RoutePlannerState(
      planResponseText: '',
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
  }) {
    return RoutePlannerState(
      planResponseJson: clearPlanResponseJson ? null : (planResponseJson ?? this.planResponseJson),
      planResponseText: planResponseText ?? this.planResponseText,
      lastPlanQuery: lastPlanQuery ?? this.lastPlanQuery,
      lastFromPlace: clearLastFromPlace ? null : (lastFromPlace ?? this.lastFromPlace),
      lastToPlace: clearLastToPlace ? null : (lastToPlace ?? this.lastToPlace),
      lastPlanDateTime: clearLastPlanDateTime ? null : (lastPlanDateTime ?? this.lastPlanDateTime),
      isPlanLoading: isPlanLoading ?? this.isPlanLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      nextPageCursor: clearNextPageCursor ? null : (nextPageCursor ?? this.nextPageCursor),
      hasMeaningfulPlanResponse: hasMeaningfulPlanResponse ?? this.hasMeaningfulPlanResponse,
    );
  }
}

class RoutePlannerCubit extends Cubit<RoutePlannerState> {
  final TransitRepository _transitRepository;

  RoutePlannerCubit({
    required TransitRepository transitRepository,
  })  : _transitRepository = transitRepository,
        super(RoutePlannerState.initial());

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

    emit(state.copyWith(
      planResponseJson: result.responseJson,
      planResponseText: result.responseText,
      lastPlanQuery: result.query,
      lastFromPlace: fromPlace,
      lastToPlace: toPlace,
      lastPlanDateTime: dateTime,
      nextPageCursor: result.nextPageCursor,
      hasMeaningfulPlanResponse: result.hasMeaningfulResponse,
    ));
  }

  void setLoading(bool isLoading) {
    emit(state.copyWith(isPlanLoading: isLoading));
  }

  void clearSearch() {
    emit(state.copyWith(
      clearPlanResponseJson: true,
      planResponseText: '',
      lastPlanQuery: '',
      clearLastFromPlace: true,
      clearLastToPlace: true,
      clearLastPlanDateTime: true,
      clearNextPageCursor: true,
      isPlanLoading: false,
      isLoadingMore: false,
      hasMeaningfulPlanResponse: false,
    ));
  }

  Future<bool> loadMorePlans() async {
    if (state.isLoadingMore) return false;
    final fromPlace = state.lastFromPlace;
    final toPlace = state.lastToPlace;
    final dateTime = state.lastPlanDateTime;
    final cursor = state.nextPageCursor;

    if (fromPlace == null ||
        toPlace == null ||
        dateTime == null ||
        cursor == null ||
        cursor.trim().isEmpty) {
      return false;
    }

    emit(state.copyWith(isLoadingMore: true));

    try {
      final nextJson = await _transitRepository.fetchRoutePlans(
        fromPlace: fromPlace,
        toPlace: toPlace,
        dateTime: dateTime,
        nextPageCursor: cursor,
      );

      if (nextJson == null) {
        emit(state.copyWith(isLoadingMore: false));
        return false;
      }

      final merged = MainScreenUtils.mergePlanResponses(state.planResponseJson, nextJson);
      final plan = PlanResponseController.extractPlan(nextJson);
      final nextCursor = PlanResponseController.extractNextPageCursor(plan);

      emit(state.copyWith(
        planResponseJson: merged,
        planResponseText: const JsonEncoder.withIndent('  ').convert(merged),
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
