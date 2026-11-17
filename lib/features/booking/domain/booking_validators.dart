/// Pure validation helpers for the checkout form (unit-testable).
class BookingValidators {
  BookingValidators._();

  static final RegExp _email = RegExp(r"^[\w.!#$%&'*+/=?^`{|}~-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$");

  /// Returns the phone in E.164 (`+91XXXXXXXXXX`) or null when it is not a
  /// valid Indian mobile number.
  static String? normalizeIndianPhone(String input) {
    var digits = input.replaceAll(RegExp(r'[\s\-()]'), '');
    if (digits.startsWith('+91')) {
      digits = digits.substring(3);
    } else if (digits.startsWith('91') && digits.length == 12) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) return null;
    return '+91$digits';
  }

  static bool isValidEmail(String input) => _email.hasMatch(input.trim());

  static bool isValidName(String input) {
    final v = input.trim();
    return v.length >= 2 && RegExp(r"^[A-Za-z][A-Za-z .'-]*$").hasMatch(v);
  }
}
