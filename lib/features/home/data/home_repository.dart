import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/category_model.dart';
import '../domain/location_model.dart';
import '../domain/symptom_model.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return HomeRepository(apiClient);
});

class HomeRepository {
  final ApiClient _apiClient;

  HomeRepository(this._apiClient);

  /// Fetch Master Locations (Cities and Areas)
  Future<MasterLocationsModel> getLocations() async {
    final response = await _apiClient.get('/doctors/locations/master');
    return MasterLocationsModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Fetch Clinical Specialties / Categories
  Future<List<CategoryModel>> getCategories() async {
    final response = await _apiClient.get('/categories');
    final list = response.data['categories'] as List<dynamic>? ?? [];
    return list.map((c) => CategoryModel.fromJson(c as Map<String, dynamic>)).toList();
  }

  /// Fetch Medical Symptoms / Conditions Catalogue
  Future<List<SymptomModel>> getSymptoms() async {
    final response = await _apiClient.get('/symptoms');
    final list = response.data['symptoms'] as List<dynamic>? ?? [];
    return list.map((s) => SymptomModel.fromJson(s as Map<String, dynamic>)).toList();
  }
}
