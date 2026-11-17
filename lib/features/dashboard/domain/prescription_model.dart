import '../../../core/utils/json_utils.dart';

class MedicationItem {
  final String name;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? instructions;

  const MedicationItem({required this.name, this.dosage, this.frequency, this.duration, this.instructions});

  static MedicationItem? tryParse(dynamic raw) {
    final asText = Json.string(raw);
    if (asText != null && raw is String) return MedicationItem(name: asText);
    final json = Json.map(raw);
    if (json == null) return null;
    final name = Json.string(Json.pick(json, const ['name', 'medicine', 'medication', 'drug', 'exercise', 'title']));
    if (name == null) return null;
    return MedicationItem(
      name: name,
      dosage: Json.string(Json.pick(json, const ['dosage', 'dose', 'strength'])),
      frequency: Json.string(Json.pick(json, const ['frequency', 'timing', 'schedule'])),
      duration: Json.string(Json.pick(json, const ['duration', 'days', 'period'])),
      instructions: Json.string(Json.pick(json, const ['instructions', 'notes', 'note'])),
    );
  }
}

/// A prescription from `GET /me/prescriptions`.
///
/// The response shape for this endpoint is not specified in the work guide, so
/// parsing accepts common key variants and only exposes data that is present.
class PrescriptionModel {
  final String id;
  final String? appointmentId;
  final String? doctorName;
  final DateTime? issuedAt;
  final String? diagnosis;
  final String? instructions;
  final List<MedicationItem> medications;

  /// Only set when the backend supplies an absolute http(s) document URL.
  final Uri? documentUrl;

  const PrescriptionModel({
    required this.id,
    this.appointmentId,
    this.doctorName,
    this.issuedAt,
    this.diagnosis,
    this.instructions,
    this.medications = const [],
    this.documentUrl,
  });

  static PrescriptionModel? tryParse(dynamic raw) {
    final json = Json.map(raw);
    if (json == null) return null;
    final id = Json.string(json['id']);
    if (id == null) return null;
    final doctor = Json.map(json['doctor']);
    final appointment = Json.map(json['appointment']);

    final medsRaw = Json.pick(json, const ['medications', 'medicines', 'items', 'drugs', 'exercises']);
    final meds = Json.list(medsRaw).map(MedicationItem.tryParse).whereType<MedicationItem>().toList(growable: false);

    return PrescriptionModel(
      id: id,
      appointmentId: Json.string(json['appointmentId']) ?? Json.string(appointment?['id']),
      doctorName:
          Json.string(doctor?['name']) ??
          Json.string(json['doctorName']) ??
          Json.string(Json.map(appointment?['doctor'])?['name']),
      issuedAt: Json.dateTime(Json.pick(json, const ['issuedAt', 'createdAt', 'date'])),
      diagnosis: Json.string(Json.pick(json, const ['diagnosis', 'title', 'condition'])),
      instructions: Json.string(Json.pick(json, const ['instructions', 'notes', 'advice'])),
      medications: meds,
      documentUrl: _safeUrl(Json.string(Json.pick(json, const ['documentUrl', 'pdfUrl', 'fileUrl', 'url']))),
    );
  }

  static Uri? _safeUrl(String? value) {
    if (value == null) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasAuthority) return null;
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    return uri;
  }
}
