import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/doctor_model.dart';
import '../providers/doctors_provider.dart';

class DoctorDetailScreen extends ConsumerWidget {
  final String slug;
  final DoctorModel? doctor;

  const DoctorDetailScreen({
    super.key,
    required this.slug,
    this.doctor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(doctorDetailProvider(slug));
    final reviewsAsync = ref.watch(doctorReviewsProvider(slug));

    final doc = doctor ?? detailAsync.value;

    if (doc == null && detailAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (doc == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Doctor Profile')),
        body: const Center(child: Text('Doctor profile could not be loaded.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.name),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Profile Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: doc.photo != null
                            ? CachedNetworkImage(
                                imageUrl: doc.photo!,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(width: 90, height: 90, color: AppColors.surfaceSoft),
                                errorWidget: (context, url, error) => Container(
                                  width: 90,
                                  height: 90,
                                  color: AppColors.surfaceSoft,
                                  child: const Icon(LucideIcons.user, size: 40, color: AppColors.primary),
                                ),
                              )
                            : Container(
                                width: 90,
                                height: 90,
                                color: AppColors.surfaceSoft,
                                child: const Icon(LucideIcons.user, size: 40, color: AppColors.primary),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    doc.name,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.headingText),
                                  ),
                                ),
                                if (doc.verified)
                                  const Icon(LucideIcons.badgeCheck, color: AppColors.primary, size: 20),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              doc.specialty,
                              style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(LucideIcons.mapPin, size: 13, color: AppColors.bodyText),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    doc.location.displayString,
                                    style: const TextStyle(fontSize: 12, color: AppColors.bodyText),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quick Stats Row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderSoft),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: 'Experience',
                          value: '${doc.experienceYears}+ Yrs',
                          icon: LucideIcons.briefcase,
                        ),
                        const _Divider(),
                        _StatItem(
                          label: 'Rating',
                          value: '${doc.rating} ★',
                          icon: LucideIcons.star,
                          valueColor: Colors.amber.shade800,
                        ),
                        const _Divider(),
                        _StatItem(
                          label: 'Patients',
                          value: '${doc.patientsTreated > 0 ? doc.patientsTreated : doc.reviewCount * 8}+',
                          icon: LucideIcons.users,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Registration & Council Badge
            if (doc.registration != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.shieldCheck, color: AppColors.accentTeal, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Council Registration Verified', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(
                              '${doc.registration!['council'] ?? 'State OTPT Council'} • Reg: ${doc.registration!['number'] ?? 'Verified'}',
                              style: const TextStyle(fontSize: 12, color: AppColors.bodyText),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Clinical Bio
            if (doc.bio.isNotEmpty) ...[
              _SectionCard(
                title: 'About the Doctor',
                child: Text(
                  doc.bio,
                  style: const TextStyle(fontSize: 14, color: AppColors.bodyText, height: 1.55),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Education & Experience
            if (doc.education.isNotEmpty || doc.experience.isNotEmpty) ...[
              _SectionCard(
                title: 'Qualifications & Background',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (doc.education.isNotEmpty) ...[
                      const Text('Education', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.headingText)),
                      const SizedBox(height: 6),
                      ...doc.education.map((e) => _BulletText(text: e)),
                      const SizedBox(height: 12),
                    ],
                    if (doc.experience.isNotEmpty) ...[
                      const Text('Clinical Experience', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.headingText)),
                      const SizedBox(height: 6),
                      ...doc.experience.map((e) => _BulletText(text: e)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Expertise & Treatments
            if (doc.expertise.isNotEmpty || doc.treatments.isNotEmpty) ...[
              _SectionCard(
                title: 'Clinical Expertise & Treatments',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (doc.expertise.isNotEmpty) ...[
                      const Text('Specialized Areas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: doc.expertise.map((exp) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderSoft),
                            ),
                            child: Text(exp, style: const TextStyle(fontSize: 12, color: AppColors.headingText)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (doc.treatments.isNotEmpty) ...[
                      const Text('Treatments Offered', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: doc.treatments.map((tr) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderSoft),
                            ),
                            child: Text(tr, style: const TextStyle(fontSize: 12, color: AppColors.bodyText)),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Patient Reviews Section
            _SectionCard(
              title: 'Patient Reviews (${doc.reviewCount})',
              child: reviewsAsync.when(
                data: (reviews) {
                  if (reviews.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No reviews yet. Be the first to consult with this doctor!'),
                    );
                  }
                  return Column(
                    children: reviews.take(5).map((rev) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(rev.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(width: 6),
                                    const Icon(LucideIcons.checkCircle, color: AppColors.primary, size: 14),
                                  ],
                                ),
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      LucideIcons.star,
                                      size: 13,
                                      color: i < rev.rating.round() ? Colors.amber : Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (rev.date != null && rev.date!.isNotEmpty)
                              Text(rev.date!, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(rev.comment, style: const TextStyle(fontSize: 13, color: AppColors.bodyText)),
                            const Divider(height: 16),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
                error: (error, stack) => const Text('Could not load reviews.'),
              ),
            ),
          ],
        ),
      ),

      // Fixed Bottom Booking Action Bar (Hand-off to Developer 2)
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Consultation from', style: TextStyle(fontSize: 11, color: AppColors.bodyText)),
                  Text(
                    '₹${doc.startingFee}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Hand-off contract to Developer 2's BookingSlotsScreen
                    context.push(
                      '/booking-slots',
                      extra: {
                        'doctorId': doc.id,
                        'doctorSlug': doc.slug,
                        'doctorName': doc.name,
                        'mode': doc.homeVisitsEnabled ? 'home' : 'online',
                        'fee': doc.startingFee,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Book Consultation Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  final String text;
  const _BulletText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.bodyText))),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: valueColor ?? AppColors.headingText)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.bodyText)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 24, width: 1, color: AppColors.borderSoft);
  }
}
