import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_prime_app/core/router/app_router.dart';
import 'package:physio_prime_app/features/appointments/domain/appointment_model.dart';
import 'package:physio_prime_app/features/appointments/providers/appointments_provider.dart';
import 'package:physio_prime_app/features/home/presentation/home_screen.dart';
import 'package:physio_prime_app/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  setUp(() {
    markAppInitialized();
  });

  group('Auth & Route Redirect Tests (NavMenu preservation)', () {
    testWidgets('Opening /dashboard redirects to / (Home) with ScaffoldWithNavBar intact', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appointmentsProvider.overrideWith((ref) => Future.value(<AppointmentModel>[])),
          ],
          child: MaterialApp.router(
            routerConfig: appRouter,
          ),
        ),
      );

      appRouter.go('/dashboard');
      await tester.pumpAndSettle();

      // Should land on HomeScreen, NOT on fullscreen standalone DashboardScreen
      expect(find.byType(HomeScreen), findsOneWidget);
      // Bottom navigation bar ScaffoldWithNavBar must be visible
      expect(find.byType(ScaffoldWithNavBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Opening /auth-callback redirects to / (Home) with ScaffoldWithNavBar intact', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appointmentsProvider.overrideWith((ref) => Future.value(<AppointmentModel>[])),
          ],
          child: MaterialApp.router(
            routerConfig: appRouter,
          ),
        ),
      );

      appRouter.go('/auth-callback');
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(ScaffoldWithNavBar), findsOneWidget);
    });

    testWidgets('Opening /history renders DashboardScreen WITH ScaffoldWithNavBar intact', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appointmentsProvider.overrideWith((ref) => Future.value(<AppointmentModel>[])),
          ],
          child: MaterialApp.router(
            routerConfig: appRouter,
          ),
        ),
      );

      appRouter.go('/history');
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(ScaffoldWithNavBar), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });
  });
}
