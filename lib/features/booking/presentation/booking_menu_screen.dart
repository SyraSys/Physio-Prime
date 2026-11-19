import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fluid_pressable.dart';
import '../../doctors/data/doctors_repository.dart';
import '../../doctors/domain/doctor_model.dart';
import '../../home/domain/category_model.dart';
import '../../home/domain/symptom_model.dart';
import '../../home/providers/home_provider.dart';
import '../domain/booking_request_model.dart';
import 'widgets/symptom_card.dart';

/// The Booking Menu Screen mounted at `/bookings`.
///
/// Designed in strict compliance with `DESIGN.md`:
/// - Minimalist clinical aesthetics, high-clarity Plus Jakarta Sans & Inter typography.
/// - Calming white and soft mint surfaces (`#F8FAFB`, `#FFFFFF`, `#EBF8FA`).
/// - 3 tabs: "By Symptoms", "Categories", "All Doctors".
/// - Fast-action top header link to "My Appointments".
/// - Responsive mobile-first container clamped to 580px max width.
/// - Fluid 60/120 FPS sliding between tabs via `AutomaticKeepAliveClientMixin`
///   and hardware-accelerated `RepaintBoundary` layers.
class BookingMenuScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const BookingMenuScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<BookingMenuScreen> createState() => _BookingMenuScreenState();
}

