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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName'] ?? json['name'] ?? json['full_name'],
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'patient',
      gender: json['gender']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString() ??
          json['date_of_birth']?.toString() ??
          json['dob']?.toString(),
      weight: json['weight']?.toString(),
      height: json['height']?.toString(),
      address: json['address']?.toString(),
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
