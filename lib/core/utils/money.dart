import 'package:intl/intl.dart';

/// Formats amounts stored in paise (1/100 rupee) as INR.
class Money {
  Money._();

  static final NumberFormat _whole = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  static final NumberFormat _fraction = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  /// `79900` → `₹799`, `79950` → `₹799.50`.
  static String fromPaise(num paise) {
    final rupees = paise / 100;
    return paise % 100 == 0 ? _whole.format(rupees) : _fraction.format(rupees);
  }

  static String? fromPaiseOrNull(num? paise) => paise == null ? null : fromPaise(paise);
}
