import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_prime_app/features/doctors/presentation/doctor_detail_screen.dart';
import 'package:physio_prime_app/features/doctors/providers/doctors_provider.dart';

void main() {
  testWidgets('DoctorDetailScreen gracefully handles 404 error without throwing DioException', (tester) async {
    FlutterErrorDetails? caughtDetails;
    FlutterError.onError = (details) {
      caughtDetails = details;
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doctorDetailProvider('archived-cancelled-doctor').overrideWith((ref) async {
            throw DioException(
              requestOptions: RequestOptions(path: '/doctors/archived-cancelled-doctor'),
              response: Response(
                requestOptions: RequestOptions(path: '/doctors/archived-cancelled-doctor'),
                statusCode: 404,
              ),
              type: DioExceptionType.badResponse,
            );
          }),
        ],
        child: const MaterialApp(
          home: DoctorDetailScreen(slug: 'archived-cancelled-doctor'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Must not catch any unhandled FlutterError / widget build crash
    expect(caughtDetails, isNull);
    expect(tester.takeException(), isNull);

    // Verifies the user-friendly fallback is rendered gracefully
    expect(find.text('Doctor Profile Unavailable'), findsOneWidget);
    expect(find.text('Back to Appointments'), findsOneWidget);
  });
}
