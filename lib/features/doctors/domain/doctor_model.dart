class DoctorLocation {
  final String? area;
  final String? city;
  final String? address;

  const DoctorLocation({this.area, this.city, this.address});

  factory DoctorLocation.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return DoctorLocation(
        area: json['area']?.toString(),
        city: json['city']?.toString(),
        address: json['address']?.toString(),
      );
    }
    return const DoctorLocation();
  }

  String get displayString {
    final parts = [area, city].where((e) => e != null && e.isNotEmpty).toList();
    return parts.isEmpty ? 'Nagpur' : parts.join(', ');
  }
}

class DoctorServiceLocation {
  final int? id;
  final String? name;
  final String? area;
  final String? city;
  final bool active;
  final bool isPrimary;

  const DoctorServiceLocation({
    this.id,
    this.name,
    this.area,
    this.city,
    this.active = true,
    this.isPrimary = false,
  });

  factory DoctorServiceLocation.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return DoctorServiceLocation(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
        name: json['name']?.toString(),
        area: json['area']?.toString(),
        city: json['city']?.toString(),
        active: json['active'] == true,
        isPrimary: json['isPrimary'] == true,
      );
    }
    return const DoctorServiceLocation();
  }
}

class DoctorFees {
  final num home;
  final num online;

  const DoctorFees({this.home = 1000, this.online = 599});

  factory DoctorFees.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return DoctorFees(
        home: json['home'] is num ? json['home'] : (num.tryParse(json['home']?.toString() ?? '1000') ?? 1000),
        online: json['online'] is num ? json['online'] : (num.tryParse(json['online']?.toString() ?? '599') ?? 599),
      );
    }
    return const DoctorFees();
  }
}

class DoctorCategoryOption {
  final String categoryId;
  final String slug;
  final String title;
  final num feeHome;
  final num feeOnline;

  const DoctorCategoryOption({
    required this.categoryId,
    required this.slug,
    required this.title,
    required this.feeHome,
    required this.feeOnline,
  });

  factory DoctorCategoryOption.fromJson(dynamic json) {
    if (json is Map) {
      return DoctorCategoryOption(
        categoryId: json['categoryId']?.toString() ?? json['id']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        title: json['title']?.toString() ?? json['name']?.toString() ?? '',
        feeHome: json['feeHome'] is num
            ? json['feeHome']
            : (num.tryParse(json['feeHome']?.toString() ?? '0') ?? 0),
        feeOnline: json['feeOnline'] is num
            ? json['feeOnline']
            : (num.tryParse(json['feeOnline']?.toString() ?? '0') ?? 0),
      );
    }
    return const DoctorCategoryOption(
      categoryId: '',
      slug: '',
      title: '',
      feeHome: 0,
      feeOnline: 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'slug': slug,
    'title': title,
    'feeHome': feeHome,
    'feeOnline': feeOnline,
  };
}

class DoctorModel {
  final String id;
  final String slug;
  final String name;
  final String title;
  final String specialty;
  final String? photo;
  final double rating;
  final int reviewCount;
  final int experienceYears;
  final int patientsTreated;
  final List<String> languages;
  final DoctorLocation location;
  final DoctorFees fees;
  final num? feePaise;
  final bool verified;
  final bool featured;
  final bool homeVisitsEnabled;
  final String? gender;
  final String bio;
  final List<String> education;
  final List<String> experience;
  final Map<String, dynamic>? registration;
  final List<String> expertise;
  final List<String> treatments;
  final List<String> categories;
  final List<DoctorCategoryOption> categoryOptions;
  final List<DoctorServiceLocation> serviceLocations;
  final String? nextAvailable;
  final num? minFee;
  final num? maxFee;
  final String? distance;

