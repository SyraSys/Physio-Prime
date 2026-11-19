import 'package:flutter_test/flutter_test.dart';
import 'package:physio_prime_app/core/utils/ist_time.dart';
import 'package:physio_prime_app/core/utils/money.dart';
import 'package:physio_prime_app/features/appointments/domain/appointment_model.dart';
import 'package:physio_prime_app/features/booking/domain/booking_request_model.dart';
import 'package:physio_prime_app/features/booking/domain/booking_response_model.dart';
import 'package:physio_prime_app/features/booking/domain/booking_validators.dart';
import 'package:physio_prime_app/features/booking/domain/slot_model.dart';
import 'package:physio_prime_app/features/dashboard/domain/notification_model.dart';
import 'package:physio_prime_app/features/dashboard/domain/prescription_model.dart';
import 'package:physio_prime_app/features/telehealth/services/jaas_video_service.dart';

void main() {
  group('Slots', () {
    test('parses documented windows response', () {
      final a = SlotAvailability.fromResponse('2026-11-10', {
        'windows': [
          {'slot': '09:00 AM - 10:00 AM', 'available': true},
          {'slot': '10:00 AM - 11:00 AM', 'available': false},
          {'slot': null, 'available': true},
        ],
      });
      expect(a.windows.length, 2);
      expect(a.windows.first.available, isTrue);
      expect(a.windows.last.available, isFalse);
      expect(a.hasAnyAvailable, isTrue);
    });

    test('empty / malformed body yields no windows', () {
      expect(SlotAvailability.fromResponse('2026-11-10', null).windows, isEmpty);
      expect(SlotAvailability.fromResponse('2026-11-10', {'windows': 'x'}).windows, isEmpty);
    });

    test('slot start parsing handles AM/PM and noon', () {
      final d = DateTime(2026, 11, 10);
      expect(IstTime.slotStart(d, '09:00 AM - 10:00 AM'), DateTime(2026, 11, 10, 9));
      expect(IstTime.slotStart(d, '12:00 PM - 01:00 PM'), DateTime(2026, 11, 10, 12));
      expect(IstTime.slotStart(d, '12:30 AM - 01:00 AM'), DateTime(2026, 11, 10, 0, 30));
      expect(IstTime.slotStart(d, '04:00 PM - 05:00 PM'), DateTime(2026, 11, 10, 16));
      expect(IstTime.slotStart(d, 'Morning'), isNull);
    });

    test('next 14 IST days start today and are consecutive', () {
      final days = IstTime.upcomingDays(14);
      expect(days.length, 14);
      expect(IstTime.isSameDay(days.first, IstTime.today()), isTrue);
      expect(days[1].difference(days[0]).inHours, inInclusiveRange(23, 25));
      expect(IstTime.apiDate(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });

  group('Booking request / response', () {
    test('serializes exactly the documented POST /appointments body', () {
      const request = BookingRequest(
        doctorSlug: 'doc-tarannum-sayyed',
        categoryId: 'orthopedic',
        mode: ConsultationMode.home,
        date: '2026-11-10',
        slot: '10:00 AM - 11:00 AM',
        symptom: 'Lower back pain radiating down leg',
        patientName: 'Ramesh Kumar',
        patientPhone: '+919876543210',
        patientEmail: 'ramesh@example.com',
        patientGender: PatientGender.male,
        patientAge: 54,
        patientWeight: 78,
        patientHeight: 172,
        patientRelation: PatientRelation.self,
        address: BookingAddress(text: 'Flat 402, Sunshine Heights, Dharampeth', city: 'Nagpur', area: 'Dharampeth'),
        paymentMode: PaymentMode.prepay,
      );
      expect(request.toJson(), {
        'doctorSlug': 'doc-tarannum-sayyed',
        'categoryId': 'orthopedic',
        'mode': 'home',
        'date': '2026-11-10',
        'slot': '10:00 AM - 11:00 AM',
        'symptom': 'Lower back pain radiating down leg',
        'patientName': 'Ramesh Kumar',
        'patientPhone': '+919876543210',
        'patientEmail': 'ramesh@example.com',
        'patientGender': 'male',
        'patientAge': 54,
        'patientWeight': 78,
        'patientHeight': 172,
        'patientRelation': 'self',
        'address': {'text': 'Flat 402, Sunshine Heights, Dharampeth', 'city': 'Nagpur', 'area': 'Dharampeth'},
        'paymentMode': 'prepay',
      });
    });

    test('parses documented 201 response with Razorpay order', () {
      final created = BookingCreated.fromResponse({
        'appointment': {
          'id': 'apt_98214',
          'doctor': {'name': 'Dr. Tarannum Sayyed', 'title': 'Senior Orthopedic'},
          'feePaise': 79900,
          'status': 'upcoming',
          'paymentStatus': 'pending',
        },
        'razorpayOrder': {'id': 'order_ND82jsl1092', 'amount': 79900, 'currency': 'INR'},
      });
      expect(created.appointment.id, 'apt_98214');
      expect(created.appointment.doctorName, 'Dr. Tarannum Sayyed');
      expect(created.appointment.feePaise, 79900);
      expect(created.razorpayOrder?.id, 'order_ND82jsl1092');
      expect(created.razorpayOrder?.amount, 79900);
    });

    test('postpay response without order parses; missing id throws', () {
      final created = BookingCreated.fromResponse({
        'appointment': {'id': 'apt_1', 'status': 'upcoming', 'paymentStatus': 'pending'},
      });
      expect(created.razorpayOrder, isNull);
      expect(() => BookingCreated.fromResponse({'appointment': {}}), throwsFormatException);
    });

    test('verification only succeeds on explicit success=true', () {
      expect(PaymentVerification.fromResponse({'success': true, 'paymentStatus': 'paid'}).success, isTrue);
      expect(PaymentVerification.fromResponse({'paymentStatus': 'paid'}).success, isFalse);
      expect(PaymentVerification.fromResponse({'success': false}).success, isFalse);
      expect(PaymentVerification.fromResponse(null).success, isFalse);
    });

    test('route args prefer doctorSlug and fall back to doctorId', () {
      final a = BookingDoctorInfo.fromRouteArgs({
        'doctorId': 'uuid-123',
        'doctorSlug': 'doc-tarannum-sayyed',
        'doctorName': 'Dr. Tarannum Sayyed',
        'mode': 'online',
        'fee': 799,
      });
      expect(a?.slug, 'doc-tarannum-sayyed');
      expect(a?.initialMode, ConsultationMode.online);
      expect(a?.feePaise, isNull, reason: 'rupee "fee" must not be treated as paise');

      final b = BookingDoctorInfo.fromRouteArgs({'doctorId': 'dr-x', 'doctorName': 'Dr X'});
      expect(b?.slug, 'dr-x');
      expect(BookingDoctorInfo.fromRouteArgs(null), isNull);
      expect(BookingDoctorInfo.fromRouteArgs({'doctorName': 'Dr X'}), isNull);
    });
  });

  group('Validators & money', () {
    test('Indian phone normalization', () {
      expect(BookingValidators.normalizeIndianPhone('9876543210'), '+919876543210');
      expect(BookingValidators.normalizeIndianPhone('+91 98765-43210'), '+919876543210');
      expect(BookingValidators.normalizeIndianPhone('09876543210'), '+919876543210');
      expect(BookingValidators.normalizeIndianPhone('919876543210'), '+919876543210');
      expect(BookingValidators.normalizeIndianPhone('5876543210'), isNull);
      expect(BookingValidators.normalizeIndianPhone('98765'), isNull);
    });

    test('email and name', () {
      expect(BookingValidators.isValidEmail('ramesh@example.com'), isTrue);
      expect(BookingValidators.isValidEmail('ramesh@example'), isFalse);
      expect(BookingValidators.isValidName('Ramesh Kumar'), isTrue);
      expect(BookingValidators.isValidName('R2D2'), isFalse);
    });

    test('fees are rendered from paise', () {
      expect(Money.fromPaise(79900), '₹799');
      expect(Money.fromPaise(79950), '₹799.50');
      expect(Money.fromPaise(10000000), '₹1,00,000');
    });
  });

  group('Appointments', () {
    test('parses list item and derives groups/actions', () {
      final a = AppointmentModel.tryParse({
        'id': 'apt_98214',
        'doctor': {'name': 'Dr. Tarannum Sayyed', 'title': 'Senior Orthopedic', 'slug': 'doc-tarannum-sayyed'},
        'mode': 'online',
        'date': '2026-11-10',
        'slot': '10:00 AM - 11:00 AM',
        'status': 'upcoming',
        'paymentStatus': 'paid',
        'feePaise': 79900,
        'videoJoinable': true,
      })!;
      expect(a.group, AppointmentGroup.upcoming);
      expect(a.canJoinVideo, isTrue);
      expect(a.canReschedule, isTrue);
      expect(a.canCancel, isTrue);
      expect(a.canReview, isFalse);
      expect(a.isPaid, isTrue);
    });

    test('status grouping and review eligibility', () {
      expect(AppointmentStatusStyle.groupOf('completed'), AppointmentGroup.completed);
      expect(AppointmentStatusStyle.groupOf('CANCELED'), AppointmentGroup.cancelled);
      final done = AppointmentModel.tryParse({'id': '1', 'status': 'completed', 'paymentStatus': 'paid'})!;
      expect(done.canReview, isTrue);
      final reviewed = AppointmentModel.tryParse({
        'id': '2',
        'status': 'completed',
        'review': {'rating': 5},
      })!;
      expect(reviewed.canReview, isFalse);
    });

    test('video is not joinable unless backend says so', () {
      final a = AppointmentModel.tryParse({'id': '1', 'mode': 'online', 'status': 'upcoming'})!;
      expect(a.canJoinVideo, isFalse);
    });

    test('reschedule requires a doctor slug', () {
      final a = AppointmentModel.tryParse({
        'id': '1',
        'doctor': {'name': 'Dr'},
        'status': 'upcoming',
      })!;
      expect(a.canReschedule, isFalse);
    });
  });

  group('Dashboard', () {
    test('prescription parsing keeps only safe document URLs', () {
      final p = PrescriptionModel.tryParse({
        'id': 'rx1',
        'doctor': {'name': 'Dr. Tarannum Sayyed'},
        'createdAt': '2026-11-10T10:00:00Z',
        'medications': [
          {'name': 'Ibuprofen', 'dosage': '400mg', 'frequency': 'Twice daily', 'duration': '5 days'},
        ],
        'pdfUrl': 'javascript:alert(1)',
      })!;
      expect(p.doctorName, 'Dr. Tarannum Sayyed');
      expect(p.medications.single.dosage, '400mg');
      expect(p.documentUrl, isNull);
      final q = PrescriptionModel.tryParse({'id': 'rx2', 'documentUrl': 'https://cdn.example.com/rx2.pdf'})!;
      expect(q.documentUrl.toString(), 'https://cdn.example.com/rx2.pdf');
    });

    test('notification read state variants', () {
      expect(NotificationModel.tryParse({'id': '1', 'title': 'Hi', 'read': true})!.read, isTrue);
      expect(NotificationModel.tryParse({'id': '2', 'title': 'Hi', 'readAt': '2026-11-10'})!.read, isTrue);
      expect(NotificationModel.tryParse({'id': '3', 'message': 'Hi'})!.read, isFalse);
    });
  });

  group('Telehealth', () {
    test('room resolves from JWT sub when backend returns bare room name', () {
      // Header/payload only for decoding; signature is irrelevant client-side.
      const payload = 'eyJzdWIiOiJ2cGFhcy1tYWdpYy1jb29raWUtYWJjIn0'; // {"sub":"vpaas-magic-cookie-abc"}
      const token = VideoToken(token: 'eyJhbGciOiJSUzI1NiJ9.$payload.sig', roomName: 'room_apt_98214');
      expect(JaasVideoService.resolveRoom(token), 'vpaas-magic-cookie-abc/room_apt_98214');
      const full = VideoToken(token: 'x.y.z', roomName: 'vpaas-magic-cookie-abc/room_1');
      expect(JaasVideoService.resolveRoom(full), 'vpaas-magic-cookie-abc/room_1');
      expect(
        () => JaasVideoService.resolveRoom(const VideoToken(token: 'bad', roomName: 'room')),
        throwsA(isA<VideoConfigurationException>()),
      );
    });

    test('video token response validation', () {
      final t = VideoToken.fromResponse({'token': 'abc', 'roomName': 'room_apt_1', 'identity': 'patient_x'});
      expect(t.identity, 'patient_x');
      expect(() => VideoToken.fromResponse({'roomName': 'r'}), throwsFormatException);
    });
  });
}
