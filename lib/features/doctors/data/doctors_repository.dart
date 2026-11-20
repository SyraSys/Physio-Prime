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
  final Map<String, DoctorModel> _detailCache = {};
  List<DoctorModel>? _cachedAllDoctors;
  DateTime? _lastFetchTime;

  DoctorsRepository(this._apiClient);

  /// Search & Filter Doctors directly from live PhysioPrime API.
  Future<List<DoctorModel>> getDoctors({
    String? city,
    String? area,
    String? symptom,
    String? mode,
    String? category,
    String? search,
    String? gender,
  }) async {
    final isUnfiltered = city == null &&
        area == null &&
        symptom == null &&
        mode == null &&
        category == null &&
        search == null &&
        gender == null;

    // Fast-path: Return cached unfiltered list immediately if fresh (5-minute TTL)
    if (isUnfiltered &&
        _cachedAllDoctors != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < const Duration(minutes: 5)) {
      return _cachedAllDoctors!;
    }

    // Fast-path for filtered queries: If all doctors are already cached in memory,
    // filter directly in-memory in 0ms without firing redundant HTTP requests across the network.
    if (!isUnfiltered &&
        _cachedAllDoctors != null &&
        _cachedAllDoctors!.isNotEmpty &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < const Duration(minutes: 5)) {
      return _applyFilters(
        doctors: _cachedAllDoctors!,
        city: city,
        area: area,
        symptom: symptom,
        mode: mode,
        category: category,
        search: search,
        gender: gender,
      );
    }

    try {
      final queryParams = <String, dynamic>{};
      if (city != null && city.isNotEmpty && city.toLowerCase() != 'all' && city.toLowerCase() != 'all areas') {
        queryParams['city'] = city;
      }
      if (area != null && area.isNotEmpty && area.toLowerCase() != 'all' && area.toLowerCase() != 'all areas') {
        final lower = area.toLowerCase();
        if (lower == 'nagpur' || lower == 'pune' || lower == 'mumbai') {
          queryParams['city'] = area;
        } else {
          queryParams['area'] = area;
        }
      }
      if (symptom != null && symptom.isNotEmpty) queryParams['symptom'] = symptom;
      if (mode != null && mode.isNotEmpty && mode != 'all') queryParams['mode'] = mode;
      if (category != null && category.isNotEmpty && category != 'all') queryParams['category'] = category;
      if (search != null && search.isNotEmpty) queryParams['q'] = search;
      if (gender != null && gender.isNotEmpty && gender != 'all') queryParams['gender'] = gender;

      final response = await _apiClient.get(
        '/doctors',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final list = response.data['doctors'] as List<dynamic>? ?? [];
      List<DoctorModel> doctors = [];
      if (list.isNotEmpty) {
        doctors = list.map((d) => DoctorModel.fromJson(d as Map<String, dynamic>)).toList();
      } else if (queryParams.isNotEmpty) {
        final allResponse = await _apiClient.get('/doctors');
        final allList = allResponse.data['doctors'] as List<dynamic>? ?? [];
        if (allList.isNotEmpty) {
          doctors = allList.map((d) => DoctorModel.fromJson(d as Map<String, dynamic>)).toList();
        }
      }

      if (doctors.isEmpty) return const [];

      if (isUnfiltered || _cachedAllDoctors == null) {
        _cachedAllDoctors = doctors;
        _lastFetchTime = DateTime.now();
      }

      return _applyFilters(
        doctors: doctors,
        city: city,
        area: area,
        symptom: symptom,
        mode: mode,
        category: category,
        search: search,
        gender: gender,
      );
    } catch (_) {
      // If network fails but we have cached doctors, fall back to cached in-memory filtering
      if (_cachedAllDoctors != null && _cachedAllDoctors!.isNotEmpty) {
        return _applyFilters(
          doctors: _cachedAllDoctors!,
          city: city,
          area: area,
          symptom: symptom,
          mode: mode,
          category: category,
          search: search,
          gender: gender,
        );
      }
      return const [];
    }
  }

  /// High-speed 0ms in-memory filtering and detail enrichment
  List<DoctorModel> _applyFilters({
    required List<DoctorModel> doctors,
    String? city,
    String? area,
    String? symptom,
    String? mode,
    String? category,
    String? search,
    String? gender,
  }) {
    // Enrich with cached details if already in memory without blocking on network
    final enrichedDoctors = doctors.map((d) => _detailCache[d.slug] ?? d).toList();
    var result = enrichedDoctors;

    // Filter by Mode
    if (mode != null && mode.isNotEmpty && mode != 'all') {
      if (mode == 'home') {
        result = result.where((d) => d.homeVisitsEnabled).toList();
      } else if (mode == 'online') {
        result = result.where((d) => d.fees.online > 0).toList();
      }
    }

    // Filter by Location / Area
    if (area != null && area.isNotEmpty && area.toLowerCase() != 'all' && area.toLowerCase() != 'all areas') {
      final qArea = area.toLowerCase();
      final matchingArea = result.where((d) {
        final docArea = d.location.area?.toLowerCase() ?? '';
        final docCity = d.location.city?.toLowerCase() ?? '';
        final serviceMatch = d.serviceLocations.any((loc) =>
            (loc.area?.toLowerCase() ?? '').contains(qArea) ||
            (loc.city?.toLowerCase() ?? '').contains(qArea));
        return docArea.contains(qArea) || docCity.contains(qArea) || serviceMatch;
      }).toList();
      if (matchingArea.isNotEmpty) result = matchingArea;
    }

    // Filter by Gender
    if (gender != null && gender.isNotEmpty && gender != 'all') {
      result = result.where((d) => d.gender?.toLowerCase() == gender.toLowerCase()).toList();
    }

    // Filter by Search Query
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      result = result.where((d) {
        return d.name.toLowerCase().contains(q) ||
            d.specialty.toLowerCase().contains(q) ||
            d.title.toLowerCase().contains(q) ||
            d.treatments.any((t) => t.toLowerCase().contains(q)) ||
            d.expertise.any((e) => e.toLowerCase().contains(q)) ||
            d.location.displayString.toLowerCase().contains(q);
      }).toList();
    }

    // Filter by Category
    if (category != null && category.isNotEmpty && category != 'all') {
      final qCat = category.toLowerCase();
      final matchingCat = result.where((d) {
        return d.categoryOptions.any((opt) =>
                opt.slug.toLowerCase() == qCat ||
                opt.categoryId.toLowerCase() == qCat ||
                opt.title.toLowerCase().contains(qCat)) ||
            d.categories.any((c) => c.toLowerCase().contains(qCat)) ||
            d.specialty.toLowerCase().contains(qCat) ||
            d.title.toLowerCase().contains(qCat) ||
            d.expertise.any((e) => e.toLowerCase().contains(qCat));
      }).toList();
      if (matchingCat.isNotEmpty) result = matchingCat;
    }

    // Filter by Symptom
    if (symptom != null && symptom.isNotEmpty) {
      final qSym = symptom.toLowerCase().replaceAll('-', ' ');
      final matchingSym = result.where((d) {
        return d.categoryOptions.any((opt) => opt.slug.toLowerCase().contains(qSym) || opt.title.toLowerCase().contains(qSym)) ||
            d.specialty.toLowerCase().contains(qSym) ||
            d.bio.toLowerCase().contains(qSym) ||
            d.expertise.any((e) => e.toLowerCase().contains(qSym)) ||
            d.treatments.any((t) => t.toLowerCase().contains(qSym));
      }).toList();
      if (matchingSym.isNotEmpty) {
        result = matchingSym;
      }
    }

    return result;
  }

  /// Get Doctor Detailed Profile directly from live API
  Future<DoctorModel> getDoctorDetail(String slugOrId) async {
    if (_detailCache.containsKey(slugOrId)) {
      return _detailCache[slugOrId]!;
    }
    try {
      final response = await _apiClient.get('/doctors/$slugOrId');
      final docData = response.data['doctor'] as Map<String, dynamic>;
      final doc = DoctorModel.fromJson(docData);
      _detailCache[slugOrId] = doc;
      _detailCache[doc.slug] = doc;
      _detailCache[doc.id] = doc;
      return doc;
    } catch (_) {
      if (_detailCache.containsKey(slugOrId)) {
        return _detailCache[slugOrId]!;
      }
      rethrow;
    }
  }

  /// Get Doctor Reviews directly from live API
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
