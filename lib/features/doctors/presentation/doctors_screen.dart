import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fluid_pressable.dart';
import '../../../core/widgets/frosted_glass.dart';
import '../../home/providers/home_provider.dart';
import '../providers/doctors_provider.dart';
import 'widgets/doctor_card.dart';

class DoctorsScreen extends ConsumerStatefulWidget {
  const DoctorsScreen({super.key});

  @override
  ConsumerState<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends ConsumerState<DoctorsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final filter = ref.watch(doctorFilterProvider);
            final locationsAsync = ref.watch(locationsProvider);

            return FrostedGlassContainer(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              backgroundColor: const Color(0xF7FFFFFF), // 97% translucent
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
                        Text('Filter Doctors', style: Theme.of(context).textTheme.titleLarge),
                        TextButton(
                          onPressed: () {
                            ref.read(doctorFilterProvider.notifier).state = const DoctorFilterState();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Reset', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Mode selection
                    const Text('Consultation Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.headingText)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All Modes'),
                          selected: filter.mode == null || filter.mode == 'all',
                          onSelected: (_) => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(mode: 'all')),
                        ),
                        ChoiceChip(
                          avatar: const Icon(LucideIcons.home, size: 14),
                          label: const Text('Home Visit'),
                          selected: filter.mode == 'home',
                          onSelected: (_) => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(mode: 'home')),
                        ),
                        ChoiceChip(
                          avatar: const Icon(LucideIcons.video, size: 14),
                          label: const Text('Online Video'),
                          selected: filter.mode == 'online',
                          onSelected: (_) => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(mode: 'online')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Gender selection
                    const Text('Doctor Gender', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.headingText)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Any'),
                          selected: filter.gender == null || filter.gender == 'all',
                          onSelected: (_) => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(gender: 'all')),
                        ),
                        ChoiceChip(
                          label: const Text('Female'),
                          selected: filter.gender == 'female',
                          onSelected: (_) => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(gender: 'female')),
                        ),
                        ChoiceChip(
                          label: const Text('Male'),
                          selected: filter.gender == 'male',
                          onSelected: (_) => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(gender: 'male')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Area selection
                    const Text('Service Area', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.headingText)),
                    const SizedBox(height: 8),
                    locationsAsync.when(
                      data: (master) {
                        return DropdownButtonFormField<String>(
                          initialValue: filter.area,
                          hint: const Text('Select Area (Nagpur)'),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Areas')),
                            ...master.areas.map((a) => DropdownMenuItem(value: a, child: Text(a))),
                          ],
                          onChanged: (val) {
                            ref.read(doctorFilterProvider.notifier).update(
                                  (s) => s.copyWith(area: val, clearArea: val == null),
                                );
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (error, stack) => const SizedBox(),
                    ),
                    const SizedBox(height: 24),

                    FluidPressable(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(doctorsListProvider);
    final filter = ref.watch(doctorFilterProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FrostedGlassAppBar(
        title: const Text('Find Physiotherapists'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FluidPressable(
              onTap: () => _showFilterModal(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (filter.area != null || (filter.mode != null && filter.mode != 'all') || (filter.gender != null && filter.gender != 'all'))
                      ? AppColors.surfaceSoft
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (filter.area != null || (filter.mode != null && filter.mode != 'all'))
                        ? AppColors.primary
                        : Colors.transparent,
                  ),
                ),
                child: Stack(
                  children: [
                    const Icon(LucideIcons.slidersHorizontal, size: 20),
                    if (filter.area != null || (filter.mode != null && filter.mode != 'all') || (filter.gender != null && filter.gender != 'all'))
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 8),

          // Search Bar with Apple inset look
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search doctors, conditions, or treatments...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.bodyText),
                prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(search: ''));
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.borderSoft),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.borderSoft),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: (query) {
                ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(search: query.trim()));
              },
            ),
          ),

          // Active filter badges
          if (filter.area != null || (filter.mode != null && filter.mode != 'all') || filter.symptom != null || filter.category != null)
            Container(
              height: 36,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (filter.area != null)
                    _FilterChip(
                      label: filter.area!,
                      onDeleted: () => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(clearArea: true)),
                    ),
                  if (filter.mode != null && filter.mode != 'all')
                    _FilterChip(
                      label: filter.mode == 'home' ? 'Home Visit' : 'Video Consult',
                      onDeleted: () => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(mode: 'all')),
                    ),
                  if (filter.symptom != null)
                    _FilterChip(
                      label: filter.symptom!,
                      onDeleted: () => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(clearSymptom: true)),
                    ),
                  if (filter.category != null)
                    _FilterChip(
                      label: filter.category!,
                      onDeleted: () => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(clearCategory: true)),
                    ),
                ],
              ),
            ),

          // Doctor List with iOS BouncingScrollPhysics
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.refresh(doctorsListProvider),
              child: doctorsAsync.when(
                data: (doctors) {
                  if (doctors.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.userX, size: 52, color: Colors.grey),
                            const SizedBox(height: 14),
                            const Text(
                              'No Physiotherapists Found',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Try clearing active filters or searching for another condition.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.bodyText, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () {
                                _searchController.clear();
                                ref.read(doctorFilterProvider.notifier).state = const DoctorFilterState();
                              },
                              child: const Text('Reset All Filters'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      return DoctorCard(doctor: doctors[index]);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 44),
                        const SizedBox(height: 12),
                        const Text('Could not load doctors', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(e.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.bodyText)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.refresh(doctorsListProvider),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;

  const _FilterChip({required this.label, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.surfaceSoft,
        side: const BorderSide(color: AppColors.borderSoft),
        deleteIcon: const Icon(LucideIcons.x, size: 14, color: AppColors.primary),
        onDeleted: onDeleted,
      ),
    );
  }
}