class _BookingMenuScreenState extends ConsumerState<BookingMenuScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ValueNotifier<String> _categoryFilterNotifier = ValueNotifier<String>('All');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
      animationDuration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _categoryFilterNotifier.dispose();
    super.dispose();
  }

  void _openBookingFlow({
    SymptomModel? condition,
    DoctorModel? doctor,
    ConsultationMode mode = ConsultationMode.home,
  }) {
    context.push(
      '/booking-flow',
      extra: {
        'initialStep': condition != null ? 2 : (doctor != null ? 3 : 1),
        'condition': condition,
        'doctor': doctor,
        'mode': mode.apiValue,
      },
    );
  }

  void _onCategorySelected(String category) {
    _categoryFilterNotifier.value = category;
    _tabController.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCity = ref.watch(selectedCityProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Column(
              children: [
                // ===============================================================
                // 1. PINNED TOP HEADER (Logo, Brand Name, Location, My Bookings)
                // ===============================================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Brand Logo + Location Cluster (Matches DESIGN.md 3.1)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/pp_monogram.png',
                            height: 32,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F7FA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(LucideIcons.activity, size: 18, color: Color(0xFF0891B2)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  text: 'Physio',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.3,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Prime',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF0891B2),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 1),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.mapPin,
                                    size: 11,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    selectedCity,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    LucideIcons.chevronDown,
                                    size: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),

                      // My Bookings Button (Clean elevated pill)
                      FluidPressable(
                        onTap: () => context.push('/appointments'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x080F172A),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.calendar, size: 14, color: Color(0xFF0891B2)),
                              const SizedBox(width: 5),
                              Text(
                                'My Bookings',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0891B2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ===============================================================
                // 2. PINNED MINIMALIST SEGMENTED TAB BAR
                // ===============================================================
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: const Color(0xFF0891B2),
                      borderRadius: BorderRadius.circular(21),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x240891B2),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                    tabs: const [
                      Tab(text: 'By Symptoms'),
                      Tab(text: 'Categories'),
                      Tab(text: 'All Doctors'),
                    ],
                  ),
                ),

                // ===============================================================
                // 3. BUTTERY SMOOTH HORIZONTAL TAB BAR VIEW
                // ===============================================================
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
                    children: [
                      RepaintBoundary(
                        child: _SymptomsTabView(
                          filterNotifier: _categoryFilterNotifier,
                          onOpenBooking: _openBookingFlow,
                        ),
                      ),
                      RepaintBoundary(
                        child: _CategoriesTabView(
                          onSelectCategory: _onCategorySelected,
                          onOpenBooking: _openBookingFlow,
                        ),
                      ),
                      RepaintBoundary(
                        child: _DoctorsTabView(
                          onOpenBooking: _openBookingFlow,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TAB 1: BY SYMPTOMS (STATEFUL + AUTOMATIC KEEPALIVE)
// =============================================================================
class _SymptomsTabView extends ConsumerStatefulWidget {
  final ValueNotifier<String> filterNotifier;
  final void Function({
    SymptomModel? condition,
    DoctorModel? doctor,
    ConsultationMode mode,
  }) onOpenBooking;

  const _SymptomsTabView({
    required this.filterNotifier,
    required this.onOpenBooking,
  });

  @override
  ConsumerState<_SymptomsTabView> createState() => _SymptomsTabViewState();
}

class _SymptomsTabViewState extends ConsumerState<_SymptomsTabView>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _symptomSearchController = TextEditingController();
  late String _selectedCategoryChip;

  static const _categoryTabs = [
    'All',
    'Musculoskeletal / Orthopedic',
    'Sports Injuries',
    'Neurological Conditions',
    'Pediatric Conditions',
    'Cardio-Respiratory',
    'Women\'s Health',
    'Geriatric Care',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedCategoryChip = widget.filterNotifier.value;
    widget.filterNotifier.addListener(_onExternalFilterChanged);
  }

  void _onExternalFilterChanged() {
    if (mounted && _selectedCategoryChip != widget.filterNotifier.value) {
      setState(() {
        _selectedCategoryChip = widget.filterNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    widget.filterNotifier.removeListener(_onExternalFilterChanged);
    _symptomSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final symptomsAsync = ref.watch(symptomsProvider);

    return symptomsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertTriangle, size: 32, color: AppColors.error),
            const SizedBox(height: 8),
            Text('Could not load conditions catalogue', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
            TextButton(
              onPressed: () => ref.invalidate(symptomsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (conditions) {
        final query = _symptomSearchController.text.trim().toLowerCase();
        final filtered = conditions.where((item) {
          final matchesQuery = query.isEmpty ||
              item.title.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query) ||
              item.symptomsList.any((s) => s.toLowerCase().contains(query));

          if (!matchesQuery) return false;

          if (_selectedCategoryChip == 'All') return true;
          return item.department?.toLowerCase().contains(_selectedCategoryChip.toLowerCase()) ?? false;
        }).toList();

        return CustomScrollView(
          key: const PageStorageKey('symptoms_scroll'),
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                        children: [
                          const TextSpan(text: 'What brings you in? '),
                          TextSpan(
                            text: 'Choose condition',
                            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF0891B2)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Select from the 8 primary conditions we treat',
                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),

                    // Stadium Pill Search Bar (DESIGN.md 3.2)
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x080F172A),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.search, size: 18, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _symptomSearchController,
                              onChanged: (_) => setState(() {}),
                              style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF0F172A)),
                              decoration: InputDecoration(
                                hintText: 'Search conditions or symptoms...',
                                hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_symptomSearchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _symptomSearchController.clear();
                                setState(() {});
                              },
                              child: const Icon(LucideIcons.x, size: 16, color: Color(0xFF94A3B8)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Horizontal Category Filter Chips (Clamping physics prevents gesture blocking)
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        itemCount: _categoryTabs.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final tab = _categoryTabs[idx];
                          final isSelected = tab == _selectedCategoryChip;

                          return ChoiceChip(
                            label: Text(tab),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) {
                                setState(() => _selectedCategoryChip = tab);
                                widget.filterNotifier.value = tab;
                              }
                            },
                            selectedColor: const Color(0xFF0891B2),
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSelected ? Colors.transparent : const Color(0xFFF1F5F9),
                              width: 1.2,
                            ),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                            showCheckmark: false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No matching conditions found.\nTry a different search term.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filtered[index];
                      return SymptomCard(
                        item: item,
                        onTap: () => widget.onOpenBooking(condition: item),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// TAB 2: CATEGORIES (CIRCULAR 3-COL GRID MATCHING REFERENCE + LIVE SPECIALISTS)
// =============================================================================
class _CategoriesTabView extends ConsumerStatefulWidget {
  final ValueChanged<String> onSelectCategory;
  final void Function({
    SymptomModel? condition,
    DoctorModel? doctor,
    ConsultationMode mode,
  }) onOpenBooking;

  const _CategoriesTabView({
    required this.onSelectCategory,
    required this.onOpenBooking,
  });

  @override
  ConsumerState<_CategoriesTabView> createState() => _CategoriesTabViewState();
}

class _CategoriesTabViewState extends ConsumerState<_CategoriesTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  CategoryModel? _selectedCategory;
  Future<List<DoctorModel>>? _categoryDoctorsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cats = ref.read(categoriesProvider).value ?? [];
      if (cats.isNotEmpty && _selectedCategory == null) {
        _onCategoryTapped(cats.first);
      }
    });
  }

  void _onCategoryTapped(CategoryModel cat) {
    setState(() {
      _selectedCategory = cat;
      final repo = ref.read(doctorsRepositoryProvider);
      _categoryDoctorsFuture = repo.getDoctors(category: cat.slug).then((list) async {
        if (list.isNotEmpty) return list;
        final allDocs = await repo.getDoctors();
        return allDocs.where((d) => _matchesCategory(d, cat)).toList();
      });
    });
  }

  static bool _matchesCategory(DoctorModel doc, CategoryModel cat) {
    final text = [
      doc.specialty,
      doc.title,
      ...doc.expertise,
      ...doc.treatments,
      ...doc.categories,
      doc.bio,
    ].join(' ').toLowerCase();

    final slug = cat.slug.toLowerCase();
    final title = cat.title.toLowerCase();

    if (text.contains(slug) || text.contains(title)) return true;

    final words = title.split(' ').where((w) => w.length > 3 && w != 'doctor');
    for (final w in words) {
      if (text.contains(w)) return true;
    }

    if (doc.categories.any((c) => c.toLowerCase() == slug || c.toLowerCase() == title)) {
      return true;
    }

    return false;
  }

  static String _getCategoryIconAsset(CategoryModel cat) {
    final title = cat.title.toLowerCase();
    final slug = cat.slug.toLowerCase();

    if (title.contains('sport') || slug.contains('sport')) return 'assets/images/cat_sport_injury.png';
    if (title.contains('neuro') || slug.contains('neuro')) return 'assets/images/cat_neurological.png';
    if (title.contains('pediatric') || title.contains('child') || slug.contains('pediatric')) {
      return 'assets/images/cat_pediatric.png';
    }
    if (title.contains('cardio') || title.contains('cardiac') || slug.contains('cardio') || slug.contains('cardiac')) {
      return 'assets/images/cat_cardiac.png';
    }
    if (title.contains('geriatric') || title.contains('elderly') || slug.contains('geriatric')) {
      return 'assets/images/cat_geriatric.png';
    }
    if (title.contains('women') || title.contains('female') || slug.contains('women') || slug.contains('gynec')) {
      return 'assets/images/cat_womens_health.png';
    }
    return 'assets/images/cat_orthopedic.png';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Could not load categories: $e', style: GoogleFonts.inter())),
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();

        final activeCat = _selectedCategory ?? categories.first;
        if (_categoryDoctorsFuture == null) {
          final repo = ref.read(doctorsRepositoryProvider);
          _categoryDoctorsFuture = repo.getDoctors(category: activeCat.slug).then((list) async {
            if (list.isNotEmpty) return list;
            final allDocs = await repo.getDoctors();
            return allDocs.where((d) => _matchesCategory(d, activeCat)).toList();
          });
        }

        return ListView(
          key: const PageStorageKey('categories_scroll'),
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
          children: [
            // Top Section Title (DESIGN.md 3.5)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Therapy Categories',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Select a category to view specialized doctors & treatments',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),

            // 3-Column Circular Icons Grid (Matches Reference Image)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat.slug == activeCat.slug;
                return _buildCircularCategoryTile(
                  cat: cat,
                  isSelected: isSelected,
                  onTap: () => _onCategoryTapped(cat),
                );
              },
            ),

            const SizedBox(height: 10),

            // Specialists in [Category] Section Header
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${activeCat.title.replaceAll(" Doctor", "")} Doctors',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Verified specialists for ${activeCat.title}',
                          style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/categories/${activeCat.slug}', extra: activeCat),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF8FA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDEF4F7)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Category Page',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0891B2),
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(LucideIcons.chevronRight, size: 13, color: Color(0xFF0891B2)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Doctors list for selected category
            FutureBuilder<List<DoctorModel>>(
              future: _categoryDoctorsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  );
                }

                final doctors = snapshot.data ?? [];
                if (doctors.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Column(
                      children: [
                        const Icon(LucideIcons.userX, size: 36, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 10),
                        Text(
                          'No Specialists Currently Available',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'We are currently onboarding verified physiotherapists for ${activeCat.title} in Nagpur.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: doctors.map((doc) => _buildCategoryDoctorCard(doc)).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCircularCategoryTile({
    required CategoryModel cat,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final assetPath = _getCategoryIconAsset(cat);
    final title = cat.title.replaceAll(' Doctor', '').replaceAll(' Care', '');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEBF8FA) : const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF0891B2) : const Color(0xFFE2E8F0),
                width: isSelected ? 2.2 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? const Color(0x220891B2) : const Color(0x060F172A),
                  blurRadius: isSelected ? 12 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: Center(
                child: Image.asset(
                  assetPath,
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? const Color(0xFF0891B2) : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDoctorCard(DoctorModel doc) {
    final fee = doc.fees.home > 0 ? doc.fees.home : (doc.fees.online > 0 ? doc.fees.online : 800);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: doc.photo != null && doc.photo!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: doc.photo!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFEBF8FA),
                            child: const Icon(LucideIcons.user, color: Color(0xFF0891B2)),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFEBF8FA),
                          child: const Icon(LucideIcons.user, color: Color(0xFF0891B2)),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  doc.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (doc.verified) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF0891B2)),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFEF3C7)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 2.5),
                              Text(
                                doc.ratingDisplay,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doc.specialty.isNotEmpty ? doc.specialty : doc.title,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${doc.experienceYears} yrs exp • ${doc.location.displayString}',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${fee.toInt()}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0891B2),
                ),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => context.push('/doctor/${doc.slug}', extra: doc),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      'Profile',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF009AA6), Color(0xFF26B4BD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33009AA6),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => widget.onOpenBooking(doctor: doc, mode: ConsultationMode.home),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      ),
                      child: Text(
                        'Book Now',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 3: ALL DOCTORS (STATEFUL + AUTOMATIC KEEPALIVE + CACHED FUTURE)
// =============================================================================
class _DoctorsTabView extends ConsumerStatefulWidget {
  final void Function({
    SymptomModel? condition,
    DoctorModel? doctor,
    ConsultationMode mode,
  }) onOpenBooking;

  const _DoctorsTabView({
    required this.onOpenBooking,
  });

  @override
  ConsumerState<_DoctorsTabView> createState() => _DoctorsTabViewState();
}

class _DoctorsTabViewState extends ConsumerState<_DoctorsTabView>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _doctorSearchController = TextEditingController();
  String _selectedDoctorMode = 'all';
  Future<List<DoctorModel>>? _doctorsFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  void _fetchDoctors() {
    final repo = ref.read(doctorsRepositoryProvider);
    setState(() {
      _doctorsFuture = repo.getDoctors(
        search: _doctorSearchController.text.trim().isNotEmpty ? _doctorSearchController.text.trim() : null,
        mode: _selectedDoctorMode != 'all' ? _selectedDoctorMode : null,
      );
    });
  }

  @override
  void dispose() {
    _doctorSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder<List<DoctorModel>>(
      future: _doctorsFuture,
      builder: (context, snapshot) {
        final doctors = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return CustomScrollView(
          key: const PageStorageKey('doctors_scroll'),
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Best Doctors',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Book verified physiotherapists for home visits or online consultations',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),

                    // Stadium Pill Search Bar
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x080F172A),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.search, size: 18, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _doctorSearchController,
                              onSubmitted: (_) => _fetchDoctors(),
                              style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF0F172A)),
                              decoration: InputDecoration(
                                hintText: 'Search by doctor name or specialty...',
                                hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_doctorSearchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _doctorSearchController.clear();
                                _fetchDoctors();
                              },
                              child: const Icon(LucideIcons.x, size: 16, color: Color(0xFF94A3B8)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Mode Filter Chips
                    Row(
                      children: [
                        _buildDoctorFilterChip('All Modes', 'all'),
                        const SizedBox(width: 8),
                        _buildDoctorFilterChip('Home Visit', 'home'),
                        const SizedBox(width: 8),
                        _buildDoctorFilterChip('Online Video', 'online'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (doctors.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No therapists found for this filter.',
                      style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = doctors[index];
                      return _buildDoctorListItem(doc);
                    },
                    childCount: doctors.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDoctorFilterChip(String label, String value) {
    final isSelected = _selectedDoctorMode == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val && _selectedDoctorMode != value) {
          _selectedDoctorMode = value;
          _fetchDoctors();
        }
      },
      selectedColor: const Color(0xFF0891B2),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? Colors.transparent : const Color(0xFFF1F5F9),
        width: 1.2,
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildDoctorListItem(DoctorModel doc) {
    final mode = _selectedDoctorMode == 'online' ? ConsultationMode.online : ConsultationMode.home;
    final fee = mode == ConsultationMode.home ? doc.fees.home : doc.fees.online;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: doc.photo != null && doc.photo!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: doc.photo!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFE0F4F7),
                            child: const Icon(LucideIcons.user, color: Color(0xFF0891B2)),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFE0F4F7),
                          child: const Icon(LucideIcons.user, color: Color(0xFF0891B2)),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            doc.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        // Amber star rating pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFEF3C7)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 2.5),
                              Text(
                                doc.rating > 0 ? doc.rating.toStringAsFixed(1) : 'New',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doc.specialty.isNotEmpty ? doc.specialty : doc.title,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${doc.experienceYears} yrs exp • ${doc.languages.isNotEmpty ? doc.languages.join(", ") : "Hindi, English"}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${fee.toInt()}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0891B2),
                ),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => context.push('/doctor/${doc.slug}', extra: doc),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      'Profile',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF009AA6), Color(0xFF26B4BD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33009AA6),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => widget.onOpenBooking(doctor: doc, mode: mode),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      ),
                      child: Text(
                        'Book Now',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
