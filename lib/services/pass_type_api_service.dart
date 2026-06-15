import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pass_type.dart';

class PassTypeApiService {
  const PassTypeApiService();

  Future<List<PassType>> fetchPassTypes() async {
    final prebaked = PassType.getPrebakedPassTypes();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('local_pass_types_v1');
      if (raw == null || raw.trim().isEmpty) {
        return prebaked;
      }
      final dynamic decoded = jsonDecode(raw);
      final list = <PassType>[];
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            list.add(PassType.fromJson(item.cast<String, dynamic>()));
          }
        }
      }
      return [...prebaked, ...list];
    } catch (e) {
      return prebaked;
    }
  }

  Future<void> savePassType(PassType passType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('local_pass_types_v1');
      final list = <PassType>[];
      if (raw != null && raw.trim().isNotEmpty) {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              list.add(PassType.fromJson(item.cast<String, dynamic>()));
            }
          }
        }
      }

      final index = list.indexWhere((p) => p.id == passType.id);
      if (index != -1) {
        list[index] = passType;
      } else {
        list.add(passType);
      }

      await prefs.setString(
        'local_pass_types_v1',
        jsonEncode(list.map((p) => p.toJson()).toList()),
      );
    } catch (e) {
      // ignore
    }
  }

  Future<void> deletePassType(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('local_pass_types_v1');
      final list = <PassType>[];
      if (raw != null && raw.trim().isNotEmpty) {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              list.add(PassType.fromJson(item.cast<String, dynamic>()));
            }
          }
        }
      }

      list.removeWhere((p) => p.id == id);

      await prefs.setString(
        'local_pass_types_v1',
        jsonEncode(list.map((p) => p.toJson()).toList()),
      );
    } catch (e) {
      // ignore
    }
  }
}
