import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_prime_app/core/router/app_router.dart';
import 'package:physio_prime_app/features/appointments/domain/appointment_model.dart';
import 'package:physio_prime_app/features/appointments/providers/appointments_provider.dart';

void main() {
  setUp(() {
    markAppInitialized();
  });

  group('Bottom Navigation Bar Responsive Layout Tests', () {
    testWidgets('Xiaomi/MIUI 3-Button Navigation Bug: viewPadding=0, padding=0 on Android', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      const double screenWidth = 393;
      const double screenHeight = 851;
      const double systemNavBarHeight = 48.0;

      tester.view.physicalSize = const Size(screenWidth, screenHeight);
      tester.view.devicePixelRatio = 1.0;
      // On Xiaomi/Redmi (MIUI), the 3-button navigation bar renders an opaque 48dp black bar
      // but fails to report window insets to Flutter (both viewPadding and padding report 0).
      tester.view.padding = FakeViewPadding.zero;
      tester.view.viewPadding = FakeViewPadding.zero;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

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
      await tester.pumpAndSettle();

      final navBarFinder = find.byType(ScaffoldWithNavBar);
      expect(navBarFinder, findsOneWidget);

      final itemFinder = find.text('Home');
      expect(itemFinder, findsOneWidget);

      final homeTextBottom = tester.getBottomLeft(itemFinder).dy;
      // System navigation bar starts at screenHeight - 48 = 803.0
      const systemBarTop = screenHeight - systemNavBarHeight;
      // Home label must be strictly above system bar top (803.0)
      expect(homeTextBottom, lessThan(systemBarTop));

      final containerFinder = find.descendant(
        of: find.byType(ScaffoldWithNavBar),
        matching: find.byWidgetPredicate((widget) {
          if (widget is Container && widget.decoration is BoxDecoration) {
            final box = widget.decoration as BoxDecoration;
            return box.color == Colors.white && box.borderRadius == BorderRadius.circular(33);
          }
          return false;
        }),
      );
      expect(containerFinder, findsOneWidget);

      final containerBottom = tester.getBottomLeft(containerFinder).dy;
      // Expected container bottom is at screenHeight - 58.0 (48.0 3-button bar + 10.0 margin)
      expect(containerBottom, equals(screenHeight - 58.0));
      // Container bottom must be strictly above the 3-button navigation bar (803.0)
      expect(containerBottom, lessThan(systemBarTop));
    });

    testWidgets('Standard Android 3-Button Navigation (reported insets: viewPadding=48)', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      const double screenWidth = 393;
      const double screenHeight = 851;
      const double systemNavBarHeight = 48.0;

      tester.view.physicalSize = const Size(screenWidth, screenHeight);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = FakeViewPadding.zero;
      tester.view.viewPadding = const FakeViewPadding(bottom: systemNavBarHeight);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

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
      await tester.pumpAndSettle();

      final containerFinder = find.descendant(
        of: find.byType(ScaffoldWithNavBar),
        matching: find.byWidgetPredicate((widget) {
          if (widget is Container && widget.decoration is BoxDecoration) {
            final box = widget.decoration as BoxDecoration;
            return box.color == Colors.white && box.borderRadius == BorderRadius.circular(33);
          }
          return false;
        }),
      );
      expect(containerFinder, findsOneWidget);

      final containerBottom = tester.getBottomLeft(containerFinder).dy;
      // Expected container bottom: screenHeight - (48 + 10) = 793.0
      expect(containerBottom, equals(screenHeight - (systemNavBarHeight + 10.0)));
    });

    testWidgets('Android Gesture Navigation (viewPadding=16, padding=16)', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      const double screenWidth = 393;
      const double screenHeight = 851;
      const double gestureBarHeight = 16.0;

      tester.view.physicalSize = const Size(screenWidth, screenHeight);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: gestureBarHeight);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: gestureBarHeight);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

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
      await tester.pumpAndSettle();

      final containerFinder = find.descendant(
        of: find.byType(ScaffoldWithNavBar),
        matching: find.byWidgetPredicate((widget) {
          if (widget is Container && widget.decoration is BoxDecoration) {
            final box = widget.decoration as BoxDecoration;
            return box.color == Colors.white && box.borderRadius == BorderRadius.circular(33);
          }
          return false;
        }),
      );
      expect(containerFinder, findsOneWidget);

      final containerBottom = tester.getBottomLeft(containerFinder).dy;
      // Expected: 16 + 8 = 24 -> screenHeight - 24 = 827.0
      expect(containerBottom, equals(screenHeight - (gestureBarHeight + 8.0)));
    });

    testWidgets('iOS Flagship with Home Indicator (iPhone 16 / 15: padding=34, viewPadding=34)', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      const double screenWidth = 393;
      const double screenHeight = 852;
      const double homeIndicatorSafeHeight = 34.0;

      tester.view.physicalSize = const Size(screenWidth, screenHeight);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(top: 59, bottom: homeIndicatorSafeHeight);
      tester.view.viewPadding = const FakeViewPadding(top: 59, bottom: homeIndicatorSafeHeight);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

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
      await tester.pumpAndSettle();

      final containerFinder = find.descendant(
        of: find.byType(ScaffoldWithNavBar),
        matching: find.byWidgetPredicate((widget) {
          if (widget is Container && widget.decoration is BoxDecoration) {
            final box = widget.decoration as BoxDecoration;
            return box.color == Colors.white && box.borderRadius == BorderRadius.circular(33);
          }
          return false;
        }),
      );
      expect(containerFinder, findsOneWidget);

      final containerBottom = tester.getBottomLeft(containerFinder).dy;
      // Expected: floats 8pt above the 34pt safe area -> screenHeight - (34 + 8) = 810.0
      expect(containerBottom, equals(screenHeight - (homeIndicatorSafeHeight + 8.0)));
    });

    testWidgets('iOS Compact / Zero Insets (iPhone SE / older devices: bottom insets = 0)', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      const double screenWidth = 375;
      const double screenHeight = 667;

      tester.view.physicalSize = const Size(screenWidth, screenHeight);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(top: 20, bottom: 0);
      tester.view.viewPadding = const FakeViewPadding(top: 20, bottom: 0);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

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
      await tester.pumpAndSettle();

      final containerFinder = find.descendant(
        of: find.byType(ScaffoldWithNavBar),
        matching: find.byWidgetPredicate((widget) {
          if (widget is Container && widget.decoration is BoxDecoration) {
            final box = widget.decoration as BoxDecoration;
            return box.color == Colors.white && box.borderRadius == BorderRadius.circular(33);
          }
          return false;
        }),
      );
      expect(containerFinder, findsOneWidget);

      final containerBottom = tester.getBottomLeft(containerFinder).dy;
      // Expected: default 16px bottom margin when physical home button exists on iOS
      expect(containerBottom, equals(screenHeight - 16.0));
    });
  });
}
