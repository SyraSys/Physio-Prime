import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../doctors/providers/doctors_provider.dart';
import '../domain/category_model.dart';
import '../providers/home_provider.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final String slug;
  final CategoryModel? category;

  const CategoryDetailScreen({
    super.key,
    required this.slug,
    this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If category wasn't passed via extra, find it from categoriesProvider
    final categoriesAsync = ref.watch(categoriesProvider);
    final cat = category ??
        categoriesAsync.value?.where((c) => c.slug == slug).firstOrNull;

    if (cat == null && categoriesAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (cat == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Specialty Detail')),
        body: const Center(child: Text('Specialty category not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(cat.title),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cat.image != null)
              CachedNetworkImage(
                imageUrl: cat.image!,
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
                  Text(cat.title, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 10),
                  Text(cat.description, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 24),

                  if (cat.conditions.isNotEmpty) ...[
                    Text('Common Conditions Treated', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: cat.conditions.map((cond) {
                        return ActionChip(
                          avatar: const Icon(LucideIcons.checkCircle, size: 16, color: AppColors.primary),
                          label: Text(cond),
                          backgroundColor: AppColors.surfaceSoft,
                          side: const BorderSide(color: AppColors.borderSoft),
                          onPressed: () {
                            ref.read(doctorFilterProvider.notifier).update(
                                  (s) => s.copyWith(search: cond),
                                );
                            context.go('/doctors');
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                  ],

                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(doctorFilterProvider.notifier).update(
                            (s) => s.copyWith(category: cat.slug),
                          );
                      context.go('/doctors');
                    },
                    icon: const Icon(LucideIcons.search, size: 18),
                    label: Text('Find ${cat.title} Specialists'),
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
