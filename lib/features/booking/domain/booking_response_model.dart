import '../../../core/utils/json_utils.dart';
import 'booking_request_model.dart';

/// Razorpay order created by the backend for prepaid bookings.
class RazorpayOrder {
  final String id;

  /// Amount in paise, exactly as returned by the backend.
  final int amount;
  final String currency;

  const RazorpayOrder({required this.id, required this.amount, required this.currency});

  static RazorpayOrder? tryParse(dynamic raw) {
    final json = Json.map(raw);
    if (json == null) return null;
    final id = Json.string(json['id']);
    final amount = Json.integer(json['amount']);
    if (id == null || amount == null || amount <= 0) return null;
    return RazorpayOrder(id: id, amount: amount, currency: Json.string(json['currency']) ?? 'INR');
  }
}

/// Appointment summary returned by `POST /appointments`.
class CreatedAppointment {
  final String id;
  final String? doctorName;
  final String? doctorTitle;
  final int? feePaise;
  final String status;
  final String paymentStatus;

  const CreatedAppointment({
    required this.id,
    this.doctorName,
    this.doctorTitle,
    this.feePaise,
    required this.status,
    required this.paymentStatus,
  });

  CreatedAppointment copyWith({String? status, String? paymentStatus}) {
    return CreatedAppointment(
      id: id,
      doctorName: doctorName,
      doctorTitle: doctorTitle,
      feePaise: feePaise,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  static CreatedAppointment? tryParse(dynamic raw) {
    final json = Json.map(raw);
    if (json == null) return null;
    final id = Json.string(json['id']);
    if (id == null) return null;
    final doctor = Json.map(json['doctor']);
    return CreatedAppointment(
      id: id,
      doctorName: Json.string(doctor?['name']),
      doctorTitle: Json.string(doctor?['title']),
      feePaise: Json.integer(json['feePaise']),
      status: Json.string(json['status']) ?? 'upcoming',
      paymentStatus: Json.string(json['paymentStatus']) ?? 'pending',
    );
  }
}

/// Full result of a successful `POST /appointments` call.
class BookingCreated {
  final CreatedAppointment appointment;
  final RazorpayOrder? razorpayOrder;

  const BookingCreated({required this.appointment, this.razorpayOrder});

  BookingCreated copyWith({CreatedAppointment? appointment}) =>
      BookingCreated(appointment: appointment ?? this.appointment, razorpayOrder: razorpayOrder);

  /// Throws [FormatException] if the documented `appointment.id` is absent.
  factory BookingCreated.fromResponse(dynamic body) {
    final json = Json.map(body);
    final root = Json.map(json?['data']) ?? json;
    final appointment = CreatedAppointment.tryParse(root?['appointment']);
    if (appointment == null) {
      throw const FormatException('Booking response is missing appointment.id');
    }
    return BookingCreated(appointment: appointment, razorpayOrder: RazorpayOrder.tryParse(root?['razorpayOrder']));
  }
}

/// Response of `POST /appointments/:id/verify`.
class PaymentVerification {
  final bool success;
  final String paymentStatus;

  const PaymentVerification({required this.success, required this.paymentStatus});

  factory PaymentVerification.fromResponse(dynamic body) {
    final json = Json.map(body) ?? const <String, dynamic>{};
    final status = Json.string(json['paymentStatus']) ?? 'unknown';
    return PaymentVerification(success: Json.boolean(json['success']) == true, paymentStatus: status);
  }
}

/// Everything the confirmation screen needs, gathered across the flow.
class BookingConfirmation {
  final CreatedAppointment appointment;
  final BookingSelection selection;
  final BookingRequest request;

  /// Amount in paise charged (prepay) or payable (postpay).
  final int? amountPaise;

  const BookingConfirmation({
    required this.appointment,
    required this.selection,
    required this.request,
    required this.amountPaise,
  });

  bool get isPrepaid => request.paymentMode == PaymentMode.prepay;
}
