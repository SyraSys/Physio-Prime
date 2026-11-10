class SymptomModel {
  final String id;
  final String title;
  final String slug;
  final String? iconName;
  final String description;
  final List<String> symptomsList;
  final String? treatment;
  final List<String> popularFor;
  final String? recoveryEstimate;
  final String? department;
  final String? image;
  final int? sortOrder;

  const SymptomModel({
    required this.id,
    required this.title,
    required this.slug,
    this.iconName,
    required this.description,
    this.symptomsList = const [],
    this.treatment,
    this.popularFor = const [],
    this.recoveryEstimate,
    this.department,
    this.image,
    this.sortOrder,
  });

  factory SymptomModel.fromJson(Map<String, dynamic> json) {
    // Parse symptomsList which can be a String (semicolon separated) or List
    List<String> parsedSymptoms = [];
    if (json['symptomsList'] is List) {
      parsedSymptoms = (json['symptomsList'] as List).map((e) => e.toString().trim()).toList();
    } else if (json['symptomsList'] is String) {
      parsedSymptoms = (json['symptomsList'] as String)
          .split(';')
          .map((e) => e.trim())
          .filter((e) => e.isNotEmpty)
          .toList();
    }

    // Parse popularFor which can be a List or String
    List<String> parsedPopularFor = [];
    if (json['popularFor'] is List) {
      parsedPopularFor = (json['popularFor'] as List).map((e) => e.toString().trim()).toList();
    } else if (json['popularFor'] is String) {
      parsedPopularFor = [json['popularFor'].toString()];
    }

    String? rawImage = json['image']?.toString();
    if (rawImage != null && rawImage.startsWith('/')) {
      rawImage = 'https://www.physio-prime.in$rawImage';
    }

    return SymptomModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      iconName: json['iconName']?.toString(),
      description: json['description']?.toString() ?? '',
      symptomsList: parsedSymptoms,
      treatment: json['treatment']?.toString(),
      popularFor: parsedPopularFor,
      recoveryEstimate: json['recoveryEstimate']?.toString(),
      department: (parsedPopularFor.isNotEmpty ? parsedPopularFor.first : null) ??
          json['department']?.toString() ??
          'Musculoskeletal / Orthopedic',
      image: rawImage,
      sortOrder: json['sortOrder'] is int ? json['sortOrder'] : int.tryParse(json['sortOrder']?.toString() ?? ''),
    );
  }
}

extension IterableFilterExtension<E> on Iterable<E> {
  Iterable<E> filter(bool Function(E element) test) => where(test);
}
