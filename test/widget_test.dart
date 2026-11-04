import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physio_prime_app/main.dart';

void main() {
  testWidgets('PhysioPrimeApp root widget pump test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PhysioPrimeApp(),
      ),
    );
    expect(find.byType(PhysioPrimeApp), findsOneWidget);
  });
}
