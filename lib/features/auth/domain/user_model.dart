import 'dart:convert';

class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? role;
  final String? gender;
  final String? dateOfBirth;
  final String? weight;
  final String? height;
  final String? address;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.role,
    this.gender,
    this.dateOfBirth,
    this.weight,
    this.height,
    this.address,
    this.createdAt,
  });

  /// Robust parser for addresses that may be returned as JSON objects,
  /// Dart Map string representations like `{text: guwahati}`, or plain text.
  static String? parseAddress(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) {
      final text = raw['text'] ?? raw['line1'] ?? raw['address'] ?? raw['formatted'];
      if (text != null && text.toString().trim().isNotEmpty) {
        final city = raw['city']?.toString().trim();
        final area = raw['area']?.toString().trim();
        final parts = [
          text.toString().trim(),
          if (area != null && area.isNotEmpty) area,
          if (city != null && city.isNotEmpty) city,
        ];
        return parts.join(', ');
      }
      return raw.values.where((v) => v != null && v.toString().trim().isNotEmpty).join(', ');
    }
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    if (s.startsWith('{') && s.endsWith('}')) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is Map) {
          return parseAddress(decoded);
        }
      } catch (_) {}
      // Handle Dart map representation like {text: guwahati} or {text:guwahati}
      final match = RegExp(r'(?:text|line1|address)\s*:\s*([^,}]+)', caseSensitive: false).firstMatch(s);
      if (match != null) {
        return match.group(1)?.trim();
      }
      final inner = s.substring(1, s.length - 1).trim();
      if (!inner.contains(':')) return inner;
    }
    return s;
  }

  static DateTime? parseDob(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final clean = text.trim();
    if (clean.contains('/') || clean.contains('-')) {
      final delimiter = clean.contains('/') ? '/' : '-';
      final parts = clean.split(delimiter);
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final d = int.tryParse(parts[2]);
          if (y != null && m != null && d != null) {
            return DateTime(y, m, d);
          }
        } else {
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final y = int.tryParse(parts[2]);
          if (y != null && m != null && d != null) {
            return DateTime(y, m, d);
          }
        }
      }
    }
    return DateTime.tryParse(clean);
  }

  static String formatDob(dynamic raw) {
    if (raw == null) return '—';
    final s = raw.toString().trim();
    if (s.isEmpty) return '—';
    final dt = parseDob(s);
    if (dt == null) return s;
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    return '$d/$m/$y';
  }

  static String? toIsoDate(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final clean = text.trim();
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(clean)) return clean;
    final dt = parseDob(clean);
    if (dt == null) return clean;
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName'] ?? json['name'] ?? json['full_name'],
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'patient',
      gender: json['gender']?.toString(),
      dateOfBirth: json['dob']?.toString() ??
          json['dateOfBirth']?.toString() ??
          json['date_of_birth']?.toString(),
      weight: json['weight']?.toString(),
      height: json['height']?.toString(),
      address: parseAddress(json['address']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'role': role,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'weight': weight,
      'height': height,
      'address': address,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? role,
    String? gender,
    String? dateOfBirth,
    String? weight,
    String? height,
    String? address,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
