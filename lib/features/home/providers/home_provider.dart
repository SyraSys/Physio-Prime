import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/home_repository.dart';
import '../domain/category_model.dart';
import '../domain/location_model.dart';
import '../domain/symptom_model.dart';

// Selected City & Area state
final selectedCityProvider = StateProvider<String>((ref) => 'Nagpur');
final selectedAreaProvider = StateProvider<String?>((ref) => null);

// Selected Mode: 'all', 'home', 'online'
final selectedModeProvider = StateProvider<String>((ref) => 'all');

// Master locations future provider
final locationsProvider = FutureProvider<MasterLocationsModel>((ref) async {
  final repo = ref.read(homeRepositoryProvider);
  return repo.getLocations();
});

// Categories future provider
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.read(homeRepositoryProvider);
  return repo.getCategories();
});

// Symptoms future provider
final symptomsProvider = FutureProvider<List<SymptomModel>>((ref) async {
  final repo = ref.read(homeRepositoryProvider);
  return repo.getSymptoms();
});
