/// Defensive JSON readers used by Developer 2 models.
///
/// Backend payloads are parsed without assuming exact runtime types (numbers may
/// arrive as strings, maps as `Map<dynamic, dynamic>`), and missing keys yield
/// `null` instead of throwing.
class Json {
  Json._();

  static Map<String, dynamic>? map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, v) => MapEntry(key.toString(), v));
    }
    return null;
  }

  static List<dynamic> list(dynamic value) => value is List ? value : const [];

  static String? string(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is num || value is bool) return value.toString();
    return null;
  }

  static int? integer(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) {
      return int.tryParse(value.trim()) ?? double.tryParse(value.trim())?.round();
    }
    return null;
  }

  static num? number(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value.trim());
    return null;
  }

  static bool? boolean(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1' || v == 'yes') return true;
      if (v == 'false' || v == '0' || v == 'no') return false;
    }
    return null;
  }

  static DateTime? dateTime(dynamic value) {
    final s = string(value);
    if (s == null) return null;
    return DateTime.tryParse(s);
  }

  /// Returns the first non-null value found under any of [keys].
  static dynamic pick(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final v = json[key];
      if (v != null) return v;
    }
    return null;
  }

  /// Extracts a list from a response body that is either a bare list or an
  /// object wrapping the list under one of [keys].
  static List<dynamic> listFromBody(dynamic body, List<String> keys) {
    if (body is List) return body;
    final m = map(body);
    if (m == null) return const [];
    for (final key in keys) {
      if (m[key] is List) return m[key] as List;
    }
    final data = map(m['data']);
    if (data != null) {
      for (final key in keys) {
        if (data[key] is List) return data[key] as List;
      }
    }
    if (m['data'] is List) return m['data'] as List;
    return const [];
  }
}
