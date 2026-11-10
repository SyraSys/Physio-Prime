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
  final String? nextAvailable;
  final num? minFee;
  final num? maxFee;

  const DoctorModel({
    required this.id,
    required this.slug,
    required this.name,
    required this.title,
    required this.specialty,
    this.photo,
    this.rating = 4.9,
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
    this.nextAvailable,
    this.minFee,
    this.maxFee,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    num? parsedMinFee;
    num? parsedMaxFee;
    if (json['feeRange'] is Map<String, dynamic>) {
      final fr = json['feeRange'] as Map<String, dynamic>;
      parsedMinFee = fr['min'] is num ? fr['min'] : num.tryParse(fr['min']?.toString() ?? '');
      parsedMaxFee = fr['max'] is num ? fr['max'] : num.tryParse(fr['max']?.toString() ?? '');
    }

    return DoctorModel(
      id: json['id']?.toString() ?? json['slug']?.toString() ?? '',
      slug: json['slug']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Physiotherapist',
      title: json['title']?.toString() ?? 'Senior Physiotherapist',
      specialty: json['specialty']?.toString() ?? 'Physiotherapy Specialist',
      photo: json['photo']?.toString(),
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 4.9,
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
      categories: (json['categories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      nextAvailable: json['nextAvailable']?.toString(),
      minFee: parsedMinFee,
      maxFee: parsedMaxFee,
    );
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
    if (nextAvailable == null || nextAvailable!.isEmpty) return 'Oct 5';
    try {
      final dt = DateTime.parse(nextAvailable!);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return nextAvailable!;
    }
  }
}
