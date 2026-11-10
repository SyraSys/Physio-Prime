class CityLocation {
  final String name;
  final List<String> areas;

  const CityLocation({
    required this.name,
    required this.areas,
  });

  factory CityLocation.fromJson(Map<String, dynamic> json) {
    return CityLocation(
      name: json['name']?.toString() ?? '',
      areas: (json['areas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class MasterLocationsModel {
  final List<CityLocation> cities;
  final List<String> areas;
  final bool panIndia;

  const MasterLocationsModel({
    this.cities = const [],
    this.areas = const [],
    this.panIndia = true,
  });

  factory MasterLocationsModel.fromJson(Map<String, dynamic> json) {
    List<CityLocation> parsedCities = [];
    if (json['cities'] is List) {
      parsedCities = (json['cities'] as List)
          .map((c) => CityLocation.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    List<String> parsedAreas = [];
    if (json['areas'] is List) {
      parsedAreas = (json['areas'] as List).map((a) => a.toString()).toList();
    }

    // Fallback if cities is empty but areas exist (e.g. Nagpur default)
    if (parsedCities.isEmpty && parsedAreas.isNotEmpty) {
      parsedCities.add(CityLocation(name: 'Nagpur', areas: parsedAreas));
    }

    return MasterLocationsModel(
      cities: parsedCities,
      areas: parsedAreas,
      panIndia: json['panIndia'] == true,
    );
  }
}
