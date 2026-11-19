import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_prime_app/features/content/presentation/legal_screens.dart';
import 'package:physio_prime_app/features/content/presentation/blog_detail_screen.dart';

void main() {
  group('Legal & Compliance Screens (iOS Design)', () {
    testWidgets('PrivacyPolicyScreen renders HIPAA & DPDP compliance', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PrivacyPolicyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('HIPAA & DPDP Act Compliant'), findsOneWidget);
      expect(find.text('1. Information We Collect'), findsOneWidget);
      expect(find.text('4. Your Data Rights & Account Deletion'), findsOneWidget);
    });

    testWidgets('TermsOfServiceScreen renders 15-min hold & cancellation terms', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TermsOfServiceScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Patient Service Agreement'), findsOneWidget);
      expect(find.text('2. Booking, Capacity & Unpaid Holds'), findsOneWidget);
      expect(find.text('3. Rescheduling & Cancellation Policy'), findsOneWidget);
    });

    testWidgets('ComplianceScreen renders State OTPT verification info', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ComplianceScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clinical Compliance'), findsOneWidget);
      expect(find.text('State OTPT Registration Verification'), findsOneWidget);
      expect(find.text('Telemedicine Practice Guidelines'), findsOneWidget);
    });

    testWidgets('PatientGuidesScreen renders pre and post care guides', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PatientGuidesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Patient Recovery Guides'), findsOneWidget);
      expect(find.text('Preparing for Your Home Visit'), findsOneWidget);
      expect(find.text('Joining an HD Video Consultation'), findsOneWidget);
    });

    testWidgets('BlogDetailScreen renders article content & doctor reviewer', (tester) async {
      final samplePost = {
        'id': 'post-1',
        'slug': 'orthopedic-recovery-tips',
        'title': '5 Effective Stretches for Lower Back Pain Relief',
        'summary': 'Clinical guidance on alleviating chronic lumbar tension through targeted physiotherapy.',
        'content': 'Gentle stretching and core stabilization can dramatically reduce disc pressure.',
        'authorName': 'Dr. Jayshree Ingole',
        'categoryName': 'Orthopedic',
        'readTime': '3 min read',
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BlogDetailScreen(
              slug: 'orthopedic-recovery-tips',
              initialData: samplePost,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5 Effective Stretches for Lower Back Pain Relief'), findsOneWidget);
      expect(find.text('Dr. Jayshree Ingole'), findsOneWidget);
      expect(find.text('Need Specialist Advice?'), findsOneWidget);
      expect(find.text('Find a Specialist'), findsOneWidget);
    });
  });
}
