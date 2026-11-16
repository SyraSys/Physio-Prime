import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/api_error.dart';
import '../../payment/domain/payment_result.dart';
import '../../payment/services/razorpay_service.dart';
import '../data/booking_repository.dart';
import '../domain/booking_request_model.dart';
import '../domain/booking_response_model.dart';
import '../domain/slot_model.dart';

/// Slot availability for a doctor on a date. Auto-disposed so revisiting a
/// date always re-fetches live availability.
final slotAvailabilityProvider = FutureProvider.autoDispose.family<SlotAvailability, SlotQuery>((ref, query) {
  return ref.read(bookingRepositoryProvider).getSlots(doctorSlug: query.doctorSlug, date: query.date);
});

enum BookingPhase {
  /// Form editable, nothing submitted.
  idle,

  /// `POST /appointments` in flight.
  creating,

  /// Razorpay checkout sheet is open.
  awaitingPayment,

  /// `POST /appointments/:id/verify` in flight.
  verifying,

  /// Booking confirmed (postpay created, or prepay verified by backend).
  completed,

  /// Appointment exists but payment was cancelled / failed / handed off.
  paymentIncomplete,

  /// Razorpay returned credentials but backend verification failed.
  verificationFailed,

  /// Appointment creation failed; nothing was booked.
  failed,
}

class BookingFlowState {
  final BookingPhase phase;
  final BookingSelection? selection;
  final BookingRequest? request;
  final BookingCreated? created;
  final PaymentResult? lastPayment;
  final ApiException? error;
  final BookingConfirmation? confirmation;

  const BookingFlowState({
    this.phase = BookingPhase.idle,
    this.selection,
    this.request,
    this.created,
    this.lastPayment,
    this.error,
    this.confirmation,
  });

  bool get isBusy =>
      phase == BookingPhase.creating || phase == BookingPhase.awaitingPayment || phase == BookingPhase.verifying;

  /// Once an appointment exists the form is locked so a second
  /// `POST /appointments` can never be issued for the same checkout.
  bool get appointmentCreated => created != null;

  BookingFlowState copyWith({
    BookingPhase? phase,
    BookingSelection? selection,
    BookingRequest? request,
    BookingCreated? created,
    PaymentResult? lastPayment,
    ApiException? error,
    bool clearError = false,
    BookingConfirmation? confirmation,
  }) {
    return BookingFlowState(
      phase: phase ?? this.phase,
      selection: selection ?? this.selection,
      request: request ?? this.request,
      created: created ?? this.created,
      lastPayment: lastPayment ?? this.lastPayment,
      error: clearError ? null : (error ?? this.error),
      confirmation: confirmation ?? this.confirmation,
    );
  }
}

final bookingFlowProvider = StateNotifierProvider.autoDispose<BookingFlowController, BookingFlowState>((ref) {
  final controller = BookingFlowController(ref.read(bookingRepositoryProvider), RazorpayService());
  return controller;
});

/// Orchestrates appointment creation → Razorpay checkout → backend
/// verification, guarding against duplicate submissions and callbacks.
class BookingFlowController extends StateNotifier<BookingFlowState> {
  final BookingRepository _repository;
  final RazorpayService _razorpay;

  BookingFlowController(this._repository, this._razorpay) : super(const BookingFlowState());

  /// Creates the appointment, then launches payment for prepay bookings.
  Future<void> submit(BookingSelection selection, BookingRequest request) async {
    if (state.isBusy) return;
    if (state.appointmentCreated) {
      // Never create a second appointment for the same checkout.
      if (state.request?.paymentMode == PaymentMode.prepay) await retryPayment();
      return;
    }

    state = BookingFlowState(phase: BookingPhase.creating, selection: selection, request: request);

    final BookingCreated created;
    try {
      created = await _repository.createAppointment(request);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(phase: BookingPhase.failed, error: ApiException.from(e));
      return;
    }
    if (!mounted) return;
    state = state.copyWith(created: created, clearError: true);

    if (request.paymentMode == PaymentMode.postpay) {
      _complete(created);
      return;
    }

    if (created.razorpayOrder == null) {
      state = state.copyWith(
        phase: BookingPhase.paymentIncomplete,
        error: const ApiException(
          'Your appointment was created but an online payment order was not issued. '
          'Payment is pending — please contact support or pay from My Appointments.',
        ),
      );
      return;
    }
    await _pay();
  }

  /// Re-opens Razorpay for the existing order (no new appointment).
  Future<void> retryPayment() async {
    if (state.isBusy || state.created?.razorpayOrder == null) return;
    await _pay();
  }

  /// Re-sends previously received Razorpay credentials for verification.
  Future<void> retryVerification() async {
    final payment = state.lastPayment;
    if (state.isBusy || payment == null || !payment.hasVerifiableCredentials) return;
    await _verify(payment);
  }

  Future<void> _pay() async {
    final created = state.created!;
    final request = state.request!;
    final order = created.razorpayOrder!;

    state = state.copyWith(phase: BookingPhase.awaitingPayment, clearError: true);

    final result = await _razorpay.openCheckout(
      order: order,
      contact: request.patientPhone,
      email: request.patientEmail,
      customerName: request.patientName,
      description:
          'Consultation with ${created.appointment.doctorName ?? state.selection?.doctor.name ?? 'your physiotherapist'}',
    );
    if (!mounted) return;

    if (result.hasVerifiableCredentials) {
      state = state.copyWith(lastPayment: result);
      await _verify(result);
    } else {
      state = state.copyWith(
        phase: BookingPhase.paymentIncomplete,
        lastPayment: result,
        error: ApiException(result.userMessage),
      );
    }
  }

  Future<void> _verify(PaymentResult payment) async {
    final created = state.created!;
    state = state.copyWith(phase: BookingPhase.verifying, clearError: true);
    try {
      final verification = await _repository.verifyPayment(
        appointmentId: created.appointment.id,
        razorpayPaymentId: payment.paymentId!,
        razorpaySignature: payment.signature!,
      );
      if (!mounted) return;
      if (!verification.success) {
        state = state.copyWith(
          phase: BookingPhase.verificationFailed,
          error: const ApiException(
            'We could not verify your payment. If money was deducted it will be '
            'reconciled automatically, or contact PhysioPrime support.',
          ),
        );
        return;
      }
      _complete(created.copyWith(appointment: created.appointment.copyWith(paymentStatus: verification.paymentStatus)));
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(phase: BookingPhase.verificationFailed, error: ApiException.from(e));
    }
  }

  void _complete(BookingCreated created) {
    final request = state.request!;
    final amount = request.paymentMode == PaymentMode.prepay
        ? (created.razorpayOrder?.amount ?? created.appointment.feePaise)
        : created.appointment.feePaise;
    state = state.copyWith(
      phase: BookingPhase.completed,
      created: created,
      clearError: true,
      confirmation: BookingConfirmation(
        appointment: created.appointment,
        selection: state.selection!,
        request: request,
        amountPaise: amount,
      ),
    );
  }

  /// Clears a failed creation so the user can edit and resubmit.
  void resetAfterFailure() {
    if (state.phase == BookingPhase.failed) {
      state = const BookingFlowState();
    }
  }

  @override
  void dispose() {
    _razorpay.dispose();
    super.dispose();
  }
}
