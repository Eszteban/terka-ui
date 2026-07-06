import '../models/pass_type.dart';

abstract class PassTypeRepository {
  Future<List<PassType>> fetchPassTypes();
  Future<void> savePassType(PassType passType);
  Future<void> deletePassType(String id);
}
