import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/api_error.dart';
import '../domain/booking_request_model.dart';
import '../domain/booking_response_model.dart';
import '../domain/slot_model.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.read(apiClientProvider));
});

/// Booking + payment-verification API calls. All errors are rethrown as
/// [ApiException] so the UI can present consistent messages.
class BookingRepository {
  final ApiClient _api;

  BookingRepository(this._api);

  /// `GET /doctors/:slug/slots?date=YYYY-MM-DD`
  Future<SlotAvailability> getSlots({required String doctorSlug, required String date}) async {
    try {
      final res = await _api.get('/doctors/${Uri.encodeComponent(doctorSlug)}/slots', queryParameters: {'date': date});
      return SlotAvailability.fromResponse(date, res.data);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// `POST /appointments`
  Future<BookingCreated> createAppointment(BookingRequest request) async {
    try {
      final res = await _api.post('/appointments', data: request.toJson());
      return BookingCreated.fromResponse(res.data);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// `POST /appointments/:id/verify`
  Future<PaymentVerification> verifyPayment({
    required String appointmentId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final res = await _api.post(
        '/appointments/${Uri.encodeComponent(appointmentId)}/verify',
        data: {'razorpayPaymentId': razorpayPaymentId, 'razorpaySignature': razorpaySignature},
      );
      return PaymentVerification.fromResponse(res.data);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
