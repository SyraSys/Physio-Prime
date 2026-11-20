import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ist_time.dart';
import '../../appointments/providers/appointments_provider.dart';
import '../../doctors/presentation/widgets/doctor_card.dart';
import '../../doctors/providers/doctors_provider.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showLocationPicker(BuildContext context) {
    final locationsAsync = ref.read(locationsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const Text(
                  'Select Your Service City',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.headingText,
                  ),
                ),
                const SizedBox(height: 12),
                locationsAsync.when(
                  data: (master) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: master.cities.map((city) {
                        final isSelected = ref.watch(selectedCityProvider) == city.name;
                        return ChoiceChip(
                          label: Text(city.name),
                          selected: isSelected,
                          selectedColor: const Color(0xFF0891B2),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.headingText,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (val) {
                            if (val) {
                              ref.read(selectedCityProvider.notifier).state = city.name;
                              ref.read(selectedAreaProvider.notifier).state = null;
                              Navigator.pop(ctx);
                            }
                          },
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => const Text('Could not load locations'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCity = ref.watch(selectedCityProvider);
    final symptomsAsync = ref.watch(symptomsProvider);
    final doctorsAsync = ref.watch(homeDoctorsProvider);
    final appointmentsAsync = ref.watch(appointmentsProvider);
    final upcomingAppointment = appointmentsAsync.value?.where((a) => a.isUpcoming).firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // 1. TOP HEADER (Logo, City, Notification)
              // ==========================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Logo + Location Cluster
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/pp_monogram.png',
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: const TextSpan(
                                text: 'Physio',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Prime',
                                    style: TextStyle(
                                      color: Color(0xFF0891B2),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 1),
                            InkWell(
                              onTap: () => _showLocationPicker(context),
                              borderRadius: BorderRadius.circular(4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.mapPin,
                                    size: 12,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    selectedCity,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    LucideIcons.chevronDown,
                                    size: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Notification Button
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notifications: No new alerts today.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.bell,
                          size: 20,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // 2. SEARCH & FILTER BAR
              // ==========================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    // Search Pill Input
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x080F172A),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: (query) {
                            if (query.trim().isNotEmpty) {
                              context.go('/doctors');
                            }
                          },
                          decoration: const InputDecoration(
                            hintText: 'Search Doctors, Symptoms...',
                            hintStyle: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: Icon(
                              LucideIcons.search,
                              size: 19,
                              color: Color(0xFF94A3B8),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Filter Button
                    InkWell(
                      onTap: () => context.go('/doctors'),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2DD4BF),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x332DD4BF),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.sliders,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // 3. HERO BANNER CARD
              // ==========================================
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                height: 195,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF8FA),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFDEF4F7)),
                ),
                child: Stack(
                  children: [
                    // Left Text & CTA Action
                    Positioned(
                      left: 20,
                      top: 18,
                      bottom: 18,
                      width: 225,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(
                              text: 'Book Prime\nPhysiotherapist for\n',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                height: 1.25,
                                letterSpacing: -0.3,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Back and Neck Pain.',
                                  style: TextStyle(
                                    color: Color(0xFF0891B2),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Connect with certified experts\nfor expert care.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () => context.go('/doctors'),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0D9488), Color(0xFF0891B2)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x330D9488),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'Book Appointment',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    LucideIcons.arrowRight,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right 3D Character Illustration
                    Positioned(
                      right: 0,
                      bottom: 0,
                      top: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        child: Image.asset(
                          'assets/images/hero_doctor.png',
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // 4. UPCOMING APPOINTMENTS / QUICK BOOKING
              // ==========================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      upcomingAppointment != null ? 'Upcoming Appointment' : 'Book a Session',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    InkWell(
                      onTap: () => context.go('/bookings'),
                      child: Text(
                        upcomingAppointment != null ? 'See All' : 'Explore All',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0891B2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (upcomingAppointment != null)
                InkWell(
                  onTap: () => context.push('/appointment/${upcomingAppointment.id}'),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF009AA6), Color(0xFF26B4BD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33009AA6),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                          child: ClipOval(
                            child: upcomingAppointment.doctor.photo != null && upcomingAppointment.doctor.photo!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: upcomingAppointment.doctor.photo!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: Colors.white24),
                                    errorWidget: (context, url, error) => const Icon(LucideIcons.user, color: Colors.white),
                                  )
                                : const Icon(LucideIcons.user, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                upcomingAppointment.doctor.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                upcomingAppointment.doctor.title ?? 'Physiotherapy Session',
                                style: const TextStyle(
                                  color: Color(0xD9FFFFFF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.calendar, size: 14, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  upcomingAppointment.calendarDate != null
                                      ? IstTime.shortDate(upcomingAppointment.calendarDate!)
                                      : (upcomingAppointment.date ?? 'Upcoming'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            if (upcomingAppointment.slot != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.clock, size: 14, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    upcomingAppointment.slot!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                InkWell(
                  onTap: () => context.push('/booking-flow'),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF009AA6), Color(0xFF26B4BD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33009AA6),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.calendarCheck, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Book Certified Physiotherapist',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Home visits & online sessions from ₹799',
                                style: TextStyle(
                                  color: Color(0xD9FFFFFF),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Book Now',
                            style: TextStyle(
                              color: Color(0xFF009AA6),
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ==========================================
              // 5. ALL CATEGORIES SECTION
              // ==========================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'All Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    InkWell(
                      onTap: () => context.go('/doctors'),
                      child: const Text(
                        'See All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0891B2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Categories Horizontal List (7 Specialties)
              SizedBox(
                height: 98,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _CategoryTile(
                      name: 'Orthopedic',
                      iconAsset: 'assets/images/cat_orthopedic.png',
                      onTap: () => context.push('/categories/orthopedic'),
                    ),
                    const SizedBox(width: 14),
                    _CategoryTile(
                      name: 'Sport injury',
                      iconAsset: 'assets/images/cat_sport_injury.png',
                      onTap: () => context.push('/categories/sports-injury'),
                    ),
                    const SizedBox(width: 14),
                    _CategoryTile(
                      name: 'Neurological',
                      iconAsset: 'assets/images/cat_neurological.png',
                      onTap: () => context.push('/categories/neurological'),
                    ),
                    const SizedBox(width: 14),
                    _CategoryTile(
                      name: 'Pediatric',
                      iconAsset: 'assets/images/cat_pediatric.png',
                      onTap: () => context.push('/categories/pediatrics'),
                    ),
                    const SizedBox(width: 14),
                    _CategoryTile(
                      name: 'Cardiac',
                      iconAsset: 'assets/images/cat_cardiac.png',
                      onTap: () => context.push('/categories/cardio-pulmonary'),
                    ),
                    const SizedBox(width: 14),
                    _CategoryTile(
                      name: 'Geriatric',
                      iconAsset: 'assets/images/cat_geriatric.png',
                      onTap: () => context.push('/categories/geriatric'),
                    ),
                    const SizedBox(width: 14),
                    _CategoryTile(
                      name: "Women's Health",
                      iconAsset: 'assets/images/cat_womens_health.png',
                      onTap: () => context.push('/categories/womens-health'),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // 6. FIND SPECIALIST BY SYMPTOMS SECTION
              // ==========================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Find Specialist By Symptoms',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    InkWell(
                      onTap: () => context.push('/conditions'),
                      child: const Text(
                        'See All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0891B2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Symptoms Horizontal List (Same UI as Categories Section)
              symptomsAsync.when(
                data: (symptoms) {
                  if (symptoms.isEmpty) return const SizedBox.shrink();

                  return SizedBox(
                    height: 94,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: symptoms.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final sym = symptoms[index];
                        return _SymptomTile(
                          name: sym.title,
                          imageUrl: sym.image,
                          onTap: () {
                            ref.read(doctorFilterProvider.notifier).update((s) => s.copyWith(symptom: sym.title));
                            context.push('/doctors');
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const SizedBox(height: 98),
                error: (error, stack) => const SizedBox.shrink(),
              ),

              // ==========================================
              // 7. BEST DOCTORS SECTION
              // ==========================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Best Doctors',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    InkWell(
                      onTap: () => context.push('/doctors'),
                      child: const Text(
                        'See All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0891B2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Real Doctor Data from Doctors Repository / API
              doctorsAsync.when(
                data: (doctors) {
                  if (doctors.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Text(
                        'No doctors currently available.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    );
                  }
                  // Render top real doctors using DoctorCard
                  final displayDoctors = doctors.take(3).toList();
                  return Column(
                    children: displayDoctors.map((doc) => DoctorCard(doctor: doc)).toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF0891B2)),
                  ),
                ),
                error: (error, stack) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String name;
  final String iconAsset;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.name,
    required this.iconAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x080F172A),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: Center(
                  child: Image.asset(
                    iconAsset,
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SymptomTile extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final VoidCallback onTap;

  const _SymptomTile({
    required this.name,
    this.imageUrl,
    required this.onTap,
  });

  Widget _buildImage() {
    if (imageUrl != null && imageUrl!.startsWith('http') && !imageUrl!.contains('physio-prime.in/images/')) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          placeholder: (context, url) => _fallbackIcon(),
          errorWidget: (context, error, stackTrace) => _fallbackIcon(),
        ),
      );
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFEBF8FA),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        LucideIcons.activity,
        size: 20,
        color: Color(0xFF0891B2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: SizedBox(
        width: 66,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x080F172A),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: Center(
                  child: _buildImage(),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
