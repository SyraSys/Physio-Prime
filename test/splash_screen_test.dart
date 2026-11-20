import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_prime_app/core/router/router_state.dart';
import 'package:physio_prime_app/features/splash/presentation/splash_screen.dart';

void main() {
  setUp(() {
    resetAppInitialization();
  });

  group('SplashScreen UI & Minimalist Requirements Tests', () {
    testWidgets('Renders strictly the PhysioPrime logo and PhysioPrime name, nothing else', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(
              autoNavigate: false, // Prevent auto-navigation during UI inspection
              enableWarmUp: false, // Pure UI test without network warm-up
              minDuration: Duration(milliseconds: 1000),
            ),
          ),
        ),
      );

      // Verify PhysioPrime Logo is present
      expect(find.byType(Image), findsOneWidget);

      // Verify PhysioPrime Name is present
      expect(
        find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('PhysioPrime')),
        findsOneWidget,
      );

      // Verify NOTHING ELSE is rendered:
      // No progress bar or tracks
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // No status text
      expect(find.text('Connecting to clinical network...'), findsNothing);
      expect(find.text('Loading verified physiotherapists...'), findsNothing);
      expect(find.text('Preparing your care experience...'), findsNothing);

      // No badges, subtitles, or footers
      expect(find.text('SPECIALIZED PHYSIOTHERAPY CARE'), findsNothing);
      expect(find.text('Home Visits • Telehealth • In-Clinic Rehab'), findsNothing);
      expect(find.text('HIPAA Compliant & Clinical Grade Security'), findsNothing);

      // Pump through animation
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SplashScreen), findsOneWidget);
    });

    test('Router state initializes false and updates on markAppInitialized', () {
      expect(isAppInitialized, isFalse);
      markAppInitialized();
      expect(isAppInitialized, isTrue);
      resetAppInitialization();
      expect(isAppInitialized, isFalse);
    });
  });
}
