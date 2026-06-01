class PlanResponseController {
  static Map<String, dynamic>? extractPlan(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    final data = json['data'];
    if (data is! Map) {
      return null;
    }
    final plan = data['plan'];
    if (plan is! Map) {
      return null;
    }
    return plan.cast<String, dynamic>();
  }

  static String? extractNextPageCursor(Map<String, dynamic>? plan) {
    if (plan == null) {
      return null;
    }

    final direct = plan['pageCursor'];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct;
    }

    final next = plan['nextPageCursor'];
    if (next is String && next.trim().isNotEmpty) {
      return next;
    }

    final pageInfo = plan['pageInfo'];
    if (pageInfo is Map) {
      final pageInfoNext = pageInfo['nextPageCursor'];
      if (pageInfoNext is String && pageInfoNext.trim().isNotEmpty) {
        return pageInfoNext;
      }
      final endCursor = pageInfo['endCursor'];
      if (endCursor is String && endCursor.trim().isNotEmpty) {
        return endCursor;
      }
    }

    return null;
  }
}
