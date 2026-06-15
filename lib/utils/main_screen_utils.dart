import 'dart:convert';
import '../controllers/plan_response_controller.dart';

class MainScreenUtils {
  static bool hasItineraries(Map<String, dynamic>? json) {
    final plan = PlanResponseController.extractPlan(json);
    final itineraries = plan?['itineraries'];
    return itineraries is List && itineraries.isNotEmpty;
  }

  static Map<String, dynamic> mergePlanResponses(
    Map<String, dynamic>? current,
    Map<String, dynamic> next,
  ) {
    if (current == null) {
      return next;
    }

    final merged = jsonDecode(jsonEncode(current)) as Map<String, dynamic>;

    final currentPlan = PlanResponseController.extractPlan(merged);
    final nextPlan = PlanResponseController.extractPlan(next);
    if (currentPlan == null || nextPlan == null) {
      return next;
    }

    final currentItineraries = currentPlan['itineraries'];
    final nextItineraries = nextPlan['itineraries'];
    if (currentItineraries is List && nextItineraries is List) {
      currentItineraries.addAll(nextItineraries);
    }

    currentPlan['pageCursor'] = PlanResponseController.extractNextPageCursor(nextPlan) ?? '';
    return merged;
  }
}
