import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ist_time.dart';
import '../../../core/widgets/fluid_pressable.dart';
import '../../../core/widgets/skeleton_loading.dart';
import '../../booking/domain/slot_model.dart';
import '../../booking/providers/booking_provider.dart';
import '../domain/doctor_model.dart';
import '../domain/review_model.dart';
import '../providers/doctors_provider.dart';

/// Doctor Profile & Detail Screen matching the modern clinical design specification.
/// Features:
/// 1. Soft Cyan Hero Header with doctor cutout and 3 vertical teal stat badges (Patients, Experience, Ratings).
/// 2. Header with Doctor Name, Rating Star, Specialty & Distance.
/// 3. 4 Rounded Quick Action Cards: Call, Message, Direction, Share.
/// 4. 3 Navigation Tabs with smooth underline indicator: About Doctor, Book Appointment, Reviews.
/// 5. Horizontal 14-day Schedule Date picker, time slot chips, and solid teal "Book Appointment" CTA button.
class DoctorDetailScreen extends ConsumerStatefulWidget {
  final String slug;
  final DoctorModel? doctor;

  const DoctorDetailScreen({
    super.key,
    required this.slug,
    this.doctor,
  });

  @override
  ConsumerState<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends ConsumerState<DoctorDetailScreen> {
  int _selectedTabIndex = 1; // Default to 'Book Appointment' matching reference screenshot
  int _selectedDateIndex = 1; // Default to second date (e.g. 23 Sun) matching screenshot
  String _selectedMode = 'home';
  DoctorCategoryOption? _selectedCategoryOption;
  SlotModel? _selectedSlotModel;

  static const List<SlotModel> _fallbackWindows = [
    SlotModel(
      slot: '7:00 AM - 9:00 AM',
      label: 'Early Morning',
      available: true,
      maxPatients: 3,
    ),
    SlotModel(
      slot: '9:00 AM - 12:00 PM',
      label: 'Morning',
      available: true,
      maxPatients: 3,
    ),
    SlotModel(
      slot: '3:00 PM - 6:00 PM',
      label: 'Evening',
      available: true,
      maxPatients: 3,
    ),
    SlotModel(
      slot: '6:00 PM - 9:00 PM',
      label: 'Night',
      available: true,
      maxPatients: 3,
    ),
  ];

  IconData _getTimeWindowIcon(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('early')) return LucideIcons.sunrise;
    if (lower.contains('morning')) return LucideIcons.sun;
    if (lower.contains('afternoon')) return LucideIcons.sunMedium;
    if (lower.contains('evening')) return LucideIcons.sunset;
    return LucideIcons.moon;
  }

