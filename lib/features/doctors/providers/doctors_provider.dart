import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/doctors_repository.dart';
import '../domain/doctor_model.dart';
import '../domain/review_model.dart';

class DoctorFilterState {
  final String? area;
  final String? symptom;
  final String? mode;
  final String? category;
  final String? search;
  final String? gender;

  const DoctorFilterState({
    this.area,
    this.symptom,
    this.mode,
    this.category,
    this.search,
    this.gender,
  });

  DoctorFilterState copyWith({
    String? area,
    String? symptom,
    String? mode,
    String? category,
    String? search,
    String? gender,
    bool clearArea = false,
    bool clearSymptom = false,
    bool clearCategory = false,
  }) {
    return DoctorFilterState(
      area: clearArea ? null : (area ?? this.area),
      symptom: clearSymptom ? null : (symptom ?? this.symptom),
      mode: mode ?? this.mode,
      category: clearCategory ? null : (category ?? this.category),
      search: search ?? this.search,
      gender: gender ?? this.gender,
    );
  }
}

final doctorFilterProvider = StateProvider<DoctorFilterState>((ref) {
  return const DoctorFilterState();
});

/// List of Doctors reacting to current filter state
final doctorsListProvider = FutureProvider<List<DoctorModel>>((ref) async {
  final repo = ref.read(doctorsRepositoryProvider);
  final filter = ref.watch(doctorFilterProvider);

  return repo.getDoctors(
    area: filter.area,
    symptom: filter.symptom,
    mode: filter.mode,
    category: filter.category,
    search: filter.search,
    gender: filter.gender,
  );
});

/// Doctor Detailed Profile
final doctorDetailProvider = FutureProvider.family<DoctorModel, String>((ref, slugOrId) async {
  final repo = ref.read(doctorsRepositoryProvider);
  return repo.getDoctorDetail(slugOrId);
});

/// Doctor Reviews
final doctorReviewsProvider = FutureProvider.family<List<ReviewModel>, String>((ref, slugOrId) async {
  final repo = ref.read(doctorsRepositoryProvider);
  return repo.getDoctorReviews(slugOrId);
});
