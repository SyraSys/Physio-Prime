import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../core/constants/api_constants.dart';
import '../../booking/domain/booking_response_model.dart';
import '../domain/payment_result.dart';

/// Thin lifecycle-safe wrapper around the Razorpay Flutter SDK.
///
/// * Lazily creates the SDK instance and subscribes to success / error /
///   external-wallet events exactly once.
/// * Exposes checkout as a `Future<PaymentResult>` that completes exactly once
///   per checkout attempt; late or duplicate SDK callbacks are ignored.
/// * Uses only the public key ([ApiConstants.razorpayKey]). Signature
///   verification is performed by the backend, never on device.
class RazorpayService {
  Razorpay? _razorpay;
  Completer<PaymentResult>? _pending;
  String? _pendingOrderId;
  bool _disposed = false;

  bool get isCheckoutOpen => _pending != null && !_pending!.isCompleted;

  void _ensureInitialized() {
    if (_razorpay != null) return;
    final razorpay = Razorpay();
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    _razorpay = razorpay;
  }

  /// Opens the Razorpay checkout sheet for a backend-created [order].
  ///
  /// If a checkout is already open, the existing future is returned rather
  /// than opening a second sheet.
  Future<PaymentResult> openCheckout({
    required RazorpayOrder order,
    required String contact,
    required String email,
    String? description,
    String? customerName,
  }) {
    if (_disposed) {
      return Future.value(PaymentResult.failed(message: 'Payment session has ended.'));
    }
    if (isCheckoutOpen) return _pending!.future;

    _ensureInitialized();
    final completer = Completer<PaymentResult>();
    _pending = completer;
    _pendingOrderId = order.id;

    final options = <String, dynamic>{
      'key': ApiConstants.razorpayKey,
      'amount': order.amount,
      'currency': order.currency,
      'name': 'PhysioPrime',
      'order_id': order.id,
      'description': ?description,
      'prefill': {'contact': contact, 'email': email, 'name': ?customerName},
      'theme': {'color': '#0891B2'},
      'retry': {'enabled': true, 'max_count': 3},
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      _complete(PaymentResult.failed(message: 'Unable to open the payment window. Please try again.'));
    }
    return completer.future;
  }

  void _onSuccess(dynamic response) {
    if (response is! PaymentSuccessResponse) {
      _complete(PaymentResult.failed(message: 'Unexpected payment response.'));
      return;
    }
    final paymentId = response.paymentId;
    final signature = response.signature;
    if (paymentId == null || paymentId.isEmpty || signature == null || signature.isEmpty) {
      _complete(
        PaymentResult.failed(
          message: 'Payment response was incomplete. If money was deducted, it will be reconciled automatically.',
        ),
      );
      return;
    }
    final orderId = response.orderId;
    if (orderId != null && _pendingOrderId != null && orderId != _pendingOrderId) {
      // A callback for a different order must never confirm this booking.
      _complete(PaymentResult.failed(message: 'Payment did not match this booking.'));
      return;
    }
    _complete(PaymentResult.success(paymentId: paymentId, signature: signature, orderId: orderId));
  }

  void _onError(dynamic response) {
    if (response is! PaymentFailureResponse) {
      _complete(PaymentResult.failed(message: 'The payment could not be completed.'));
      return;
    }
    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      _complete(PaymentResult.cancelled());
      return;
    }
    if (response.code == Razorpay.NETWORK_ERROR) {
      _complete(
        PaymentResult.failed(
          code: response.code,
          message: 'Network error during payment. Please check your connection and try again.',
        ),
      );
      return;
    }
    _complete(PaymentResult.failed(code: response.code, message: _readableError(response.message)));
  }

  void _onExternalWallet(dynamic response) {
    final wallet = response is ExternalWalletResponse ? response.walletName : null;
    _complete(PaymentResult.externalWallet(wallet));
  }

  /// Razorpay error messages are sometimes JSON strings; extract the
  /// description when present.
  String? _readableError(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map && error['description'] is String) {
          return error['description'] as String;
        }
        if (decoded['description'] is String) return decoded['description'] as String;
      }
    } catch (_) {
      // Not JSON – fall through to the raw message.
    }
    return raw;
  }

  void _complete(PaymentResult result) {
    final pending = _pending;
    if (pending == null || pending.isCompleted) {
      debugPrint('[RazorpayService] Ignored duplicate/late callback: ${result.outcome}');
      return;
    }
    pending.complete(result);
    _pendingOrderId = null;
  }

  /// Releases SDK listeners. Safe to call multiple times.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _complete(PaymentResult.cancelled(message: 'Payment session closed.'));
    _razorpay?.clear();
    _razorpay = null;
  }
}
