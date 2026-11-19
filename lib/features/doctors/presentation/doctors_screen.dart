import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
  final _searchFocusNode = FocusNode();
  bool _isSearchOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  int _calculateActiveFilterCount(DoctorFilterState filter) {
    int count = 0;
    if (filter.area != null && filter.area!.isNotEmpty && filter.area != 'All Areas') count++;
    if (filter.mode != null && filter.mode != 'all') count++;
    if (filter.category != null && filter.category!.isNotEmpty && filter.category != 'all') count++;
    if (filter.gender != null && filter.gender != 'all') count++;
    if (filter.search != null && filter.search!.trim().isNotEmpty) count++;
    if (filter.symptom != null && filter.symptom!.isNotEmpty) count++;
    return count;
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
              backgroundColor: const Color(0xF7FFFFFF), // 97% translucent white
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // iOS Drag Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter Doctors',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            ref.read(doctorFilterProvider.notifier).state = const DoctorFilterState();
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'Reset All',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 1. Consultation Mode
                    const Text(
                      'Consultation Mode',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildModalChip(
                          label: 'All Modes',
                          selected: filter.mode == null || filter.mode == 'all',
                          onTap: () => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(mode: 'all')),
                        ),
                        _buildModalChip(
                          icon: LucideIcons.home,
                          label: 'Home Visit',
                          selected: filter.mode == 'home',
                          onTap: () => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(mode: 'home')),
                        ),
                        _buildModalChip(
                          icon: LucideIcons.video,
                          label: 'Online Video',
                          selected: filter.mode == 'online',
                          onTap: () => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(mode: 'online')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 2. Specialty / Department
                    const Text(
                      'Specialty / Department',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildModalChip(
                          label: 'All Specialties',
                          selected: filter.category == null || filter.category == 'all',
                          onTap: () => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(clearCategory: true)),
                        ),
                        _buildModalChip(
                          label: 'Orthopedic',
                          selected: filter.category?.toLowerCase() == 'orthopedic',
                          onTap: () => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(category: 'orthopedic')),
                        ),
                        _buildModalChip(
                          label: 'Sports Rehab',
                          selected: filter.category?.toLowerCase() == 'sport_injury' || filter.category?.toLowerCase() == 'sports',
                          onTap: () => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(category: 'sports')),
                        ),
                        _buildModalChip(
                          label: 'Neurological',
                          selected: filter.category?.toLowerCase() == 'neurology' || filter.category?.toLowerCase() == 'neurological',
                          onTap: () => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(category: 'neurological')),
                        ),
                        _buildModalChip(
                          label: 'Geriatric',
                          selected: filter.category?.toLowerCase() == 'geriatric',
                          onTap: () => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(category: 'geriatric')),
                        ),
                        _buildModalChip(
                          label: 'Pediatric',
                          selected: filter.category?.toLowerCase() == 'pediatric',
                          onTap: () => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(category: 'pediatric')),
                        ),
                        _buildModalChip(
                          label: 'Cardiac Rehab',
                          selected: filter.category?.toLowerCase() == 'cardiac' || filter.category?.toLowerCase() == 'cardiopulmonary',
                          onTap: () => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(category: 'cardiac')),
                        ),
                        _buildModalChip(
                          label: "Women's Health",
                          selected: filter.category?.toLowerCase() == "women's health" || filter.category?.toLowerCase() == "womens_health",
                          onTap: () => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(category: "womens_health")),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3. Service Area (Nagpur)
                    const Text(
                      'Service Area (Nagpur)',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    locationsAsync.when(
                      data: (master) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: filter.area,
                              hint: const Text('All Areas (Nagpur)', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('All Areas (Nagpur)')),
                                ...master.areas.map((a) => DropdownMenuItem(value: a, child: Text(a))),
                              ],
                              onChanged: (val) {
                                ref.read(doctorFilterProvider.notifier).update(
                                      (s) => s.copyWith(area: val, clearArea: val == null),
                                    );
                              },
                            ),
                          ),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (error, stack) => const SizedBox(),
                    ),
                    const SizedBox(height: 16),

                    // 4. Doctor Gender
                    const Text(
                      'Doctor Gender',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildModalChip(
                          label: 'Any',
                          selected: filter.gender == null || filter.gender == 'all',
                          onTap: () => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(gender: 'all')),
                        ),
                        _buildModalChip(
                          label: 'Female Doctors',
                          selected: filter.gender == 'female',
                          onTap: () => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(gender: 'female')),
                        ),
                        _buildModalChip(
                          label: 'Male Doctors',
                          selected: filter.gender == 'male',
                          onTap: () => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(gender: 'male')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Apply Button
                    FluidPressable(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D9488), Color(0xFF0891B2)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x330891B2),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
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

  Widget _buildModalChip({IconData? icon, required String label, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0891B2) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF0891B2) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? Colors.white : const Color(0xFF64748B)),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0891B2) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF0891B2) : const Color(0xFFF1F5F9),
              width: 1.2,
            ),
            boxShadow: [
              if (!isSelected)
                const BoxShadow(
                  color: Color(0x080F172A),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(doctorsListProvider);
    final filter = ref.watch(doctorFilterProvider);
    final activeFilterCount = _calculateActiveFilterCount(filter);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB), // Exact bgPrimary from DESIGN.md
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, size: 24, color: Color(0xFF0F172A)),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
        ),
        centerTitle: true,
        title: const Text(
          'Doctors',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          // Search Icon Button
          IconButton(
            icon: Icon(
              _isSearchOpen ? LucideIcons.x : LucideIcons.search,
              size: 21,
              color: const Color(0xFF0F172A),
            ),
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (_isSearchOpen) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _searchFocusNode.requestFocus();
                  });
                } else {
                  _searchController.clear();
                  ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(search: ''));
                }
              });
            },
          ),

          // Filter Icon Button with Active Dot
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.slidersHorizontal, size: 19, color: Color(0xFF0F172A)),
                  onPressed: () => _showFilterModal(context),
                ),
                if (activeFilterCount > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0891B2),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Expandable / Collapsible Search Input
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _isSearchOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(height: 0),
            secondChild: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search doctor, specialty, symptom...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF0891B2)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(search: ''));
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF0891B2), width: 1.5),
                  ),
                ),
                onChanged: (val) {
                  ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(search: val.trim()));
                },
              ),
            ),
          ),

          // 2. Horizontal Filter Bar
          Container(
            height: 48,
            color: const Color(0xFFF8FAFB),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Filter Modal Trigger Pill
                _buildQuickFilterChip(
                  icon: LucideIcons.slidersHorizontal,
                  label: activeFilterCount > 0 ? 'Filters ($activeFilterCount)' : 'Filters',
                  isSelected: activeFilterCount > 0,
                  onTap: () => _showFilterModal(context),
                ),

                // All Doctors Pill
                _buildQuickFilterChip(
                  label: 'All',
                  isSelected: (filter.category == null || filter.category == 'all') &&
                      (filter.mode == null || filter.mode == 'all'),
                  onTap: () {
                    ref.read(doctorFilterProvider.notifier).update(
                          (s) => s.copyWith(clearCategory: true, mode: 'all'),
                        );
                  },
                ),

                // Home Visit Pill
                _buildQuickFilterChip(
                  icon: LucideIcons.home,
                  label: 'Home Visit',
                  isSelected: filter.mode == 'home',
                  onTap: () {
                    ref.read(doctorFilterProvider.notifier).update(
                          (s) => s.copyWith(mode: filter.mode == 'home' ? 'all' : 'home'),
                        );
                  },
                ),

                // Video Consult Pill
                _buildQuickFilterChip(
                  icon: LucideIcons.video,
                  label: 'Video Consult',
                  isSelected: filter.mode == 'online',
                  onTap: () {
                    ref.read(doctorFilterProvider.notifier).update(
                          (s) => s.copyWith(mode: filter.mode == 'online' ? 'all' : 'online'),
                        );
                  },
                ),

                // Orthopedic Pill
                _buildQuickFilterChip(
                  label: 'Orthopedic',
                  isSelected: filter.category?.toLowerCase() == 'orthopedic',
                  onTap: () {
                    final isCurrent = filter.category?.toLowerCase() == 'orthopedic';
                    ref.read(doctorFilterProvider.notifier).update(
                          (s) => isCurrent ? s.copyWith(clearCategory: true) : s.copyWith(category: 'orthopedic'),
                        );
                  },
                ),

                // Sports Rehab Pill
                _buildQuickFilterChip(
                  label: 'Sports Rehab',
                  isSelected: filter.category?.toLowerCase() == 'sports' || filter.category?.toLowerCase() == 'sport_injury',
                  onTap: () {
                    final isCurrent = filter.category?.toLowerCase() == 'sports';
                    ref.read(doctorFilterProvider.notifier).update(
                          (s) => isCurrent ? s.copyWith(clearCategory: true) : s.copyWith(category: 'sports'),
                        );
                  },
                ),

                // Neurological Pill
                _buildQuickFilterChip(
                  label: 'Neurological',
                  isSelected: filter.category?.toLowerCase() == 'neurology' || filter.category?.toLowerCase() == 'neurological',
                  onTap: () {
                    final isCurrent = filter.category?.toLowerCase() == 'neurological' || filter.category?.toLowerCase() == 'neurology';
                    ref.read(doctorFilterProvider.notifier).update(
                          (s) => isCurrent ? s.copyWith(clearCategory: true) : s.copyWith(category: 'neurological'),
                        );
                  },
                ),
              ],
            ),
          ),

          // 3. Active Removable Tags (if Area, Search, or custom filter is applied)
          if (filter.area != null || filter.gender != null && filter.gender != 'all' || filter.symptom != null)
            Container(
              height: 34,
              margin: const EdgeInsets.only(top: 4, bottom: 4),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  if (filter.area != null)
                    _RemovableTag(
                      label: 'Area: ${filter.area}',
                      onDeleted: () => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(clearArea: true)),
                    ),
                  if (filter.gender != null && filter.gender != 'all')
                    _RemovableTag(
                      label: filter.gender == 'female' ? 'Female Doctors' : 'Male Doctors',
                      onDeleted: () => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(gender: 'all')),
                    ),
                  if (filter.symptom != null)
                    _RemovableTag(
                      label: filter.symptom!,
                      onDeleted: () => ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(clearSymptom: true)),
                    ),
                ],
              ),
            ),

          // 4. Doctor List with Apple BouncingScrollPhysics
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF0891B2),
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
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(LucideIcons.userX, size: 36, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Doctors Found',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Try adjusting active filters or searching for another condition.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF0891B2)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(doctorFilterProvider.notifier).state = const DoctorFilterState();
                              },
                              child: const Text(
                                'Reset All Filters',
                                style: TextStyle(color: Color(0xFF0891B2), fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.only(top: 8, bottom: 28),
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      return DoctorCard(doctor: doctors[index]);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0891B2)),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 40),
                        const SizedBox(height: 12),
                        const Text(
                          'Could not load doctors',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          e.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0891B2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => ref.refresh(doctorsListProvider),
                          child: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

class _RemovableTag extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;

  const _RemovableTag({required this.label, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDeleted,
            child: const Icon(LucideIcons.x, size: 12, color: Color(0xFF1D4ED8)),
          ),
        ],
      ),
    );
  }
}
