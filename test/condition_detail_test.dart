import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_prime_app/features/home/domain/symptom_model.dart';
import 'package:physio_prime_app/features/home/presentation/condition_detail_screen.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('ConditionDetailScreen has safe bottom padding for 3-button navigation and fully visible Book Doctor button', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    const double screenWidth = 393;
    const double screenHeight = 851;
    const double systemNavBarHeight = 48.0;

    tester.view.physicalSize = const Size(screenWidth, screenHeight);
    tester.view.devicePixelRatio = 1.0;
    // Simulate Xiaomi 3-button bug where padding=0, viewPadding=0
    tester.view.padding = FakeViewPadding.zero;
    tester.view.viewPadding = FakeViewPadding.zero;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    final mockSymptom = SymptomModel(
      id: 'sciatica',
      slug: 'sciatica',
      title: 'Sciatica',
      description: 'Irritation or compression of the sciatic nerve.',
      recoveryEstimate: '4–8 weeks',
      symptomsList: ['Shooting pain', 'Numbness', 'Tingling'],
      treatment: 'Nerve mobilization, stretching',
      image: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ConditionDetailScreen(
            slug: 'sciatica',
            symptom: mockSymptom,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title and content
    expect(find.text('Sciatica'), findsWidgets);
    expect(find.text('Estimated Recovery Timeline'), findsOneWidget);
    expect(find.text('Book Doctor for Sciatica'), findsOneWidget);

    // Verify button position is above the 48dp system bar (starts at 803.0)
    final buttonFinder = find.widgetWithText(ElevatedButton, 'Book Doctor for Sciatica');
    expect(buttonFinder, findsOneWidget);

    final buttonBottom = tester.getBottomLeft(buttonFinder).dy;
    const systemBarTop = screenHeight - systemNavBarHeight; // 803.0

    // Button bottom must be strictly above the system bar top (803.0)
    expect(buttonBottom, lessThan(systemBarTop));
    // Specifically, bottom should sit with 12px clearance above the 48px bar -> 851 - 60 = 791.0
    expect(buttonBottom, equals(systemBarTop - 12.0));
  });
}
