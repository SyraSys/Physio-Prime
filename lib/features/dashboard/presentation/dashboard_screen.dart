import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fluid_pressable.dart';
import '../../../core/widgets/frosted_glass.dart';
import '../../auth/providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userName = authState.user?.fullName ?? 'Patient';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FrostedGlassAppBar(
        title: const Text(
          'Health Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.headingText),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell, size: 20, color: AppColors.headingText),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications: Reminder for morning spinal exercises at 08:00 AM.')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Greeting & Recovery Status Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Color(0x260891B2), blurRadius: 18, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Welcome back, $userName',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0x33FFFFFF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Active Care Plan', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Rehabilitation Target: Knee Mobility & Posture Realignment',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Care Plan Progress', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('65% Complete', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const LinearProgressIndicator(
                      value: 0.65,
                      backgroundColor: Color(0x4DFFFFFF),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('4 of 6 sessions completed with Dr. Tarannum Sayyed', style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Quick Health Metric Cards
            Row(
              children: [
                Expanded(
                  child: _DashboardMetricCard(
                    title: 'Current Pain Score',
                    value: '1/10',
                    subtitle: 'Down from 8/10',
                    trend: '87% Improvement',
                    trendColor: const Color(0xFF10B981),
                    icon: LucideIcons.heartPulse,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DashboardMetricCard(
                    title: 'Exercise Streak',
                    value: '14 Days',
                    subtitle: 'Daily routine kept',
                    trend: 'Consistency badge',
                    trendColor: const Color(0xFFF59E0B),
                    icon: LucideIcons.flame,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),

            // Prescribed Daily Home Exercises Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Prescribed Home Exercises', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.headingText)),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All (4)', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ExerciseCard(
              title: 'Isometric Quadriceps Contractions',
              reps: '3 sets × 10 reps',
              duration: '10 mins daily',
              status: 'Completed Today',
              isDone: true,
            ),
            const SizedBox(height: 10),
            _ExerciseCard(
              title: 'Prone Pelvic Tilt & Lumbar Stretch',
              reps: '2 sets × 15 reps',
              duration: '8 mins evening',
              status: 'Pending Evening',
              isDone: false,
            ),
            const SizedBox(height: 26),

            // Digital Prescriptions & Clinical Doctor Notes (EHR)
            const Text('Digital Prescriptions & Doctor Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.headingText)),
            const SizedBox(height: 12),
            _PrescriptionCard(
              date: 'Oct 05, 2026',
              doctorName: 'Dr. Tarannum Sayyed',
              specialty: 'Orthopedic & Post-Op Rehab Specialist',
              diagnosis: 'Left Knee Meniscal Repair & Postural Decompression',
              notes: 'Patient shows substantial restoration in active knee flexion. Recommended progressive weight bearing and resistance band exercises.',
              prescriptionId: 'RX-2026-NAG-8821',
            ),
            const SizedBox(height: 26),

            // Emergency Care / Dedicated Clinical Hotline
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.phoneCall, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('PhysioPrime Care Hotline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.headingText)),
                        SizedBox(height: 2),
                        Text('Direct line to support: +91 96232 04165', style: TextStyle(fontSize: 11, color: AppColors.bodyText)),
                      ],
                    ),
                  ),
                  FluidPressable(
                    onTap: () => context.push('/caretaker'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
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
}

class _DashboardMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final String trend;
  final Color trendColor;
  final IconData icon;

  const _DashboardMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.trend,
    required this.trendColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: AppColors.bodyText, fontWeight: FontWeight.w600)),
              Icon(icon, size: 16, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.headingText)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(trend, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: trendColor)),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final String title;
  final String reps;
  final String duration;
  final String status;
  final bool isDone;

  const _ExerciseCard({
    required this.title,
    required this.reps,
    required this.duration,
    required this.status,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              color: isDone ? const Color(0xFFD1FAE5) : AppColors.surfaceSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDone ? LucideIcons.check : LucideIcons.play,
              size: 16,
              color: isDone ? const Color(0xFF059669) : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.headingText)),
                const SizedBox(height: 2),
                Text('$reps • $duration', style: const TextStyle(fontSize: 11, color: AppColors.bodyText)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDone ? const Color(0xFF047857) : const Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final String date;
  final String doctorName;
  final String specialty;
  final String diagnosis;
  final String notes;
  final String prescriptionId;

  const _PrescriptionCard({
    required this.date,
    required this.doctorName,
    required this.specialty,
    required this.diagnosis,
    required this.notes,
    required this.prescriptionId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.fileCheck2, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(prescriptionId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary)),
                ],
              ),
              Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.headingText)),
          Text(specialty, style: const TextStyle(fontSize: 11, color: AppColors.bodyText)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Clinical Diagnosis:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(diagnosis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.headingText)),
                const SizedBox(height: 8),
                const Text('Therapist Assessment & Instructions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(notes, style: const TextStyle(fontSize: 11, color: AppColors.bodyText, height: 1.35)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Downloading digital prescription $prescriptionId PDF...')),
                  );
                },
                icon: const Icon(LucideIcons.download, size: 14, color: AppColors.primary),
                label: const Text('Download PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
