import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_prime_app/features/booking/domain/booking_request_model.dart';
import 'package:physio_prime_app/features/booking/domain/slot_model.dart';
import 'package:physio_prime_app/features/booking/presentation/booking_menu_screen.dart';
import 'package:physio_prime_app/features/booking/presentation/widgets/booking_stepper.dart';
import 'package:physio_prime_app/features/booking/presentation/widgets/symptom_card.dart';
import 'package:physio_prime_app/features/home/domain/symptom_model.dart';

void main() {
  group('Booking Features & Stepper Tests', () {
    test('SlotModel parses backend window format with label, timeRange and spots', () {
      final json = {
        'start': '07:00',
        'end': '09:00',
        'label': 'Early Morning',
        'maxPatients': 3,
        'bookedCount': 1,
        'available': true,
      };

      final slot = SlotModel.tryParse(json);
      expect(slot, isNotNull);
      expect(slot!.label, 'Early Morning');
      expect(slot.start, '07:00');
      expect(slot.end, '09:00');
      expect(slot.availableSpots, 2);
      expect(slot.timeRange, '7:00 AM – 9:00 AM');
      expect(slot.displayTitle, 'Early Morning');
      expect(slot.available, isTrue);
    });

    test('BookingRequest includes specialRequirements and numberOfPatients when specified', () {
      const request = BookingRequest(
        doctorSlug: 'doc-tarannum-sayyed',
        categoryId: 'orthopedic',
        mode: ConsultationMode.home,
        date: '2026-11-19',
        slot: 'Early Morning',
        symptom: 'Back Pain',
        patientName: 'Zenith',
        patientPhone: '9876543210',
        patientEmail: 'hey.zenith5@gmail.com',
        patientGender: PatientGender.male,
        patientAge: 28,
        patientRelation: PatientRelation.self,
        address: BookingAddress(text: 'Civil Lines', city: 'Nagpur', area: 'Civil Lines'),
        paymentMode: PaymentMode.prepay,
        numberOfPatients: 2,
        specialRequirements: 'Wheelchair access required',
      );

      final json = request.toJson();
      expect(json['doctorSlug'], 'doc-tarannum-sayyed');
      expect(json['numberOfPatients'], 2);
      expect(json['specialRequirements'], 'Wheelchair access required');
      expect(json['notes'], 'Wheelchair access required');
      expect(json['mode'], 'home');
      expect(json['paymentMode'], 'prepay');
    });

    testWidgets('BookingStepper renders all 4 steps and highlights current step', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BookingStepper(currentStep: 2),
          ),
        ),
      );

      expect(find.text('CONDITION'), findsOneWidget);
      expect(find.text('DOCTOR'), findsOneWidget);
      expect(find.text('SCHEDULE'), findsOneWidget);
      expect(find.text('CONFIRM'), findsOneWidget);

      // Step 1 is completed -> shows checkmark
      expect(find.byIcon(Icons.check), findsOneWidget);
      // Step 2 is active -> shows '2'
      expect(find.text('2'), findsOneWidget);
      // Steps 3 & 4 are upcoming -> show '3' and '4'
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    test('SymptomCard maps departments and keywords to matching home page 3D icon assets', () {
      const ortho = SymptomModel(
        id: '1',
        title: 'Back Pain',
        slug: 'back-pain',
        description: 'Pain in spine',
        department: 'Musculoskeletal / Orthopedic',
      );
      expect(SymptomCard.getIconAsset(ortho), 'assets/images/cat_orthopedic.png');

      const neuro = SymptomModel(
        id: '2',
        title: 'Stroke Rehabilitation',
        slug: 'stroke-rehab',
        description: 'Paralysis recovery',
        department: 'Neurological Conditions',
      );
      expect(SymptomCard.getIconAsset(neuro), 'assets/images/cat_neurological.png');

      const sports = SymptomModel(
        id: '3',
        title: 'ACL Tear',
        slug: 'acl-tear',
        description: 'Knee ligament injury',
        department: 'Sports Injuries',
      );
      expect(SymptomCard.getIconAsset(sports), 'assets/images/cat_sport_injury.png');

      const cardiac = SymptomModel(
        id: '4',
        title: 'Chest Physio',
        slug: 'chest-physio',
        description: 'Breathing rehab',
        department: 'Cardio-Respiratory',
      );
      expect(SymptomCard.getIconAsset(cardiac), 'assets/images/cat_cardiac.png');
    });

    testWidgets('SymptomCard renders without RenderFlex overflow even with long text in narrow constraints', (tester) async {
      const longSymptom = SymptomModel(
        id: '99',
        title: 'Extremely Long Musculoskeletal Back and Neck Condition Name That Takes Much Space',
        slug: 'long-condition',
        description: 'Pain along the spine caused by muscle strain, poor posture, disc issues, or osteoarthritis in elderly patients',
        symptomsList: [
          'Shooting pain from lower back through hip and down the leg',
          'Pain worsening with bending or sitting long hours',
          'Numbness and tingling',
        ],
        department: 'Musculoskeletal / Orthopedic Department with Very Long Title',
        recoveryEstimate: '4-8 weeks',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 250, // Narrow constraints matching phone viewport in test
                child: SymptomCard(
                  item: longSymptom,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      // Verify widget rendered cleanly with no assertions or RenderFlex errors
      expect(tester.takeException(), isNull);
      expect(find.byType(SymptomCard), findsOneWidget);
    });

    testWidgets('BookingMenuScreen renders 3 tabs and switches between tabs smoothly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BookingMenuScreen(),
          ),
        ),
      );

      expect(find.text('By Symptoms'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('All Doctors'), findsOneWidget);

      // Tap on Categories tab
      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();

      // Verify no exceptions thrown during tab sliding/transition
      expect(tester.takeException(), isNull);
    });
  });
}
