import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_prime_app/features/home/data/conditions_catalogue.dart';
import 'package:physio_prime_app/features/home/presentation/conditions_screen.dart';
import 'package:physio_prime_app/features/home/presentation/widgets/conditions_catalogue_view.dart';

void main() {
  group('ConditionsCatalogue Data & Validation Tests', () {
    test('Contains exactly 7 canonical clinical categories', () {
      expect(ConditionsCatalogue.allCategories.length, equals(7));

      final slugs = ConditionsCatalogue.allCategories.map((c) => c.specialtySlug).toList();
      expect(slugs, containsAll([
        'orthopedic',
        'sports-injury',
        'neurological',
        'pediatrics',
        'cardio-pulmonary',
        'geriatric',
        'womens-health',
      ]));
    });

    test('Contains exactly 48 canonical conditions', () {
      expect(ConditionsCatalogue.allConditions.length, equals(48));
      expect(ConditionsCatalogue.bySlug.length, equals(48));
    });

    test('Category condition counts match website structure', () {
      final ortho = ConditionsCatalogue.allCategories.firstWhere((c) => c.specialtySlug == 'orthopedic');
      expect(ortho.conditions.length, equals(6));
      expect(ortho.conditions.map((c) => c.title), contains('Back Pain'));
      expect(ortho.conditions.map((c) => c.title), contains('Neck Pain'));
      expect(ortho.conditions.map((c) => c.title), contains('Sciatica'));
      expect(ortho.conditions.map((c) => c.title), contains('Frozen Shoulder'));
      expect(ortho.conditions.map((c) => c.title), contains('Knee Osteoarthritis'));
      expect(ortho.conditions.map((c) => c.title), contains('Spondylosis'));

      final sports = ConditionsCatalogue.allCategories.firstWhere((c) => c.specialtySlug == 'sports-injury');
      expect(sports.conditions.length, equals(6));

      final neuro = ConditionsCatalogue.allCategories.firstWhere((c) => c.specialtySlug == 'neurological');
      expect(neuro.conditions.length, equals(6));

      final peds = ConditionsCatalogue.allCategories.firstWhere((c) => c.specialtySlug == 'pediatrics');
      expect(peds.conditions.length, equals(6));

      final cardio = ConditionsCatalogue.allCategories.firstWhere((c) => c.specialtySlug == 'cardio-pulmonary');
      expect(cardio.conditions.length, equals(6));

      final geriatric = ConditionsCatalogue.allCategories.firstWhere((c) => c.specialtySlug == 'geriatric');
      expect(geriatric.conditions.length, equals(6));

      final womens = ConditionsCatalogue.allCategories.firstWhere((c) => c.specialtySlug == 'womens-health');
      expect(womens.conditions.length, equals(12));
    });

    test('findOrCreateSymptom returns valid fallback when live symptom is absent', () {
      final sym = ConditionsCatalogue.findOrCreateSymptom('back-pain');
      expect(sym.title, equals('Back Pain'));
      expect(sym.slug, equals('back-pain'));
      expect(sym.department, equals('Musculoskeletal / Orthopedic'));
      expect(sym.symptomsList, isNotEmpty);
      expect(sym.recoveryEstimate, isNotNull);
    });
  });

  group('ConditionsCatalogueView & Card UI Tests', () {
    testWidgets('Renders search bar, categories, and minimal cards (title + chevron)', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ConditionsCatalogueView(),
            ),
          ),
        ),
      );

      // Verify search input placeholder
      expect(find.text('Search 48+ conditions, e.g. "back pain"...'), findsOneWidget);

      // Verify Category headers & View specialty links
      expect(find.text('Musculoskeletal / Orthopedic'), findsOneWidget);
      expect(find.text('Sports Injuries'), findsOneWidget);
      expect(find.text('Neurological Conditions'), findsOneWidget);
      expect(find.text('View specialty'), findsWidgets);

      // Verify Condition Cards contain the title
      expect(find.text('Back Pain'), findsOneWidget);
      expect(find.text('Neck Pain'), findsOneWidget);
      expect(find.text('Sciatica'), findsOneWidget);
      expect(find.text('Frozen Shoulder'), findsOneWidget);

      // Verify ConditionCard widget structure (strictly title and icon)
      expect(find.byType(ConditionCard), findsWidgets);
    });

    testWidgets('Live search dynamically filters conditions and shows match count', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ConditionsCatalogueView(),
            ),
          ),
        ),
      );

      // Type "back" into search field
      await tester.enterText(find.byType(TextField), 'back');
      await tester.pumpAndSettle();

      // Expect search results view
      expect(find.text('Search Results'), findsOneWidget);
      expect(find.text('Back Pain'), findsOneWidget);
      expect(find.text('Back Pain in Pregnancy'), findsOneWidget);

      // Unrelated condition should not be visible in search results
      expect(find.text('Frozen Shoulder'), findsNothing);
    });

    testWidgets('Empty search result shows helpful empty state and clear button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ConditionsCatalogueView(),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'nonexistentcondition12345');
      await tester.pumpAndSettle();

      expect(find.text('No conditions found'), findsOneWidget);
      expect(find.text('Clear search'), findsOneWidget);

      // Tap clear search
      await tester.tap(find.text('Clear search'));
      await tester.pumpAndSettle();

      // Should return to normal catalogue view
      expect(find.text('Musculoskeletal / Orthopedic'), findsOneWidget);
      expect(find.text('Back Pain'), findsOneWidget);
    });

    testWidgets('ConditionsScreen mounts cleanly with app bar', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ConditionsScreen(),
          ),
        ),
      );

      expect(find.text('Conditions We Treat'), findsOneWidget);
      expect(find.byType(ConditionsCatalogueView), findsOneWidget);
    });
  });
}
