import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/fluid_pressable.dart';
import '../../domain/doctor_model.dart';

class DoctorCard extends StatelessWidget {
  final DoctorModel doctor;

  const DoctorCard({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft, width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Avatar with soft depth
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: doctor.photo != null
                      ? CachedNetworkImage(
                          imageUrl: doctor.photo!,
                          width: 78,
                          height: 78,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(width: 78, height: 78, color: AppColors.surfaceSoft),
                          errorWidget: (context, url, error) => Container(
                            width: 78,
                            height: 78,
                            color: AppColors.surfaceSoft,
                            child: const Icon(LucideIcons.user, size: 36, color: AppColors.primary),
                          ),
                        )
                      : Container(
                          width: 78,
                          height: 78,
                          color: AppColors.surfaceSoft,
                          child: const Icon(LucideIcons.user, size: 36, color: AppColors.primary),
                        ),
                ),
                const SizedBox(width: 14),

                // Name & Credentials
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              doctor.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.2, color: AppColors.headingText),
                            ),
                          ),
                          if (doctor.verified)
                            const Icon(LucideIcons.checkCircle2, color: AppColors.primary, size: 16),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctor.specialty,
                        style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(LucideIcons.star, color: Colors.amber, size: 13),
                          const SizedBox(width: 3),
                          Text(
                            doctor.rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            ' (${doctor.reviewCount}+)',
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                          const SizedBox(width: 6),
                          const Text('•', style: TextStyle(color: Colors.grey, fontSize: 10)),
                          const SizedBox(width: 6),
                          Text(
                            '${doctor.experienceYears}+ yrs exp',
                            style: const TextStyle(color: AppColors.bodyText, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(LucideIcons.mapPin, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              doctor.location.displayString,
                              style: const TextStyle(fontSize: 11, color: AppColors.bodyText),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderSoft),
            const SizedBox(height: 12),

            // Consultation Modes & Pricing
            Row(
              children: [
                if (doctor.homeVisitsEnabled) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderSoft),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.home, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text('Home: ₹${doctor.fees.home}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.video, size: 12, color: AppColors.accentTeal),
                      const SizedBox(width: 4),
                      Text('Video: ₹${doctor.fees.online}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Action Buttons with FluidPressable
            Row(
              children: [
                Expanded(
                  child: FluidPressable(
                    onTap: () => context.push('/doctor/${doctor.slug}', extra: doctor),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSoft),
                      ),
                      child: const Text('View Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.headingText)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FluidPressable(
                    onTap: () {
                      // Hand-off contract to Developer 2's BookingSlotsScreen
                      context.push(
                        '/booking-slots',
                        extra: {
                          'doctorId': doctor.id,
                          'doctorSlug': doctor.slug,
                          'doctorName': doctor.name,
                          'mode': doctor.homeVisitsEnabled ? 'home' : 'online',
                          'fee': doctor.startingFee,
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x330891B2),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text('Book Slot', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
