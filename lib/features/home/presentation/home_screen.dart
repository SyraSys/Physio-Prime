import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fluid_pressable.dart';
import '../../../core/widgets/frosted_glass.dart';
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FrostedGlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          backgroundColor: const Color(0xF2FFFFFF), // 95% translucent
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // iOS drag handle pill
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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

                    return SizedBox(
                      height: 380,
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: areas.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderSoft),
                        itemBuilder: (context, index) {
                          final area = areas[index];
                          final isSelected = (area == 'All Areas' && currentArea == null) ||
                              currentArea == area;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            title: Text(
                              area,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.primary : AppColors.headingText,
                                fontSize: 15,
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
                  loading: () => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
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
      extendBodyBehindAppBar: true,
      appBar: FrostedGlassAppBar(
        title: FluidPressable(
          onTap: () => _showLocationPicker(context, ref),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.mapPin, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        selectedArea != null ? '$selectedArea, $selectedCity' : selectedCity,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.headingText),
                      ),
                      const SizedBox(width: 3),
                      const Icon(LucideIcons.chevronDown, size: 14, color: AppColors.bodyText),
                    ],
                  ),
                  Text('Service Area', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FluidPressable(
              onTap: () {
                if (authState.status == AuthStatus.authenticated) {
                  context.push('/profile');
                } else {
                  context.push('/login');
                }
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: const Icon(LucideIcons.user, size: 18, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        displacement: 90,
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(symptomsProvider);
          ref.invalidate(locationsProvider);
          ref.invalidate(doctorsListProvider);
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Apple-style Fluid Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x330891B2),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF), // Translucent glass pill
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x4DFFFFFF)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.shieldCheck, color: Colors.white, size: 14),
                          SizedBox(width: 5),
                          Text(
                            'State Council Verified Specialists',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Premium Home &\nOnline Physiotherapy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Accredited therapists bringing clinical electrotherapy, manual rehabilitation, and postural exercises to your doorstep.',
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.45),
                    ),
                    const SizedBox(height: 18),
                    FluidPressable(
                      onTap: () => context.go('/doctors'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1F000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.search, size: 16, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'Find Doctors Near You',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Consultation Mode Filter Buttons with tactile press
              Row(
                children: [
                  Expanded(
                    child: FluidPressable(
                      onTap: () {
                        final newMode = selectedMode == 'home' ? 'all' : 'home';
                        ref.read(selectedModeProvider.notifier).state = newMode;
                        ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(mode: newMode));
                        context.go('/doctors');
                      },
                      child: _ModeSelectCard(
                        icon: LucideIcons.home,
                        title: 'Home Visits',
                        subtitle: 'Doctor travels to you',
                        isSelected: selectedMode == 'home',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FluidPressable(
                      onTap: () {
                        final newMode = selectedMode == 'online' ? 'all' : 'online';
                        ref.read(selectedModeProvider.notifier).state = newMode;
                        ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(mode: newMode));
                        context.go('/doctors');
                      },
                      child: _ModeSelectCard(
                        icon: LucideIcons.video,
                        title: 'Video Consult',
                        subtitle: '1-on-1 HD Telehealth',
                        isSelected: selectedMode == 'online',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Specialty Categories Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Clinical Specialties', style: Theme.of(context).textTheme.titleLarge),
                  FluidPressable(
                    onTap: () => context.go('/doctors'),
                    child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              categoriesAsync.when(
                data: (categories) {
                  return SizedBox(
                    height: 165,
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        return FluidPressable(
                          onTap: () => context.push('/categories/${cat.slug}', extra: cat),
                          child: _CategoryCard(category: cat),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                error: (error, stack) => Text('Error loading categories: $error'),
              ),
              const SizedBox(height: 28),

              // Common Conditions & Symptoms Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Common Conditions', style: Theme.of(context).textTheme.titleLarge),
                  FluidPressable(
                    onTap: () => context.go('/doctors'),
                    child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              symptomsAsync.when(
                data: (symptoms) {
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: symptoms.take(5).length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final sym = symptoms[index];
                      return FluidPressable(
                        onTap: () => context.push('/conditions/${sym.slug}', extra: sym),
                        child: _ConditionTile(symptom: sym),
                      );
                    },
                  );
                },
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                error: (error, stack) => Text('Error loading conditions: $error'),
              ),
              const SizedBox(height: 28),

              // Caretaker Request Assistance Card
              FluidPressable(
                onTap: () => context.push('/caretaker'),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderSoft),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderSoft),
                        ),
                        child: const Icon(LucideIcons.heartHandshake, color: AppColors.primary, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Need a Home Caretaker?',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.headingText),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Trained attendants for post-stroke recovery, mobility assistance & elderly support.',
                              style: TextStyle(color: AppColors.bodyText, fontSize: 12, height: 1.35),
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Text(
                                  'Request Attendant',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                SizedBox(width: 4),
                                Icon(LucideIcons.arrowRight, size: 13, color: AppColors.primary),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Join as a Physiotherapist (Careers) Card
              FluidPressable(
                onTap: () => context.push('/careers'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.stethoscope, color: AppColors.accentTeal, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Are you a Physiotherapist?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Join PhysioPrime clinical network', style: TextStyle(fontSize: 12, color: AppColors.bodyText)),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
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

  const _ModeSelectCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.surfaceSoft : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.borderSoft,
          width: isSelected ? 1.8 : 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isSelected ? AppColors.primary : AppColors.bodyText, size: 22),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.headingText)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.bodyText)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 136,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft, width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            child: category.image != null
                ? CachedNetworkImage(
                    imageUrl: category.image!,
                    height: 88,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: AppColors.surfaceSoft),
                    errorWidget: (context, url, error) => Container(color: AppColors.surfaceSoft, child: const Icon(LucideIcons.activity, color: AppColors.primary)),
                  )
                : Container(
                    height: 88,
                    color: AppColors.surfaceSoft,
                    child: const Center(child: Icon(LucideIcons.activity, color: AppColors.primary)),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              category.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.headingText, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionTile extends StatelessWidget {
  final SymptomModel symptom;

  const _ConditionTile({required this.symptom});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft, width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: symptom.image != null
              ? CachedNetworkImage(
                  imageUrl: symptom.image!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(width: 50, height: 50, color: AppColors.surfaceSoft),
                  errorWidget: (context, url, error) => Container(width: 50, height: 50, color: AppColors.surfaceSoft, child: const Icon(LucideIcons.activity, color: AppColors.primary, size: 20)),
                )
              : Container(width: 50, height: 50, color: AppColors.surfaceSoft, child: const Icon(LucideIcons.activity, color: AppColors.primary, size: 20)),
        ),
        title: Text(symptom.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.headingText)),
        subtitle: Text(
          symptom.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.bodyText, height: 1.3),
        ),
        trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey),
      ),
    );
  }
}
