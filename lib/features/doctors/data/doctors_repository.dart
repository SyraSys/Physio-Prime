import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/doctor_model.dart';
import '../domain/review_model.dart';

final doctorsRepositoryProvider = Provider<DoctorsRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return DoctorsRepository(apiClient);
});

class DoctorsRepository {
  final ApiClient _apiClient;

  DoctorsRepository(this._apiClient);

  /// Search & Filter Doctors
  Future<List<DoctorModel>> getDoctors({
    String? area,
    String? symptom,
    String? mode,
    String? category,
    String? search,
    String? gender,
  }) async {
    final queryParams = <String, dynamic>{};
    if (area != null && area.isNotEmpty && area != 'All') queryParams['area'] = area;
    if (symptom != null && symptom.isNotEmpty) queryParams['symptom'] = symptom;
    if (mode != null && mode.isNotEmpty && mode != 'all') queryParams['mode'] = mode;
    if (category != null && category.isNotEmpty) queryParams['category'] = category;
    if (search != null && search.isNotEmpty) queryParams['q'] = search;
    if (gender != null && gender.isNotEmpty && gender != 'all') queryParams['gender'] = gender;

    final response = await _apiClient.get(
      '/doctors',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final list = response.data['doctors'] as List<dynamic>? ?? [];
    return list.map((d) => DoctorModel.fromJson(d as Map<String, dynamic>)).toList();
  }

  /// Get Doctor Detailed Profile
  Future<DoctorModel> getDoctorDetail(String slugOrId) async {
    final response = await _apiClient.get('/doctors/$slugOrId');
    final docData = response.data['doctor'] as Map<String, dynamic>;
    return DoctorModel.fromJson(docData);
  }

  /// Get Doctor Reviews
  Future<List<ReviewModel>> getDoctorReviews(String slugOrId) async {
    try {
      final response = await _apiClient.get('/doctors/$slugOrId/reviews');
      final list = response.data['reviews'] as List<dynamic>? ?? [];
      return list.map((r) => ReviewModel.fromJson(r as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }
}
