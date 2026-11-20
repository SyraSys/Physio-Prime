import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_prime_app/core/network/api_client.dart';
import 'package:physio_prime_app/features/doctors/data/doctors_repository.dart';
import 'package:physio_prime_app/features/doctors/domain/doctor_model.dart';
import 'package:physio_prime_app/features/home/domain/category_model.dart';
import 'package:physio_prime_app/features/home/presentation/category_detail_screen.dart';

class FakeDoctorsRepo extends DoctorsRepository {
  final List<DoctorModel> list;
  FakeDoctorsRepo(this.list) : super(ApiClient());

  @override
  Future<List<DoctorModel>> getDoctors({
    String? city,
    String? area,
    String? symptom,
    String? mode,
    String? category,
    String? search,
    String? gender,
  }) async {
    return list;
  }
}

void main() {
  const sportsCategory = CategoryModel(
    id: 'cat_sports',
    title: 'Sports Injury Doctor',
    slug: 'sports-injury',
    description: 'High-performance sports medicine and recovery.',
    doctorCount: 3,
    conditions: ['ACL Tear', 'Rotator Cuff Injury'],
  );

  final threeDoctors = [
    const DoctorModel(
      id: 'doc-1',
      slug: 'dr-darrell-steward',
      name: 'Dr. Darrell Steward',
      title: 'Senior Sports Physiotherapist',
      specialty: 'Sports Injuries & ACL Rehab',
      rating: 4.9,
      fees: DoctorFees(home: 1000, online: 800),
    ),
    const DoctorModel(
      id: 'doc-2',
      slug: 'dr-john-doe',
      name: 'Dr. John Doe',
      title: 'Consultant Physiotherapist',
      specialty: 'Sports Medicine & Conditioning',
      rating: 4.8,
      fees: DoctorFees(home: 1200, online: 900),
    ),
    const DoctorModel(
      id: 'doc-3',
      slug: 'dr-jane-smith',
      name: 'Dr. Jane Smith',
      title: 'Athletic Rehab Specialist',
      specialty: 'Sports Injury & Dry Needling',
      rating: 5.0,
      fees: DoctorFees(home: 1100, online: 850),
    ),
  ];

  group('CategoryDetailScreen Real Data & Dynamic Doctor Count Tests', () {
    testWidgets('Dynamically displays "3 Verified Doctors" when 3 doctors are fetched for sports-injury', (tester) async {
      final fakeRepo = FakeDoctorsRepo(threeDoctors);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            doctorsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: CategoryDetailScreen(
              slug: 'sports-injury',
              category: sportsCategory,
            ),
          ),
        ),
      );

      // Settle async doctors future
      await tester.pumpAndSettle();

      // Expect "3 Verified Doctors" badge
      expect(find.text('3 Verified Doctors'), findsOneWidget);
      // It should NOT say "1 Verified Doctor"
      expect(find.text('1 Verified Doctor'), findsNothing);

      // Expect all 3 doctor cards rendered
      expect(find.text('Dr. Darrell Steward'), findsOneWidget);
      expect(find.text('Dr. John Doe'), findsOneWidget);
      expect(find.text('Dr. Jane Smith'), findsOneWidget);

      // Section subtitle indicates 3 licensed clinical physiotherapists
      expect(find.textContaining('3 licensed clinical physiotherapists'), findsOneWidget);
    });

    testWidgets('Dynamically displays "1 Verified Doctor" when exactly 1 doctor is fetched', (tester) async {
      final fakeRepo = FakeDoctorsRepo([threeDoctors.first]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            doctorsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: CategoryDetailScreen(
              slug: 'orthopedic',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1 Verified Doctor'), findsOneWidget);
      expect(find.text('3 Verified Doctors'), findsNothing);
      expect(find.text('Dr. Darrell Steward'), findsOneWidget);
    });
  });
}
