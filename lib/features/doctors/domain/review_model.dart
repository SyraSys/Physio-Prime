class ReviewModel {
  final String id;
  final String patientName;
  final double rating;
  final String? date;
  final String comment;
  final bool verified;
  final String? treatmentName;

  const ReviewModel({
    required this.id,
    required this.patientName,
    required this.rating,
    this.date,
    required this.comment,
    this.verified = true,
    this.treatmentName,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? 'Verified Patient',
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 5.0,
      date: json['createdAt'] != null
          ? json['createdAt'].toString().split('T').first
          : (json['date']?.toString() ?? ''),
      comment: json['comment']?.toString() ?? '',
      verified: json['verified'] != false,
      treatmentName: json['symptom']?.toString() ?? json['treatmentName']?.toString() ?? 'Physiotherapy Treatment',
    );
  }
}