  const DoctorModel({
    required this.id,
    required this.slug,
    required this.name,
    required this.title,
    required this.specialty,
    this.photo,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.experienceYears = 5,
    this.patientsTreated = 0,
    this.languages = const [],
    this.location = const DoctorLocation(),
    this.fees = const DoctorFees(),
    this.feePaise,
    this.verified = true,
    this.featured = false,
    this.homeVisitsEnabled = true,
    this.gender,
    this.bio = '',
    this.education = const [],
    this.experience = const [],
    this.registration,
    this.expertise = const [],
    this.treatments = const [],
    this.categories = const [],
    this.categoryOptions = const [],
    this.serviceLocations = const [],
    this.nextAvailable,
    this.minFee,
    this.maxFee,
    this.distance,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    num? parsedMinFee;
    num? parsedMaxFee;
    if (json['feeRange'] is Map<String, dynamic>) {
      final fr = json['feeRange'] as Map<String, dynamic>;
      parsedMinFee = fr['min'] is num ? fr['min'] : num.tryParse(fr['min']?.toString() ?? '');
      parsedMaxFee = fr['max'] is num ? fr['max'] : num.tryParse(fr['max']?.toString() ?? '');
    }

    final rawName = json['name']?.toString().trim() ?? 'Physiotherapist';
    final rawTitle = json['title']?.toString().trim() ?? 'Senior Consultant Physiotherapist';
    String rawSpecialty = json['specialty']?.toString().trim() ?? '';
    if (rawSpecialty.isEmpty) {
      rawSpecialty = rawTitle.isNotEmpty ? rawTitle : 'Physiotherapy Specialist';
    }

    final rawRating = (json['rating'] is num) ? (json['rating'] as num).toDouble() : 0.0;

    // Handle categories list where items may be Maps or Strings:
    final List<String> parsedCategories = [];
    final List<DoctorCategoryOption> parsedCategoryOptions = [];
    if (json['categories'] is List) {
      for (final item in json['categories'] as List) {
        if (item is Map) {
          final s = item['slug']?.toString();
          final t = item['title']?.toString();
          if (s != null && s.isNotEmpty) parsedCategories.add(s);
          if (t != null && t.isNotEmpty && t != s) parsedCategories.add(t);
          parsedCategoryOptions.add(DoctorCategoryOption.fromJson(item));
        } else if (item != null) {
          final str = item.toString().trim();
          if (str.isNotEmpty) parsedCategories.add(str);
        }
      }
    }

    // Handle locations list
    final List<DoctorServiceLocation> parsedLocations = [];
    if (json['locations'] is List) {
      for (final loc in json['locations'] as List) {
        parsedLocations.add(DoctorServiceLocation.fromJson(loc));
      }
    }

    return DoctorModel(
      id: json['id']?.toString() ?? json['slug']?.toString() ?? '',
      slug: json['slug']?.toString() ?? json['id']?.toString() ?? '',
      name: rawName,
      title: rawTitle,
      specialty: rawSpecialty,
      photo: json['photo']?.toString(),
      rating: rawRating,
      reviewCount: json['reviewCount'] is int ? json['reviewCount'] : int.tryParse(json['reviewCount']?.toString() ?? '0') ?? 0,
      experienceYears: json['experienceYears'] is int ? json['experienceYears'] : int.tryParse(json['experienceYears']?.toString() ?? '5') ?? 5,
      patientsTreated: json['patientsTreated'] is int ? json['patientsTreated'] : int.tryParse(json['patientsTreated']?.toString() ?? '0') ?? 0,
      languages: (json['languages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const ['English', 'Hindi'],
      location: DoctorLocation.fromJson(json['location']),
      fees: DoctorFees.fromJson(json['fees']),
      feePaise: json['feePaise'] is num ? json['feePaise'] : null,
      verified: json['verified'] == true,
      featured: json['featured'] == true,
      homeVisitsEnabled: json['homeVisitsEnabled'] != false,
      gender: json['gender']?.toString(),
      bio: json['bio']?.toString() ?? '',
      education: (json['education'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      experience: (json['experience'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      registration: json['registration'] is Map<String, dynamic> ? json['registration'] : null,
      expertise: (json['expertise'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      treatments: (json['treatments'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      categories: parsedCategories,
      categoryOptions: parsedCategoryOptions,
      serviceLocations: parsedLocations,
      nextAvailable: json['nextAvailable']?.toString(),
      minFee: parsedMinFee,
      maxFee: parsedMaxFee,
      distance: json['distance']?.toString(),
    );
  }

  DoctorModel copyWith({
    String? id,
    String? slug,
    String? name,
    String? title,
    String? specialty,
    String? photo,
    double? rating,
    int? reviewCount,
    int? experienceYears,
    int? patientsTreated,
    List<String>? languages,
    DoctorLocation? location,
    DoctorFees? fees,
    num? feePaise,
    bool? verified,
    bool? featured,
    bool? homeVisitsEnabled,
    String? gender,
    String? bio,
    List<String>? education,
    List<String>? experience,
    Map<String, dynamic>? registration,
    List<String>? expertise,
    List<String>? treatments,
    List<String>? categories,
    List<DoctorCategoryOption>? categoryOptions,
    List<DoctorServiceLocation>? serviceLocations,
    String? nextAvailable,
    num? minFee,
    num? maxFee,
    String? distance,
  }) {
    return DoctorModel(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      title: title ?? this.title,
      specialty: specialty ?? this.specialty,
      photo: photo ?? this.photo,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      experienceYears: experienceYears ?? this.experienceYears,
      patientsTreated: patientsTreated ?? this.patientsTreated,
      languages: languages ?? this.languages,
      location: location ?? this.location,
      fees: fees ?? this.fees,
      feePaise: feePaise ?? this.feePaise,
      verified: verified ?? this.verified,
      featured: featured ?? this.featured,
      homeVisitsEnabled: homeVisitsEnabled ?? this.homeVisitsEnabled,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      education: education ?? this.education,
      experience: experience ?? this.experience,
      registration: registration ?? this.registration,
      expertise: expertise ?? this.expertise,
      treatments: treatments ?? this.treatments,
      categories: categories ?? this.categories,
      categoryOptions: categoryOptions ?? this.categoryOptions,
      serviceLocations: serviceLocations ?? this.serviceLocations,
      nextAvailable: nextAvailable ?? this.nextAvailable,
      minFee: minFee ?? this.minFee,
      maxFee: maxFee ?? this.maxFee,
      distance: distance ?? this.distance,
    );
  }

  String get ratingDisplay => rating > 0 ? rating.toStringAsFixed(1) : 'New';

  String get distanceDisplay {
    if (distance != null && distance!.isNotEmpty) return distance!;
    final dist = 0.8 + ((name.hashCode.abs() % 18) / 10.0);
    return '${dist.toStringAsFixed(1)} km away';
  }

  num get startingFee => minFee ?? (fees.online > 0 ? fees.online : (fees.home > 0 ? fees.home : 1));

  String get consultationFeeDisplay {
    if (minFee != null && maxFee != null) {
      if (minFee == maxFee) {
        return '₹$maxFee/session';
      }
      return '₹$minFee-1,000 / session';
    }
    if (fees.home > 0 && fees.online > 0 && fees.home != fees.online) {
      final low = fees.online < fees.home ? fees.online : fees.home;
      final high = fees.online > fees.home ? fees.online : fees.home;
      return '₹$low-$high / session';
    }
    return '₹${fees.home}/session';
  }

  String get nextAvailableDisplay {
    if (nextAvailable == null || nextAvailable!.isEmpty) return 'Available Today';
    try {
      final dt = DateTime.parse(nextAvailable!);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return nextAvailable!;
    }
  }
}
