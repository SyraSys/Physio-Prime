import 'package:flutter_test/flutter_test.dart';
import 'package:physio_prime_app/features/auth/domain/user_model.dart';
import 'package:physio_prime_app/features/home/domain/category_model.dart';
import 'package:physio_prime_app/features/home/domain/symptom_model.dart';
import 'package:physio_prime_app/features/doctors/domain/doctor_model.dart';

void main() {
  group('Developer 1 Domain Models Tests', () {
    test('UserModel deserialization with web profile attributes', () {
      final json = {
        'id': 'usr-12345',
        'email': 'hey.zenith5@gmail.com',
        'fullName': 'Zenith',
        'phone': '+91 9876543210',
        'role': 'patient',
        'gender': 'Male',
        'dateOfBirth': '15/08/1995',
        'weight': '68 kg',
        'height': '175 cm',
        'address': 'Nagpur, Maharashtra, India',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 'usr-12345');
      expect(user.email, 'hey.zenith5@gmail.com');
      expect(user.fullName, 'Zenith');
      expect(user.phone, '+91 9876543210');
      expect(user.gender, 'Male');
      expect(user.dateOfBirth, '15/08/1995');
      expect(user.weight, '68 kg');
      expect(user.height, '175 cm');
      expect(user.address, 'Nagpur, Maharashtra, India');

      final serialized = user.toJson();
      expect(serialized['weight'], '68 kg');
      expect(serialized['height'], '175 cm');
      expect(serialized['address'], 'Nagpur, Maharashtra, India');

      final copied = user.copyWith(weight: '70 kg');
      expect(copied.weight, '70 kg');
      expect(copied.fullName, 'Zenith');
    });
    test('CategoryModel deserialization', () {
      final json = {
        'id': 'orthopedic',
        'numericId': 1,
        'title': 'Orthopedic Doctor',
        'slug': 'orthopedic',
        'description': 'Specialized therapy for bones and joints',
        'conditions': ['Back Pain', 'Neck Pain'],
      };

      final cat = CategoryModel.fromJson(json);
      expect(cat.id, 'orthopedic');
      expect(cat.title, 'Orthopedic Doctor');
      expect(cat.conditions.length, 2);
    });

    test('SymptomModel deserialization', () {
      final json = {
        'id': 'back-pain',
        'title': 'Back Pain',
        'slug': 'back-pain',
        'description': 'Pain along the spine',
        'symptomsList': 'Stiffness; Sharp pain; Muscle spasm',
        'recoveryEstimate': '4-8 weeks',
      };

      final sym = SymptomModel.fromJson(json);
      expect(sym.id, 'back-pain');
      expect(sym.symptomsList.length, 3);
      expect(sym.recoveryEstimate, '4-8 weeks');
    });

    test('DoctorModel deserialization & starting fee', () {
      final json = {
        'id': 'doc-tarannum-sayyed',
        'slug': 'doc-tarannum-sayyed',
        'name': 'Dr. Tarannum Sayyed',
        'title': 'Senior Consultant Physiotherapist',
        'specialty': 'Orthopedic & Post-Op Rehab Specialist',
        'rating': 4.9,
        'reviewCount': 142,
        'experienceYears': 6,
        'patientsTreated': 1250,
        'fees': {'home': 1000, 'online': 1},
        'feeRange': {'min': 1, 'max': 1000},
        'nextAvailable': '2026-10-05',
        'homeVisitsEnabled': true,
      };

      final doc = DoctorModel.fromJson(json);
      expect(doc.name, 'Dr. Tarannum Sayyed');
      expect(doc.fees.home, 1000);
      expect(doc.fees.online, 1);
      expect(doc.startingFee, 1);
      expect(doc.consultationFeeDisplay, '₹1-1,000 / session');
      expect(doc.nextAvailableDisplay, 'Oct 5');
    });
  });
}
