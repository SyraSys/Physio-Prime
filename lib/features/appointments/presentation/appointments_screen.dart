import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fluid_pressable.dart';
import '../../../core/widgets/frosted_glass.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  int _selectedTab = 0; // 0: Upcoming, 1: Completed, 2: Cancelled

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FrostedGlassAppBar(
        title: const Text(
          'My Appointments',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.headingText),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FluidPressable(
              onTap: () => context.go('/doctors'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.plus, size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text('Book Slot', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // iOS Segmented Tab Switcher
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                children: [
                  _SegmentButton(
                    title: 'Upcoming (1)',
                    isSelected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                  _SegmentButton(
                    title: 'Completed (1)',
                    isSelected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                  _SegmentButton(
                    title: 'Cancelled',
                    isSelected: _selectedTab == 2,
                    onTap: () => setState(() => _selectedTab = 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            if (_selectedTab == 0) ...[
              // Upcoming Appointments with Dr. Tarannum Sayyed
              _AppointmentCard(
                doctorName: 'Dr. Tarannum Sayyed',
                specialty: 'Orthopedic & Post-Op Rehab Specialist',
                date: 'Tomorrow, Oct 12',
                time: '10:30 AM - 11:15 AM',
                mode: 'Home Visit',
                modeIcon: LucideIcons.home,
                modeColor: const Color(0xFF047857),
                modeBg: const Color(0xFFD1FAE5),
                status: 'Confirmed',
                address: 'Plot 42, Civil Lines, Nagpur',
                sessionCost: '₹1,000 (Paid Online)',
                primaryActionTitle: 'Track Therapist Arrival',
                primaryActionIcon: LucideIcons.navigation,
                onPrimaryAction: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dr. Tarannum will depart at 10:00 AM. Live GPS tracking will activate then.')),
                  );
                },
              ),
            ] else if (_selectedTab == 1) ...[
              _PastAppointmentCard(
                doctorName: 'Dr. Tarannum Sayyed',
                specialty: 'Orthopedic & Knee Rehab Specialist',
                date: 'Oct 05, 2026',
                mode: 'Home Visit',
                notes: 'Post-op quadriceps activation completed. Range of motion improved by 15 degrees.',
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(32),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: const Column(
                  children: [
                    Icon(LucideIcons.calendarX, size: 42, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No Cancelled Appointments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.headingText)),
                    SizedBox(height: 4),
                    Text('All your booked sessions are active or successfully completed.', style: TextStyle(fontSize: 12, color: AppColors.bodyText), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentButton({required this.title, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FluidPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.bodyText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final String doctorName;
  final String specialty;
  final String date;
  final String time;
  final String mode;
  final IconData modeIcon;
  final Color modeColor;
  final Color modeBg;
  final String status;
  final String address;
  final String sessionCost;
  final String primaryActionTitle;
  final IconData primaryActionIcon;
  final VoidCallback onPrimaryAction;

  const _AppointmentCard({
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
    required this.mode,
    required this.modeIcon,
    required this.modeColor,
    required this.modeBg,
    required this.status,
    required this.address,
    required this.sessionCost,
    required this.primaryActionTitle,
    required this.primaryActionIcon,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: modeBg, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(modeIcon, size: 12, color: modeColor),
                    const SizedBox(width: 4),
                    Text(mode, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: modeColor)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.headingText)),
          const SizedBox(height: 2),
          Text(specialty, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.headingText)),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 8),
                    Text(time, style: const TextStyle(fontSize: 12, color: AppColors.bodyText)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(address, style: const TextStyle(fontSize: 11, color: AppColors.bodyText))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FluidPressable(
                  onTap: onPrimaryAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(primaryActionIcon, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(primaryActionTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FluidPressable(
                onTap: () {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (ctx) => CupertinoActionSheet(
                      title: Text('Manage Appointment with $doctorName'),
                      actions: [
                        CupertinoActionSheetAction(
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.go('/doctors');
                          },
                          child: const Text('Reschedule Slot'),
                        ),
                        CupertinoActionSheetAction(
                          isDestructiveAction: true,
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Refund of ₹1,000 initiated. Cancellation processed.')),
                            );
                          },
                          child: const Text('Cancel Session'),
                        ),
                      ],
                      cancelButton: CupertinoActionSheetAction(
                        child: const Text('Close'),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.moreHorizontal, size: 16, color: AppColors.headingText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PastAppointmentCard extends StatelessWidget {
  final String doctorName;
  final String specialty;
  final String date;
  final String mode;
  final String notes;

  const _PastAppointmentCard({
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.mode,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.headingText)),
              Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 2),
          Text(specialty, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
            child: Text(notes, style: const TextStyle(fontSize: 11, color: AppColors.bodyText, height: 1.3)),
          ),
        ],
      ),
    );
  }
}
