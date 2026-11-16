import 'package:flutter/material.dart';

import '../../../core/utils/ist_time.dart';
import '../../../core/utils/json_utils.dart';
import '../../booking/domain/booking_request_model.dart';

/// Tabs on the My Appointments screen.
enum AppointmentGroup { upcoming, completed, cancelled }

class AppointmentDoctor {
  final String? slug;
  final String name;
  final String? title;
  final String? photo;

  const AppointmentDoctor({this.slug, required this.name, this.title, this.photo});
}

/// An appointment from `GET /appointments`.
///
/// Fields mirror the booking request/response documented in the work guide.
/// Parsing is tolerant: anything not supplied by the backend is null and the
/// UI simply omits it.
class AppointmentModel {
  final String id;
  final AppointmentDoctor doctor;
  final String? categoryId;
  final ConsultationMode? mode;
  final String? date; // YYYY-MM-DD
  final String? slot;
  final String status;
  final String paymentStatus;
  final PaymentMode? paymentMode;
  final int? feePaise;
  final String? symptom;
  final String? patientName;
  final String? patientPhone;
  final String? patientEmail;
  final String? patientGender;
  final int? patientAge;
  final num? patientWeight;
  final num? patientHeight;
  final String? patientRelation;
  final BookingAddress? address;
  final bool videoJoinable;
  final bool reviewed;
  final String? cancelReason;
  final DateTime? createdAt;

  const AppointmentModel({
    required this.id,
    required this.doctor,
    this.categoryId,
    this.mode,
    this.date,
    this.slot,
    required this.status,
    required this.paymentStatus,
    this.paymentMode,
    this.feePaise,
    this.symptom,
    this.patientName,
    this.patientPhone,
    this.patientEmail,
    this.patientGender,
    this.patientAge,
    this.patientWeight,
    this.patientHeight,
    this.patientRelation,
    this.address,
    this.videoJoinable = false,
    this.reviewed = false,
    this.cancelReason,
    this.createdAt,
  });

  static AppointmentModel? tryParse(dynamic raw) {
    final json = Json.map(raw);
    if (json == null) return null;
    final id = Json.string(json['id']);
    if (id == null) return null;

    final doctorJson = Json.map(json['doctor']);
    final doctor = AppointmentDoctor(
      slug:
          Json.string(json['doctorSlug']) ??
          Json.string(doctorJson?['slug']) ??
          Json.string(doctorJson?['id']) ??
          Json.string(json['doctorId']),
      name: Json.string(doctorJson?['name']) ?? Json.string(json['doctorName']) ?? 'Physiotherapist',
      title: Json.string(doctorJson?['title']) ?? Json.string(doctorJson?['specialty']),
      photo: Json.string(doctorJson?['photo']) ?? Json.string(doctorJson?['photoUrl']),
    );

    final patient = Json.map(json['patient']);
    dynamic p(String flatKey, String nestedKey) => json[flatKey] ?? patient?[nestedKey];

    final review = json['review'];
    return AppointmentModel(
      id: id,
      doctor: doctor,
      categoryId: Json.string(json['categoryId']),
      mode: ConsultationMode.tryParse(Json.string(json['mode'])),
      date: Json.string(json['date']),
      slot: Json.string(json['slot']),
      status: (Json.string(json['status']) ?? 'upcoming').toLowerCase(),
      paymentStatus: (Json.string(json['paymentStatus']) ?? 'pending').toLowerCase(),
      paymentMode: PaymentMode.tryParse(Json.string(json['paymentMode'])),
      feePaise: Json.integer(json['feePaise']),
      symptom: Json.string(json['symptom']),
      patientName: Json.string(p('patientName', 'name')),
      patientPhone: Json.string(p('patientPhone', 'phone')),
      patientEmail: Json.string(p('patientEmail', 'email')),
      patientGender: Json.string(p('patientGender', 'gender')),
      patientAge: Json.integer(p('patientAge', 'age')),
      patientWeight: Json.number(p('patientWeight', 'weight')),
      patientHeight: Json.number(p('patientHeight', 'height')),
      patientRelation: Json.string(p('patientRelation', 'relation')),
      address: BookingAddress.tryParse(json['address']),
      videoJoinable: Json.boolean(json['videoJoinable']) == true,
      reviewed:
          Json.boolean(json['reviewed']) == true || Json.boolean(json['hasReview']) == true || Json.map(review) != null,
      cancelReason: Json.string(json['cancelReason']) ?? Json.string(json['cancellationReason']),
      createdAt: Json.dateTime(json['createdAt']),
    );
  }

