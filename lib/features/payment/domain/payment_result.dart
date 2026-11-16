/// Outcome reported by the Razorpay checkout sheet.
///
/// IMPORTANT: [PaymentOutcome.success] only means Razorpay returned a payment
/// id + signature to the app. A payment is considered complete solely after
/// the backend verifies it via `POST /appointments/:id/verify`.
enum PaymentOutcome { success, failed, cancelled, externalWallet }

class PaymentResult {
  final PaymentOutcome outcome;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final int? errorCode;
  final String? message;
  final String? walletName;

  const PaymentResult._({required this.outcome, this.errorCode, this.message, this.walletName})
    : paymentId = null,
      orderId = null,
      signature = null;

  const PaymentResult.success({required String this.paymentId, required String this.signature, this.orderId})
    : outcome = PaymentOutcome.success,
      errorCode = null,
      message = null,
      walletName = null;

  factory PaymentResult.failed({int? code, String? message}) =>
      PaymentResult._(outcome: PaymentOutcome.failed, errorCode: code, message: message);

  factory PaymentResult.cancelled({String? message}) =>
      PaymentResult._(outcome: PaymentOutcome.cancelled, message: message ?? 'Payment was cancelled.');

  factory PaymentResult.externalWallet(String? walletName) => PaymentResult._(
    outcome: PaymentOutcome.externalWallet,
    walletName: walletName,
    message: walletName == null
        ? 'Payment was handed off to an external wallet.'
        : 'Payment was handed off to $walletName.',
  );

  bool get hasVerifiableCredentials =>
      outcome == PaymentOutcome.success && (paymentId?.isNotEmpty ?? false) && (signature?.isNotEmpty ?? false);

  /// Human readable explanation for non-success outcomes.
  String get userMessage {
    switch (outcome) {
      case PaymentOutcome.success:
        return 'Payment received. Confirming with PhysioPrime…';
      case PaymentOutcome.cancelled:
        return 'You closed the payment window before completing payment.';
      case PaymentOutcome.externalWallet:
        return '${message ?? 'Payment handed off to an external wallet.'} '
            'We will update your booking once the payment is confirmed.';
      case PaymentOutcome.failed:
        final m = message?.trim();
        return (m == null || m.isEmpty) ? 'The payment could not be completed.' : m;
    }
  }
}
