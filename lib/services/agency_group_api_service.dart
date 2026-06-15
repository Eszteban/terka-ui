import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/agency_group.dart';

class AgencyGroupApiService {
  const AgencyGroupApiService();

  Future<List<AgencyGroup>> fetchCustomAgencyGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('local_agency_groups_v1');
      if (raw == null || raw.trim().isEmpty) {
        return [];
      }
      final dynamic decoded = jsonDecode(raw);
      final groups = <AgencyGroup>[];
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            groups.add(AgencyGroup.fromJson(item.cast<String, dynamic>()));
          }
        }
      }
      return groups;
    } catch (e) {
      return [];
    }
  }

  Future<void> saveCustomAgencyGroup(AgencyGroup group) async {
    try {
      final groups = await fetchCustomAgencyGroups();
      final index = groups.indexWhere(
        (g) => g.name.toLowerCase() == group.name.toLowerCase(),
      );
      if (index != -1) {
        groups[index] = group;
      } else {
        groups.add(group);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'local_agency_groups_v1',
        jsonEncode(groups.map((g) => g.toJson()).toList()),
      );
    } catch (e) {
      // ignore
    }
  }
}
