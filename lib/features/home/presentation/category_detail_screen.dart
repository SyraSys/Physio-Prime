import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../doctors/data/doctors_repository.dart';
import '../../doctors/domain/doctor_model.dart';
import '../domain/category_model.dart';
import '../domain/symptom_model.dart';
import '../providers/home_provider.dart';

class CategoryDetailScreen extends ConsumerStatefulWidget {
  final String slug;
  final CategoryModel? category;

  const CategoryDetailScreen({
    super.key,
    required this.slug,
    this.category,
  });

  @override
  ConsumerState<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  late Future<List<DoctorModel>> _doctorsFuture;
  List<DoctorModel>? _loadedDoctors;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  void _loadDoctors() {
    final repo = ref.read(doctorsRepositoryProvider);
    _doctorsFuture = repo.getDoctors(category: widget.slug).then((list) async {
      List<DoctorModel> result = list;
      if (result.isEmpty) {
        // If endpoint returned empty, query all live doctors and apply website matching algorithm
        final allDocs = await repo.getDoctors();
        final catTitle = widget.category?.title ?? widget.slug;
        result = allDocs.where((d) => _matchesCategory(d, widget.slug, catTitle)).toList();
      }
      if (mounted) {
        setState(() {
          _loadedDoctors = result;
        });
      }
      return result;
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _loadedDoctors = [];
        });
      }
      return <DoctorModel>[];
    });
  }

  String _getVerifiedDoctorsBadgeText(CategoryModel? cat) {
    if (_loadedDoctors != null) {
      final count = _loadedDoctors!.length;
      if (count > 0) {
        return '$count Verified ${count == 1 ? 'Doctor' : 'Doctors'}';
      }
      return 'Verified Specialists';
    }
    final fallbackCount = cat?.doctorCount ?? 0;
    if (fallbackCount > 0) {
      return '$fallbackCount Verified ${fallbackCount == 1 ? 'Doctor' : 'Doctors'}';
    }
    return 'Verified Specialists';
  }

  String _getRatingText() {
    if (_loadedDoctors != null && _loadedDoctors!.isNotEmpty) {
      double totalRating = 0.0;
      int ratedCount = 0;
      for (final doc in _loadedDoctors!) {
        if (doc.rating > 0) {
          totalRating += doc.rating;
          ratedCount++;
        }
      }
      if (ratedCount > 0) {
        return '${(totalRating / ratedCount).toStringAsFixed(1)} Rating';
      }
    }
    return '4.9 Rating';
  }

  String _getStartingFeeText() {
    if (_loadedDoctors != null && _loadedDoctors!.isNotEmpty) {
      int lowest = 999999;
      for (final doc in _loadedDoctors!) {
        DoctorCategoryOption? matchedOpt;
        for (final opt in doc.categoryOptions) {
          if (opt.slug.toLowerCase() == widget.slug.toLowerCase() ||
              opt.categoryId.toLowerCase() == widget.slug.toLowerCase() ||
              opt.title.toLowerCase().contains(widget.slug.toLowerCase())) {
            matchedOpt = opt;
            break;
          }
        }
        final num rawFee = matchedOpt != null && matchedOpt.feeHome > 0
            ? matchedOpt.feeHome
            : (doc.startingFee > 0
                ? doc.startingFee
                : (doc.fees.home > 0 ? doc.fees.home : doc.fees.online));
        final int fee = rawFee.toInt();
        if (fee > 0 && fee < lowest) {
          lowest = fee;
        }
      }
      if (lowest < 999999) {
        return 'From ₹$lowest';
      }
    }
    return 'From ₹800';
  }

  static bool _matchesCategory(DoctorModel doc, String catSlug, String catTitle) {
    final slug = catSlug.toLowerCase();
    final title = catTitle.toLowerCase();

    if (doc.categoryOptions.any((opt) =>
        opt.slug.toLowerCase() == slug ||
        opt.categoryId.toLowerCase() == slug ||
        opt.title.toLowerCase().contains(slug) ||
        opt.title.toLowerCase().contains(title))) {
      return true;
    }

    final text = [
      doc.specialty,
      doc.title,
      ...doc.expertise,
      ...doc.treatments,
      ...doc.categories,
      doc.bio,
    ].join(' ').toLowerCase();

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

  @override
  Widget build(BuildContext context) {
    final selectedCity = ref.watch(selectedCityProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final cat = widget.category ??
        categoriesAsync.value?.where((c) => c.slug == widget.slug).firstOrNull;

    if (cat == null && categoriesAsync.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFB),
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final categoryTitle = cat?.title ?? 'Specialty Detail';
    final categoryDesc = cat?.description ?? 'Certified clinical physiotherapy care and rehabilitation.';
    final conditions = cat?.conditions ?? const <String>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, size: 24, color: Color(0xFF0F172A)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/bookings');
            }
          },
        ),
        centerTitle: true,
        title: Text(
          categoryTitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Breadcrumbs
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/bookings');
                      }
                    },
                    child: Text(
                      'Categories',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0891B2)),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(LucideIcons.chevronRight, size: 13, color: Color(0xFF94A3B8)),
                  ),
                  Expanded(
                    child: Text(
                      categoryTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Hero Category Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x080F172A),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Stack(
                      children: [
                        if (cat != null && cat.image != null && cat.image!.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: cat.image!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 160,
                              color: const Color(0xFFEBF8FA),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 160,
                              color: const Color(0xFFEBF8FA),
                              child: const Icon(LucideIcons.activity, size: 40, color: Color(0xFF0891B2)),
                            ),
                          )
                        else
                          Container(
                            height: 100,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFE0F2FE), Color(0xFFECFDF5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(LucideIcons.activity, size: 36, color: Color(0xFF0891B2)),
                            ),
                          ),
                        Positioned(
                          top: 14,
                          right: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.badgeCheck, size: 14, color: Color(0xFF0891B2)),
                                const SizedBox(width: 5),
                                Text(
                                  _getVerifiedDoctorsBadgeText(cat),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryTitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          categoryDesc,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: const Color(0xFF475569),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stats cluster (Responsive Wrap prevents 21px RenderFlex overflow on narrow screens)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildStatBadge(
                              icon: LucideIcons.star,
                              iconColor: const Color(0xFFF59E0B),
                              label: _getRatingText(),
                            ),
                            _buildStatBadge(
                              icon: LucideIcons.home,
                              iconColor: const Color(0xFF0891B2),
                              label: 'Home & Online',
                            ),
                            _buildStatBadge(
                              icon: LucideIcons.tag,
                              iconColor: const Color(0xFF10B981),
                              label: _getStartingFeeText(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. Common Conditions Treated Section
            if (conditions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Common Conditions Treated',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Select a condition to book specialized physiotherapy care',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: conditions.map((cond) {
                    return InkWell(
                      onTap: () {
                        context.push(
                          '/booking-flow',
                          extra: {
                            'initialStep': 2,
                            'condition': SymptomModel(
                              id: cond.toLowerCase().replaceAll(' ', '-'),
                              slug: cond.toLowerCase().replaceAll(' ', '-'),
                              title: cond,
                              description: 'Specialized clinical care for $cond',
                              department: categoryTitle,
                            ),
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x040F172A),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.checkCircle2, size: 13, color: Color(0xFF0891B2)),
                            const SizedBox(width: 6),
                            Text(
                              cond,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 4. Verified Specialists Section (Matches Website https://www.physio-prime.in/categories/sports-injury)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verified Specialists in $selectedCity',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _loadedDoctors != null && _loadedDoctors!.isNotEmpty
                        ? '${_loadedDoctors!.length} licensed clinical ${_loadedDoctors!.length == 1 ? 'physiotherapist' : 'physiotherapists'} available for home visits & online consultations'
                        : 'Licensed clinical physiotherapists available for home visits & online consultations',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),

            FutureBuilder<List<DoctorModel>>(
              future: _doctorsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }

                final doctors = snapshot.data ?? [];

                if (doctors.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Column(
                      children: [
                        const Icon(LucideIcons.userX, size: 40, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        Text(
                          'No Specialists Currently Available',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Our physiotherapists will be available in this category soon.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: doctors.map((doc) => _buildCategoryDoctorCard(doc, categoryTitle)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDoctorCard(DoctorModel doc, String categoryTitle) {
    DoctorCategoryOption? matchedOpt;
    for (final opt in doc.categoryOptions) {
      if (opt.slug.toLowerCase() == widget.slug.toLowerCase() ||
          opt.categoryId.toLowerCase() == widget.slug.toLowerCase() ||
          opt.title.toLowerCase().contains(widget.slug.toLowerCase()) ||
          opt.title.toLowerCase().contains(categoryTitle.toLowerCase())) {
        matchedOpt = opt;
        break;
      }
    }
    final fee = matchedOpt != null ? matchedOpt.feeHome : (doc.fees.home > 0 ? doc.fees.home : (doc.fees.online > 0 ? doc.fees.online : 800));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      padding: const EdgeInsets.all(15),
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
                  width: 66,
                  height: 66,
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
              const SizedBox(width: 14),
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
                                const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF0891B2)),
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
              Flexible(
                child: Text(
                  '₹${fee.toInt()}/session',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0891B2),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
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
                      onPressed: () {
                        context.push(
                          '/booking-flow',
                          extra: {
                            'initialStep': 3,
                            'doctor': doc,
                            'mode': 'home',
                            if (matchedOpt != null) ...{
                              'categoryId': matchedOpt.categoryId,
                              'categoryTitle': matchedOpt.title,
                              'fee': matchedOpt.feeHome,
                            },
                          },
                        );
                      },
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
