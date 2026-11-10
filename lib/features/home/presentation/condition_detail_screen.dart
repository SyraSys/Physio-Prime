import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../doctors/providers/doctors_provider.dart';
import '../domain/symptom_model.dart';
import '../providers/home_provider.dart';

class ConditionDetailScreen extends ConsumerWidget {
  final String slug;
  final SymptomModel? symptom;

  const ConditionDetailScreen({
    super.key,
    required this.slug,
    this.symptom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symptomsAsync = ref.watch(symptomsProvider);
    final sym = symptom ??
        symptomsAsync.value?.where((s) => s.slug == slug).firstOrNull;

    if (sym == null && symptomsAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (sym == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Condition Detail')),
        body: const Center(child: Text('Condition details not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(sym.title),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sym.image != null)
              CachedNetworkImage(
                imageUrl: sym.image!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(height: 200, color: AppColors.surfaceSoft),
                errorWidget: (context, url, error) => Container(height: 200, color: AppColors.surfaceSoft),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sym.title, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 10),
                  Text(sym.description, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 20),

                  if (sym.recoveryEstimate != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSoft),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.clock, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Estimated Recovery Timeline', style: TextStyle(fontSize: 11, color: AppColors.bodyText)),
                              Text(sym.recoveryEstimate!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  if (sym.symptomsList.isNotEmpty) ...[
                    Text('Common Symptoms', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    ...sym.symptomsList.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(LucideIcons.alertCircle, color: AppColors.accentTeal, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item, style: const TextStyle(fontSize: 14, color: AppColors.headingText))),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],

                  if (sym.treatment != null) ...[
                    Text('Physiotherapy Treatment Plan', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(sym.treatment!, style: const TextStyle(fontSize: 14, color: AppColors.bodyText, height: 1.5)),
                    const SizedBox(height: 28),
                  ],

                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(doctorFilterProvider.notifier).update(
                            (s) => s.copyWith(symptom: sym.slug),
                          );
                      context.go('/doctors');
                    },
                    icon: const Icon(LucideIcons.calendar, size: 18),
                    label: Text('Book Doctor for ${sym.title}'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