  DateTime? get calendarDate => IstTime.parseDate(date);

  /// Slot start in IST, when date and slot are parseable.
  DateTime? get startsAt {
    final d = calendarDate;
    if (d == null || slot == null) return null;
    return IstTime.slotStart(d, slot!) ?? d;
  }

  AppointmentGroup get group => AppointmentStatusStyle.groupOf(status);

  bool get isUpcoming => group == AppointmentGroup.upcoming;
  bool get isCompleted => group == AppointmentGroup.completed;
  bool get isCancelled => group == AppointmentGroup.cancelled;
  bool get isOnline => mode == ConsultationMode.online;
  bool get isPaid => AppointmentStatusStyle.isPaid(paymentStatus);

  bool get canCancel => isUpcoming;

  /// Rescheduling needs the doctor slug to query live availability.
  bool get canReschedule => isUpcoming && (doctor.slug?.isNotEmpty ?? false);
  bool get canReview => isCompleted && !reviewed;

  /// Video calls open only when the backend flags the session joinable.
  bool get canJoinVideo => isOnline && isUpcoming && videoJoinable;

  String get whenLabel {
    final d = calendarDate;
    final dateText = d == null ? (date ?? 'Date to be confirmed') : IstTime.longDate(d);
    return slot == null ? dateText : '$dateText · $slot';
  }
}

/// Maps backend status strings to groups, labels and colors.
class AppointmentStatusStyle {
  AppointmentStatusStyle._();

  static const _completed = {'completed', 'complete', 'finalized', 'done', 'finished'};
  static const _cancelled = {'cancelled', 'canceled', 'refunded', 'rejected', 'no_show', 'no-show', 'expired'};
  static const _paid = {'paid', 'captured', 'success', 'succeeded', 'completed'};

  static AppointmentGroup groupOf(String status) {
    final s = status.toLowerCase();
    if (_completed.contains(s)) return AppointmentGroup.completed;
    if (_cancelled.contains(s)) return AppointmentGroup.cancelled;
    return AppointmentGroup.upcoming;
  }

  static bool isPaid(String paymentStatus) => _paid.contains(paymentStatus.toLowerCase());

  static String _titleCase(String raw) => raw
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  static String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
      case 'confirmed':
      case 'scheduled':
        return 'Confirmed';
      case 'canceled':
        return 'Cancelled';
      default:
        return _titleCase(status);
    }
  }

  static Color statusColor(String status) {
    switch (groupOf(status)) {
      case AppointmentGroup.upcoming:
        return const Color(0xFF0891B2);
      case AppointmentGroup.completed:
        return const Color(0xFF16A34A);
      case AppointmentGroup.cancelled:
        return const Color(0xFFDC2626);
    }
  }

  static String paymentLabel(String paymentStatus) {
    final s = paymentStatus.toLowerCase();
    if (isPaid(s)) return 'Paid';
    switch (s) {
      case 'pending':
      case 'created':
        return 'Payment pending';
      case 'failed':
        return 'Payment failed';
      case 'refunded':
        return 'Refunded';
      case 'postpay':
      case 'pay_later':
        return 'Pay after visit';
      default:
        return _titleCase(s);
    }
  }

  static Color paymentColor(String paymentStatus) {
    final s = paymentStatus.toLowerCase();
    if (isPaid(s)) return const Color(0xFF16A34A);
    if (s == 'failed') return const Color(0xFFDC2626);
    if (s == 'refunded') return const Color(0xFF6366F1);
    return const Color(0xFFD97706);
  }
}
