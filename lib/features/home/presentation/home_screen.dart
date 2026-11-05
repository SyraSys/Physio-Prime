import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../doctors/providers/doctors_provider.dart';
import '../domain/category_model.dart';
import '../domain/symptom_model.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showLocationPicker(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.read(locationsProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Select Your Location', style: Theme.of(context).textTheme.titleLarge),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                locationsAsync.when(
                  data: (master) {
                    final areas = ['All Areas', ...master.areas];
                    final currentArea = ref.watch(selectedAreaProvider);

                    return Expanded(
                      child: ListView.separated(
                        itemCount: areas.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final area = areas[index];
                          final isSelected = (area == 'All Areas' && currentArea == null) ||
                              currentArea == area;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              area,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.primary : AppColors.headingText,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(LucideIcons.check, color: AppColors.primary, size: 18)
                                : null,
                            onTap: () {
                              ref.read(selectedAreaProvider.notifier).state =
                                  area == 'All Areas' ? null : area;
                              ref.read(doctorFilterProvider.notifier).update(
                                    (s) => s.copyWith(
                                      area: area == 'All Areas' ? null : area,
                                      clearArea: area == 'All Areas',
                                    ),
                                  );
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => const Text('Could not load areas. Please try again.'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCity = ref.watch(selectedCityProvider);
    final selectedArea = ref.watch(selectedAreaProvider);
    final selectedMode = ref.watch(selectedModeProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final symptomsAsync = ref.watch(symptomsProvider);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: GestureDetector(
          onTap: () => _showLocationPicker(context, ref),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.mapPin, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        selectedArea != null ? '$selectedArea, $selectedCity' : selectedCity,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.headingText),
                      ),
                      const Icon(LucideIcons.chevronDown, size: 14, color: AppColors.bodyText),
                    ],
                  ),
                  const Text('Service Area', style: TextStyle(fontSize: 11, color: AppColors.bodyText)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.user),
            onPressed: () {
              if (authState.status == AuthStatus.authenticated) {
                context.push('/profile');
              } else {
                context.push('/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(symptomsProvider);
          ref.invalidate(locationsProvider);
          ref.invalidate(doctorsListProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner with Gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x400891B2),
                      blurRadius: 15,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.shieldCheck, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Certified Specialists',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Premium Home & Online\nPhysiotherapy Care',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Get diagnosed and treated by vetted physiotherapists at home or via video consult.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/doctors'),
                      icon: const Icon(LucideIcons.search, size: 16, color: AppColors.primary),
                      label: const Text('Find Doctors Near You'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Consultation Mode Filter Buttons
              Row(
                children: [
                  Expanded(
                    child: _ModeSelectCard(
                      icon: LucideIcons.home,
                      title: 'Home Visits',
                      subtitle: 'Doctor visits you',
                      isSelected: selectedMode == 'home',
                      onTap: () {
                        final newMode = selectedMode == 'home' ? 'all' : 'home';
                        ref.read(selectedModeProvider.notifier).state = newMode;
                        ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(mode: newMode));
                        context.go('/doctors');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModeSelectCard(
                      icon: LucideIcons.video,
                      title: 'Video Consult',
                      subtitle: 'HD Telehealth 1-on-1',
                      isSelected: selectedMode == 'online',
                      onTap: () {
                        final newMode = selectedMode == 'online' ? 'all' : 'online';
                        ref.read(selectedModeProvider.notifier).state = newMode;
                        ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(mode: newMode));
                        context.go('/doctors');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Specialty Categories
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Clinical Specialties', style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: () => context.go('/doctors'),
                    child: const Text('View All', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              categoriesAsync.when(
                data: (categories) {
                  return SizedBox(
                    height: 155,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        return _CategoryCard(
                          category: cat,
                          onTap: () => context.push('/categories/${cat.slug}', extra: cat),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                error: (e, _) => Text('Error loading categories: $e'),
              ),
              const SizedBox(height: 28),

              // Common Conditions & Symptoms
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Common Conditions', style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: () => context.go('/doctors'),
                    child: const Text('View All', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              symptomsAsync.when(
                data: (symptoms) {
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: symptoms.take(5).length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final sym = symptoms[index];
                      return _ConditionTile(
                        symptom: sym,
                        onTap: () => context.push('/conditions/${sym.slug}', extra: sym),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading conditions: $e'),
              ),
              const SizedBox(height: 28),

              // Caretaker Request Assistance Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0x1F0891B2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.heartHandshake, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Need a Home Caretaker?',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.headingText),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Elderly care, stroke patient assistance, and trained nursing attendants.',
                            style: TextStyle(color: AppColors.bodyText, fontSize: 12),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              backgroundColor: AppColors.primary,
                            ),
                            onPressed: () => context.push('/caretaker'),
                            child: const Text('Request Assistance', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Join as a Physiotherapist (Careers) Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.stethoscope, color: AppColors.accentTeal, size: 32),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Are you a Physiotherapist?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 2),
                            const Text('Join PhysioPrime clinical network & grow your practice.', style: TextStyle(fontSize: 12, color: AppColors.bodyText)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/careers'),
                        child: const Text('Join Us', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeSelectCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeSelectCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceSoft : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderSoft,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.bodyText, size: 24),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.headingText)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.bodyText)),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: category.image != null
                  ? CachedNetworkImage(
                      imageUrl: category.image!,
                      height: 80,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: AppColors.surfaceSoft),
                      errorWidget: (context, url, error) => Container(color: AppColors.surfaceSoft, child: const Icon(LucideIcons.activity, color: AppColors.primary)),
                    )
                  : Container(
                      height: 80,
                      color: AppColors.surfaceSoft,
                      child: const Center(child: Icon(LucideIcons.activity, color: AppColors.primary)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.headingText),
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

class _ConditionTile extends StatelessWidget {
  final SymptomModel symptom;
  final VoidCallback onTap;

  const _ConditionTile({required this.symptom, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: symptom.image != null
              ? CachedNetworkImage(
                  imageUrl: symptom.image!,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(width: 52, height: 52, color: AppColors.surfaceSoft),
                  errorWidget: (context, url, error) => Container(width: 52, height: 52, color: AppColors.surfaceSoft, child: const Icon(LucideIcons.activity, color: AppColors.primary, size: 20)),
                )
              : Container(width: 52, height: 52, color: AppColors.surfaceSoft, child: const Icon(LucideIcons.activity, color: AppColors.primary, size: 20)),
        ),
        title: Text(symptom.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(
          symptom.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.bodyText),
        ),
        trailing: const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
      ),
    );
  }
}
