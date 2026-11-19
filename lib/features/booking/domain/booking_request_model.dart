import '../../../core/utils/json_utils.dart';

/// Consultation delivery mode accepted by the backend.
enum ConsultationMode {
  home('home', 'Home Visit'),
  online('online', 'Video Consultation');

  final String apiValue;
  final String label;
  const ConsultationMode(this.apiValue, this.label);

  static ConsultationMode? tryParse(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'home':
      case 'home_visit':
      case 'home-visit':
        return ConsultationMode.home;
      case 'online':
      case 'video':
      case 'telehealth':
        return ConsultationMode.online;
    }
    return null;
  }
}

enum PatientRelation {
  self('self', 'For Myself'),
  family('family', 'For Family');

  final String apiValue;
  final String label;
  const PatientRelation(this.apiValue, this.label);
}

enum PaymentMode {
  prepay('prepay', 'Pay now', 'Secure online payment via Razorpay'),
  postpay('postpay', 'Pay after consultation', 'Pay your physiotherapist after the session');

  final String apiValue;
  final String label;
  final String description;
  const PaymentMode(this.apiValue, this.label, this.description);

  static PaymentMode? tryParse(String? value) {
    for (final m in PaymentMode.values) {
      if (m.apiValue == value?.trim().toLowerCase()) return m;
    }
    return null;
  }
}

enum PatientGender {
  male('male', 'Male'),
  female('female', 'Female'),
  other('other', 'Other');

  final String apiValue;
  final String label;
  const PatientGender(this.apiValue, this.label);
}

/// Doctor information carried through the booking flow.
class BookingDoctorInfo {
  final String slug;
  final String name;
  final String? title;
  final String? photo;
  final String? categoryId;
  final String? categoryTitle;
  final ConsultationMode initialMode;
  final bool homeVisitsEnabled;
  final int? feePaise;
  final String? conditionName;
  final String? symptomSlug;

  const BookingDoctorInfo({
    required this.slug,
    required this.name,
    this.title,
    this.photo,
    this.categoryId,
    this.categoryTitle,
    this.initialMode = ConsultationMode.home,
    this.homeVisitsEnabled = true,
    this.feePaise,
    this.conditionName,
    this.symptomSlug,
  });

  BookingDoctorInfo copyWith({
    String? title,
    String? photo,
    String? categoryId,
    String? categoryTitle,
    bool? homeVisitsEnabled,
    int? feePaise,
    String? conditionName,
    String? symptomSlug,
  }) {
    return BookingDoctorInfo(
      slug: slug,
      name: name,
      title: title ?? this.title,
      photo: photo ?? this.photo,
      categoryId: categoryId ?? this.categoryId,
      categoryTitle: categoryTitle ?? this.categoryTitle,
      initialMode: initialMode,
      homeVisitsEnabled: homeVisitsEnabled ?? this.homeVisitsEnabled,
      feePaise: feePaise ?? this.feePaise,
      conditionName: conditionName ?? this.conditionName,
      symptomSlug: symptomSlug ?? this.symptomSlug,
    );
  }

  static BookingDoctorInfo? fromRouteArgs(Object? extra, [Map<String, String> query = const {}]) {
    final map = Json.map(extra) ?? <String, dynamic>{};
    String? read(String key) => Json.string(map[key]) ?? Json.string(query[key]);

    final slug = read('doctorSlug') ?? read('slug') ?? read('doctorId');
    final name = read('doctorName');
    if (slug == null || name == null) return null;

    final feePaise = Json.integer(map['feePaise'] ?? query['feePaise']);

    return BookingDoctorInfo(
      slug: slug,
      name: name,
      title: read('doctorTitle'),
      photo: read('doctorPhoto'),
      categoryId: read('categoryId'),
      categoryTitle: read('categoryTitle'),
      initialMode: ConsultationMode.tryParse(read('mode')) ?? ConsultationMode.home,
      homeVisitsEnabled: Json.boolean(map['homeVisitsEnabled']) ?? true,
      feePaise: feePaise,
      conditionName: read('conditionName') ?? read('condition') ?? read('symptom'),
      symptomSlug: read('symptomSlug') ?? read('symptom'),
    );
  }
}

/// Doctor + mode + date + slot chosen on the slot screen.
class BookingSelection {
  final BookingDoctorInfo doctor;
  final ConsultationMode mode;

  /// Appointment date in `YYYY-MM-DD` (IST calendar date).
  final String date;
  final String slot;
  final String? conditionName;
  final String? slotDisplayTime;

  const BookingSelection({
    required this.doctor,
    required this.mode,
    required this.date,
    required this.slot,
    this.conditionName,
    this.slotDisplayTime,
  });
}

class BookingAddress {
  final String text;
  final String city;
  final String area;

  const BookingAddress({required this.text, required this.city, required this.area});

  Map<String, dynamic> toJson() => {'text': text, 'city': city, 'area': area};

  static BookingAddress? tryParse(dynamic raw) {
    final json = Json.map(raw);
    if (json == null) {
      final text = Json.string(raw);
      return text == null ? null : BookingAddress(text: text, city: '', area: '');
    }
    final text = Json.string(json['text']) ?? Json.string(json['line1']) ?? '';
    final city = Json.string(json['city']) ?? '';
    final area = Json.string(json['area']) ?? '';
    if (text.isEmpty && city.isEmpty && area.isEmpty) return null;
    return BookingAddress(text: text, city: city, area: area);
  }

  String get display => [text, area, city].where((e) => e.isNotEmpty).join(', ');
}

/// Body of `POST /appointments`.
class BookingRequest {
  final String doctorSlug;
  final String? categoryId;
  final ConsultationMode mode;
  final String date;
  final String slot;
  final String symptom;
  final String patientName;
  final String patientPhone;
  final String patientEmail;
  final PatientGender patientGender;
  final int patientAge;
  final num? patientWeight;
  final num? patientHeight;
  final PatientRelation patientRelation;
  final BookingAddress? address;
  final PaymentMode paymentMode;
  final int numberOfPatients;
  final String? specialRequirements;

  const BookingRequest({
    required this.doctorSlug,
    required this.categoryId,
    required this.mode,
    required this.date,
    required this.slot,
    required this.symptom,
    required this.patientName,
    required this.patientPhone,
    required this.patientEmail,
    required this.patientGender,
    required this.patientAge,
    this.patientWeight,
    this.patientHeight,
    required this.patientRelation,
    required this.address,
    required this.paymentMode,
    this.numberOfPatients = 1,
    this.specialRequirements,
  });

  Map<String, dynamic> toJson() => {
    'doctorSlug': doctorSlug,
    if (categoryId != null && categoryId!.isNotEmpty) 'categoryId': categoryId,
    'mode': mode.apiValue,
    'date': date,
    'slot': slot,
    'symptom': symptom,
    'patientName': patientName,
    'patientPhone': patientPhone,
    'patientEmail': patientEmail,
    'patientGender': patientGender.apiValue,
    'patientAge': patientAge,
    if (patientWeight != null && patientWeight! > 0) 'patientWeight': patientWeight,
    if (patientHeight != null && patientHeight! > 0) 'patientHeight': patientHeight,
    'patientRelation': patientRelation.apiValue,
    if (address != null) 'address': address!.toJson(),
    'paymentMode': paymentMode.apiValue,
    if (numberOfPatients > 1) 'numberOfPatients': numberOfPatients,
    if (specialRequirements != null && specialRequirements!.trim().isNotEmpty) ...{
      'specialRequirements': specialRequirements!.trim(),
      'notes': specialRequirements!.trim(),
    },
  };
}
