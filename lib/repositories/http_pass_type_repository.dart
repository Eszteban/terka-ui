import '../models/pass_type.dart';
import '../services/pass_type_api_service.dart';
import 'pass_type_repository.dart';

class HttpPassTypeRepository implements PassTypeRepository {
  final PassTypeApiService _apiService;

  const HttpPassTypeRepository({
    required PassTypeApiService apiService,
  }) : _apiService = apiService;

  @override
  Future<List<PassType>> fetchPassTypes() {
    return _apiService.fetchPassTypes();
  }

  @override
  Future<void> savePassType(PassType passType) {
    return _apiService.savePassType(passType);
  }

  @override
  Future<void> deletePassType(String id) {
    return _apiService.deletePassType(id);
  }
}
