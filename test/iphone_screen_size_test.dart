import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_prime_app/core/router/app_router.dart';
import 'package:physio_prime_app/features/appointments/domain/appointment_model.dart';
import 'package:physio_prime_app/features/appointments/providers/appointments_provider.dart';
import 'package:physio_prime_app/features/auth/presentation/login_screen.dart';
import 'package:physio_prime_app/features/auth/presentation/profile_screen.dart';
import 'package:physio_prime_app/features/booking/presentation/booking_menu_screen.dart';
import 'package:physio_prime_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:physio_prime_app/features/doctors/presentation/doctors_screen.dart';
import 'package:physio_prime_app/features/home/domain/category_model.dart';
import 'package:physio_prime_app/features/home/presentation/category_detail_screen.dart';
import 'package:physio_prime_app/features/home/presentation/home_screen.dart';

class IPhoneDevice {
  final String name;
  final Size logicalSize;
  final double devicePixelRatio;
  final EdgeInsets padding; // Safe area: top (notch/dynamic island), bottom (home indicator)

  const IPhoneDevice({
    required this.name,
    required this.logicalSize,
    required this.devicePixelRatio,
    required this.padding,
  });
}

const iphoneDevices = [
  // 1. Compact / Smallest Supported: iPhone SE (2nd/3rd gen) & iPhone 8
  IPhoneDevice(
    name: 'iPhone SE (375x667)',
    logicalSize: Size(375, 667),
    devicePixelRatio: 2.0,
    padding: EdgeInsets.only(top: 20, bottom: 0),
  ),
  // 2. Compact with Notch: iPhone 12/13 mini
  IPhoneDevice(
    name: 'iPhone 13 mini (375x812)',
    logicalSize: Size(375, 812),
    devicePixelRatio: 3.0,
    padding: EdgeInsets.only(top: 44, bottom: 34),
  ),
  // 3. Standard Modern iPhone: iPhone 14/15/16
  IPhoneDevice(
    name: 'iPhone 15/16 (393x852 Dynamic Island)',
    logicalSize: Size(393, 852),
    devicePixelRatio: 3.0,
    padding: EdgeInsets.only(top: 59, bottom: 34),
  ),
  // 4. Large Flagship: iPhone 16 Pro Max
  IPhoneDevice(
    name: 'iPhone 16 Pro Max (440x956)',
    logicalSize: Size(440, 956),
    devicePixelRatio: 3.0,
    padding: EdgeInsets.only(top: 59, bottom: 34),
  ),
];

void setIPhoneViewport(WidgetTester tester, IPhoneDevice device) {
  final physicalWidth = device.logicalSize.width * device.devicePixelRatio;
  final physicalHeight = device.logicalSize.height * device.devicePixelRatio;

  tester.view.physicalSize = Size(physicalWidth, physicalHeight);
  tester.view.devicePixelRatio = device.devicePixelRatio;
  tester.view.padding = FakeViewPadding(
    top: device.padding.top * device.devicePixelRatio,
    bottom: device.padding.bottom * device.devicePixelRatio,
    left: device.padding.left * device.devicePixelRatio,
    right: device.padding.right * device.devicePixelRatio,
  );
}

FlutterErrorDetails? lastErrorDetails;

void main() {
  setUp(() {
    markAppInitialized();
    FlutterError.onError = (details) {
      lastErrorDetails = details;
    };
  });

  for (final device in iphoneDevices) {
    group('iOS Multi-Device Layout Verification: ${device.name}', () {
      testWidgets('HomeScreen renders with zero overflow', (tester) async {
        setIPhoneViewport(tester, device);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appointmentsProvider.overrideWith((ref) => Future.value(<AppointmentModel>[])),
            ],
            child: const MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        final exception = tester.takeException();
        if (exception is FlutterError) {
          for (final prop in exception.diagnostics) {
            debugPrint('PROP: ${prop.toStringDeep()}');
          }
        }
        expect(exception, isNull);
      });

      testWidgets('CategoryDetailScreen renders with zero overflow', (tester) async {
        setIPhoneViewport(tester, device);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);

        const sportsCat = CategoryModel(
          id: 'cat_sports',
          slug: 'sports-injury',
          title: 'Sports Injury',
          description: 'Rehabilitation for sports related injuries',
          doctorCount: 3,
        );

        await tester.pumpWidget(
          ProviderScope(
            child: const MaterialApp(
              home: CategoryDetailScreen(
                slug: 'sports-injury',
                category: sportsCat,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CategoryDetailScreen), findsOneWidget);
        final exception = tester.takeException();
        if (exception is FlutterError) {
          for (final prop in exception.diagnostics) {
            debugPrint('PROP: ${prop.toStringDeep()}');
          }
        }
        expect(exception, isNull);
      });

      testWidgets('LoginScreen renders with zero overflow', (tester) async {
        setIPhoneViewport(tester, device);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: LoginScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('DashboardScreen (History) renders with zero overflow', (tester) async {
        setIPhoneViewport(tester, device);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appointmentsProvider.overrideWith((ref) => Future.value(<AppointmentModel>[])),
            ],
            child: const MaterialApp(
              home: DashboardScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('ProfileScreen renders with zero overflow', (tester) async {
        setIPhoneViewport(tester, device);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appointmentsProvider.overrideWith((ref) => Future.value(<AppointmentModel>[])),
            ],
            child: const MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ProfileScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('BookingMenuScreen renders with zero overflow', (tester) async {
        setIPhoneViewport(tester, device);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appointmentsProvider.overrideWith((ref) => Future.value(<AppointmentModel>[])),
            ],
            child: const MaterialApp(
              home: BookingMenuScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BookingMenuScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('DoctorsScreen renders with zero overflow', (tester) async {
        setIPhoneViewport(tester, device);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appointmentsProvider.overrideWith((ref) => Future.value(<AppointmentModel>[])),
            ],
            child: const MaterialApp(
              home: DoctorsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DoctorsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('ScaffoldWithNavBar navigation shell adapts properly to safe areas', (tester) async {
        setIPhoneViewport(tester, device);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);

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

        expect(find.byType(ScaffoldWithNavBar), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }
}