  late final List<DateTime> _upcomingDates;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _upcomingDates = List.generate(14, (i) => today.add(Duration(days: i)));
  }

  Future<void> _handleCall(DoctorModel doc) async {
    final phone = 'tel:+919876543210';
    try {
      final uri = Uri.parse(phone);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (mounted) {
        _showSnack('Contact number: +91 98765 43210');
      }
    } catch (_) {
      if (mounted) _showSnack('Contact number: +91 98765 43210');
    }
  }

  Future<void> _handleMessage(DoctorModel doc) async {
    final url = 'https://wa.me/919876543210?text=${Uri.encodeComponent('Hi ${doc.name}, I want to consult for physiotherapy.')}';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        _showSnack('Opening chat with ${doc.name}');
      }
    } catch (_) {
      if (mounted) _showSnack('Opening chat with ${doc.name}');
    }
  }

  Future<void> _handleDirection(DoctorModel doc) async {
    final query = doc.location.displayString;
    final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('PhysioPrime $query')}';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        _showSnack('Clinic location: $query');
      }
    } catch (_) {
      if (mounted) _showSnack('Clinic location: $query');
    }
  }

  void _handleShare(DoctorModel doc) {
    Clipboard.setData(ClipboardData(text: 'Consult with ${doc.name} (${doc.specialty}) on PhysioPrime: https://www.physio-prime.in/doctors/${doc.slug}'));
    _showSnack('Doctor profile link copied to clipboard!');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _selectCustomDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _upcomingDates[_selectedDateIndex],
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final existingIndex = _upcomingDates.indexWhere(
        (d) => d.year == picked.year && d.month == picked.month && d.day == picked.day,
      );
      if (existingIndex != -1) {
        setState(() => _selectedDateIndex = existingIndex);
      } else {
        setState(() {
          _upcomingDates.insert(0, picked);
          _selectedDateIndex = 0;
        });
      }
    }
  }

  void _proceedToBooking(DoctorModel doc) {
    final selectedDate = _upcomingDates[_selectedDateIndex];
    final selectedSlot = _selectedSlotModel ?? _fallbackWindows.first;
    final activeHomeFee = _selectedCategoryOption != null ? _selectedCategoryOption!.feeHome : doc.fees.home;
    final activeOnlineFee = _selectedCategoryOption != null ? _selectedCategoryOption!.feeOnline : doc.fees.online;
    final activeFee = _selectedMode == 'home' ? activeHomeFee : activeOnlineFee;

    context.push(
      '/booking-slots',
      extra: {
        'doctorId': doc.id,
        'doctorSlug': doc.slug,
        'doctorName': doc.name,
        'doctorTitle': doc.title,
        'doctorPhoto': doc.photo,
        'categoryId': _selectedCategoryOption?.categoryId ?? (doc.categoryOptions.isNotEmpty ? doc.categoryOptions.first.categoryId : null),
        'categoryTitle': _selectedCategoryOption?.title ?? (doc.categoryOptions.isNotEmpty ? doc.categoryOptions.first.title : null),
        'mode': _selectedMode,
        'fee': activeFee,
        'feePaise': (activeFee * 100).toInt(),
        'homeVisitsEnabled': doc.homeVisitsEnabled,
        'selectedDate': selectedDate.toIso8601String(),
        'selectedTime': selectedSlot.displayTitle,
        'selectedWindow': selectedSlot.displayTitle,
        'slot': selectedSlot.slot,
        'slotDisplayTime': selectedSlot.timeRange,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(doctorDetailProvider(widget.slug));
    final reviewsAsync = ref.watch(doctorReviewsProvider(widget.slug));
    final doc = widget.doctor ?? detailAsync.valueOrNull;

    if (doc != null && doc.categoryOptions.isNotEmpty) {
      if (_selectedCategoryOption == null ||
          !doc.categoryOptions.any((c) => c.categoryId == _selectedCategoryOption!.categoryId)) {
        _selectedCategoryOption = doc.categoryOptions.first;
      }
    }

    if (doc == null && detailAsync.isLoading) {
      return const DoctorDetailSkeletonScreen();
    }

    if (doc == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/appointments');
              }
            },
          ),
          title: const Text(
            'Doctor Profile',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.userX,
                    size: 28,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Doctor Profile Unavailable',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This doctor profile is no longer available or was associated with an archived appointment.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0891B2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/appointments');
                    }
                  },
                  icon: const Icon(LucideIcons.arrowLeft, size: 16),
                  label: const Text('Back to Appointments'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // 1. Hero Header Area (Soft Cyan Background + Doctor Cutout + 3 Stat Badges)
                _buildHeroHeader(context, doc),

                // 2. Main Profile Content Sheet (White surface with rounded top)
                _buildProfileContent(context, doc, reviewsAsync),
              ],
            ),
          ),

          // Custom Top App Bar (Back Arrow & More Menu)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF0F172A), size: 24),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/doctors');
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.moreVertical, color: Color(0xFF0F172A), size: 22),
                    onPressed: () => _handleShare(doc),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. HERO HEADER (Matches screenshot top section)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildHeroHeader(BuildContext context, DoctorModel doc) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      height: 330 + topPadding,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE8F8FA),
            Color(0xFFDFF5F8),
            Color(0xFFD5F0F5),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Doctor Cutout Photo (Left/Center)
          Positioned(
            left: 0,
            bottom: 0,
            top: topPadding + 20,
            width: MediaQuery.of(context).size.width * 0.58,
            child: _buildDoctorPhoto(doc.photo),
          ),

          // 3 Vertical Teal Stat Badges (Right side)
          Positioned(
            right: 16,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge 1: Patients
                _buildTealStatBadge(
                  icon: LucideIcons.users,
                  title: '${doc.patientsTreated > 0 ? doc.patientsTreated : 800}+',
                  subtitle: 'Patients',
                ),
                const SizedBox(height: 10),

                // Badge 2: Experience
                _buildTealStatBadge(
                  icon: LucideIcons.award,
                  title: '${doc.experienceYears > 0 ? doc.experienceYears : 5} Years',
                  subtitle: 'Experience',
                ),
                const SizedBox(height: 10),

                // Badge 3: Ratings
                _buildTealStatBadge(
                  icon: LucideIcons.star,
                  title: doc.ratingDisplay,
                  subtitle: 'Ratings',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorPhoto(String? photo) {
    if (photo != null && photo.isNotEmpty) {
      if (photo.startsWith('assets/')) {
        return Image.asset(
          photo,
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
          errorBuilder: (context, error, stackTrace) => _fallbackDoctorImage(),
        );
      }
      return CachedNetworkImage(
        imageUrl: photo,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        placeholder: (context, url) => const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        ),
        errorWidget: (context, url, error) => _fallbackDoctorImage(),
      );
    }
    return _fallbackDoctorImage();
  }

  Widget _fallbackDoctorImage() {
    return Image.asset(
      'assets/images/hero_doctor.png',
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
    );
  }

  Widget _buildTealStatBadge({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0891B2), // Solid brand teal from DESIGN.md
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260891B2),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular White Icon Badge
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF0891B2)),
          ),
          const SizedBox(width: 8),

          // Label Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. MAIN PROFILE CONTENT SHEET (White rounded container)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildProfileContent(
    BuildContext context,
    DoctorModel doc,
    AsyncValue<List<ReviewModel>> reviewsAsync,
  ) {
    return Transform.translate(
      offset: const Offset(0, -16),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 20,
              offset: Offset(0, -6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Doctor Name + Star Rating Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    doc.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF9C3), // Soft light amber
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.star, size: 15, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        doc.ratingDisplay,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Row 2: Specialty & Distance Indicator
            Row(
              children: [
                Flexible(
                  child: Text(
                    doc.specialty,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.mapPin, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 3),
                    Text(
                      doc.distance ?? '1.5 km away',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Row 3: 4 Quick Action Buttons (Call, Message, Direction, Share)
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: LucideIcons.phone,
                    label: 'Call',
                    onTap: () => _handleCall(doc),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: LucideIcons.messageSquare,
                    label: 'Message',
                    onTap: () => _handleMessage(doc),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: LucideIcons.map,
                    label: 'Direction',
                    onTap: () => _handleDirection(doc),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: LucideIcons.share2,
                    label: 'Share',
                    onTap: () => _handleShare(doc),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Row 4: 3 Navigation Tabs (About Doctor, Book Appointment, Reviews)
            _buildTabBar(),
            const SizedBox(height: 20),

            // Row 5: Tab Body
            if (_selectedTabIndex == 1)
              _buildTabBookAppointment(doc)
            else if (_selectedTabIndex == 0)
              _buildTabAboutDoctor(doc)
            else
              _buildTabReviews(doc, reviewsAsync),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. QUICK ACTION BUTTON (Call, Message, Direction, Share)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return FluidPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDFA), // Calming soft mint/cyan
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(height: 7),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. TAB BAR (About Doctor, Book Appointment, Reviews)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    final tabs = ['About Doctor', 'Book Appointment', 'Reviews'];

    return Column(
      children: [
        Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = _selectedTabIndex == index;
            return Expanded(
              child: FluidPressable(
                onTap: () => setState(() => _selectedTabIndex = index),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        tabs[index],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        Container(height: 1, color: const Color(0xFFF1F5F9)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. TAB 1: BOOK APPOINTMENT (Matches website screenshot)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTabBookAppointment(DoctorModel doc) {
    final activeHomeFee = _selectedCategoryOption != null ? _selectedCategoryOption!.feeHome : doc.fees.home;
    final activeOnlineFee = _selectedCategoryOption != null ? _selectedCategoryOption!.feeOnline : doc.fees.online;
    final activeFee = _selectedMode == 'home' ? activeHomeFee : activeOnlineFee;
    final selectedDate = _upcomingDates[_selectedDateIndex];
    final slotQuery = SlotQuery(
      doctorSlug: doc.slug,
      date: IstTime.apiDate(selectedDate),
    );
    final slotsAsync = ref.watch(slotAvailabilityProvider(slotQuery));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Consultation Fee By Speciality (Matches website: media_1795114387558_b0efb712.jpg)
        if (doc.categoryOptions.isNotEmpty) ...[
          _buildConsultationFeeBySpeciality(doc),
          const SizedBox(height: 24),
        ],

        // 2. Consultation Mode Selection
        Text(
          'Consultation Mode',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (doc.homeVisitsEnabled)
              Expanded(
                child: _buildModeCard(
                  title: 'Home Visit',
                  fee: '₹${activeHomeFee.toInt()}',
                  icon: LucideIcons.home,
                  isSelected: _selectedMode == 'home',
                  onTap: () => setState(() => _selectedMode = 'home'),
                ),
              ),
            if (doc.homeVisitsEnabled) const SizedBox(width: 12),
            Expanded(
              child: _buildModeCard(
                title: 'Online Video',
                fee: '₹${activeOnlineFee.toInt()}',
                icon: LucideIcons.video,
                isSelected: _selectedMode == 'online',
                onTap: () => setState(() => _selectedMode = 'online'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 3. Schedule Date Header + Calendar Icon Picker
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Schedule Date',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            FluidPressable(
              onTap: () => _selectCustomDate(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(LucideIcons.calendar, size: 18, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Horizontal Date Selector (14 upcoming days)
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _upcomingDates.length,
            itemBuilder: (context, index) {
              final date = _upcomingDates[index];
              final isSelected = _selectedDateIndex == index;
              final dayNum = DateFormat('dd').format(date);
              final dayName = DateFormat('EEE').format(date);

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: FluidPressable(
                  onTap: () {
                    setState(() {
                      _selectedDateIndex = index;
                      _selectedSlotModel = null;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 62,
                    height: 78,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? const [
                              BoxShadow(
                                color: Color(0x330891B2),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayNum,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dayName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // 4. Time Window Section (Live from GET /doctors/:slug/slots?date=YYYY-MM-DD)
        Text(
          'Select Time Window',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 14),
        slotsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
              ),
            ),
          ),
          error: (_, _) => _buildTimeWindowsList(_fallbackWindows),
          data: (availability) {
            final windows = availability.windows.isNotEmpty ? availability.windows : _fallbackWindows;
            return _buildTimeWindowsList(windows);
          },
        ),
        const SizedBox(height: 24),

        // 5. Home Visit Coverage
        _buildHomeVisitCoverage(doc),
        const SizedBox(height: 28),

        // 6. Bottom CTA Button: Book Appointment with Price
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF009AA6), Color(0xFF26B4BD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33009AA6),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            onPressed: () => _proceedToBooking(doc),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Book Appointment',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '₹${activeFee.toInt()}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeWindowsList(List<SlotModel> windows) {
    if (_selectedSlotModel == null && windows.isNotEmpty) {
      _selectedSlotModel = windows.firstWhere((w) => w.available, orElse: () => windows.first);
    }

    return Column(
      children: windows.map((slot) {
        final isSelected = _selectedSlotModel != null &&
            (_selectedSlotModel!.slot == slot.slot ||
             (_selectedSlotModel!.label != null && _selectedSlotModel!.label == slot.label));
        final icon = _getTimeWindowIcon(slot.label ?? slot.slot);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FluidPressable(
            onTap: slot.available
                ? () {
                    setState(() {
                      _selectedSlotModel = slot;
                    });
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF0FDFA) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0891B2) : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Color(0x140891B2),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Opacity(
                opacity: slot.available ? 1.0 : 0.5,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0891B2) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slot.displayTitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? const Color(0xFF0891B2) : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            slot.timeRange,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0891B2) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        slot.available ? '${slot.availableSpots} spots' : 'Full',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// CONSULTATION FEE BY SPECIALITY (Directly matching media_1795114387558_b0efb712.jpg)
  Widget _buildConsultationFeeBySpeciality(DoctorModel doc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.fileText, size: 16, color: Color(0xFF0891B2)),
              const SizedBox(width: 8),
              Text(
                'CONSULTATION FEE BY SPECIALITY',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0891B2),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: doc.categoryOptions.map((option) {
              final isSelected = _selectedCategoryOption?.categoryId == option.categoryId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FluidPressable(
                  onTap: () => setState(() => _selectedCategoryOption = option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF0FDFA) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0891B2) : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? const [
                              BoxShadow(
                                color: Color(0x140891B2),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            option.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Text(
                          'Home ₹${option.feeHome.toInt()} · Video ₹${option.feeOnline.toInt()}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? const Color(0xFF0891B2) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Home Visit Coverage (Directly matching media_1795114387558_b0efb712.jpg)
  Widget _buildHomeVisitCoverage(DoctorModel doc) {
    final areas = doc.serviceLocations.where((l) => l.area != null && l.area!.isNotEmpty).map((l) => l.area!).toSet().toList();
    if (areas.isEmpty && doc.location.area != null && doc.location.area!.isNotEmpty) {
      areas.add(doc.location.area!);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.mapPin, size: 16, color: Color(0xFF0891B2)),
              const SizedBox(width: 8),
              Text(
                'Home Visit Coverage',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          if (areas.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: areas.map((area) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCCFBF1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.home, size: 12, color: Color(0xFF0891B2)),
                      const SizedBox(width: 5),
                      Text(
                        area,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(LucideIcons.globe, size: 14, color: Color(0xFF0891B2)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Online (Pan-India) — available anywhere in India',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0F766E),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String fee,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FluidPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDFA) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? AppColors.primary : const Color(0xFF64748B)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    fee,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
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

  // ─────────────────────────────────────────────────────────────────────────────
  // 6. TAB 0: ABOUT DOCTOR
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTabAboutDoctor(DoctorModel doc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About the Doctor',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          doc.bio.isNotEmpty
              ? doc.bio
              : 'Dr. ${doc.name} is a certified physiotherapy clinician with extensive experience in physical rehabilitation, restorative mobility, and patient-centered musculoskeletal therapy.',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF475569),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),

        if (doc.registration != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCCFBF1)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verified Medical Practitioner',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${doc.registration!['council'] ?? 'State Council'} • Reg: ${doc.registration!['number'] ?? 'Verified'}',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        if (doc.expertise.isNotEmpty) ...[
          Text(
            'Clinical Focus & Expertise',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: doc.expertise.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  item,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        if (doc.categoryOptions.isNotEmpty) ...[
          _buildConsultationFeeBySpeciality(doc),
          const SizedBox(height: 20),
        ],

        _buildHomeVisitCoverage(doc),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => setState(() => _selectedTabIndex = 1),
            child: Text(
              'Book Appointment',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 7. TAB 2: REVIEWS
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTabReviews(DoctorModel doc, AsyncValue<List<ReviewModel>> reviewsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Patient Reviews',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            Row(
              children: [
                if (doc.rating > 0) ...[
                  const Icon(LucideIcons.star, size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 4),
                  Text(
                    '${doc.rating.toStringAsFixed(1)} (${doc.reviewCount})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ] else
                  Text(
                    'New Practitioner',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0891B2),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        reviewsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (_, _) => _buildNoReviewsState(doc),
          data: (reviews) {
            if (reviews.isEmpty) {
              return _buildNoReviewsState(doc);
            }
            return Column(
              children: reviews.map((r) => _buildReviewCard(r)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNoReviewsState(DoctorModel doc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFEBF8FA),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.messageSquare, size: 24, color: Color(0xFF0891B2)),
          ),
          const SizedBox(height: 12),
          Text(
            'No Reviews Yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Reviews will appear after patients complete consultations with ${doc.name}.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                r.patientName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    LucideIcons.star,
                    size: 13,
                    color: i < r.rating.round() ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ],
          ),
          if (r.date != null) ...[
            const SizedBox(height: 2),
            Text(
              r.date!,
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            r.comment,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569), height: 1.45),
          ),
        ],
      ),
    );
  }
}
