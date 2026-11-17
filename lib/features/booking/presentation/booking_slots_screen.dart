import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ist_time.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/fluid_pressable.dart';
import '../../../core/widgets/frosted_glass.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/data/auth_repository.dart';
import '../../doctors/domain/doctor_model.dart';
import '../../doctors/providers/doctors_provider.dart';
import '../domain/booking_request_model.dart';
import '../domain/slot_model.dart';
import '../providers/booking_provider.dart';
import 'widgets/slot_picker_widgets.dart';

/// Step 1 of booking: choose consultation mode, date (next 14 IST days) and
/// an available time slot.
class BookingSlotsScreen extends ConsumerStatefulWidget {
  final BookingDoctorInfo doctor;

  const BookingSlotsScreen({super.key, required this.doctor});

  @override
  ConsumerState<BookingSlotsScreen> createState() => _BookingSlotsScreenState();
}

class _BookingSlotsScreenState extends ConsumerState<BookingSlotsScreen> {
  late final List<DateTime> _days = IstTime.upcomingDays(14);
  late DateTime _selectedDate = _days.first;
  late ConsultationMode _mode = widget.doctor.initialMode;
  String? _selectedSlot;

  /// Merges route arguments with the live doctor profile when it matches the
  /// requested slug (never trusts a mismatched fallback profile).
  BookingDoctorInfo _resolveDoctor(DoctorModel? profile) {
    final base = widget.doctor;
    if (profile == null || (profile.slug != base.slug && profile.id != base.slug)) {
      return base;
    }
    return base.copyWith(
      title: profile.title.isNotEmpty ? profile.title : null,
      photo: profile.photo,
      categoryId: base.categoryId ?? (profile.categories.isNotEmpty ? profile.categories.first : null),
      homeVisitsEnabled: profile.homeVisitsEnabled,
      feePaise: base.feePaise ?? profile.feePaise?.round(),
    );
  }

  void _selectDate(DateTime day) {
    if (IstTime.isSameDay(day, _selectedDate)) return;
    setState(() {
      _selectedDate = day;
      _selectedSlot = null;
    });
  }

  void _continue(BookingDoctorInfo doctor) {
    final slot = _selectedSlot;
    if (slot == null) {
      showAppSnack(context, 'Please select an available time slot.');
      return;
    }
    if (IstTime.slotHasStarted(_selectedDate, slot)) {
      setState(() => _selectedSlot = null);
      showAppSnack(context, 'That slot has already started. Please choose another.', error: true);
      return;
    }
    if (!ref.read(authRepositoryProvider).isAuthenticated) {
      _promptSignIn();
      return;
    }
    context.push(
      '/booking-checkout',
      extra: BookingSelection(doctor: doctor, mode: _mode, date: IstTime.apiDate(_selectedDate), slot: slot),
    );
  }

  void _promptSignIn() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.lock, color: AppColors.primary, size: 30),
              const SizedBox(height: 12),
              const Text(
                'Sign in to book',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.headingText),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your appointment, payment and prescriptions are linked to your PhysioPrime account. Your slot selection is kept.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.bodyText, height: 1.4),
              ),
              const SizedBox(height: 20),
              PrimaryActionButton(
                label: 'Sign in',
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/login');
                },
              ),
              const SizedBox(height: 10),
              SecondaryActionButton(
                label: 'Create an account',
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/register');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(doctorDetailProvider(widget.doctor.slug)).value;
    final doctor = _resolveDoctor(profile);

    if (_mode == ConsultationMode.home && !doctor.homeVisitsEnabled) {
      // Profile says home visits are unavailable: switch to online.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _mode == ConsultationMode.home) {
          setState(() => _mode = ConsultationMode.online);
        }
      });
    }

    final query = SlotQuery(doctorSlug: doctor.slug, date: IstTime.apiDate(_selectedDate));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FrostedGlassAppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.canPop() ? context.pop() : context.go('/doctors'),
        ),
        title: const Text('Select a Slot'),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.primary,
            edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
            onRefresh: () async => ref.invalidate(slotAvailabilityProvider(query)),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + kToolbarHeight + 12, bottom: 140),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _DoctorSummaryCard(doctor: doctor),
                ),
                const SizedBox(height: 20),
                const _SectionLabel(title: 'Consultation type'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ModeOption(
                          icon: LucideIcons.home,
                          title: 'Home Visit',
                          subtitle: doctor.homeVisitsEnabled ? 'Physio comes to you' : 'Not offered',
                          selected: _mode == ConsultationMode.home,
                          enabled: doctor.homeVisitsEnabled,
                          onTap: () => setState(() => _mode = ConsultationMode.home),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ModeOption(
                          icon: LucideIcons.video,
                          title: 'Video Consult',
                          subtitle: 'From anywhere',
                          selected: _mode == ConsultationMode.online,
                          enabled: true,
                          onTap: () => setState(() => _mode = ConsultationMode.online),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _SectionLabel(
                  title: 'Choose a date',
                  trailing: Text(
                    IstTime.longDate(_selectedDate),
                    style: const TextStyle(fontSize: 12, color: AppColors.bodyText, fontWeight: FontWeight.w600),
                  ),
                ),
                DatePillsRow(days: _days, selected: _selectedDate, onSelected: _selectDate),
                const SizedBox(height: 22),
                const _SectionLabel(title: 'Available time slots', subtitle: 'All times are in IST'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SlotAvailabilityGrid(
                    key: ValueKey(query.date),
                    query: query,
                    date: _selectedDate,
                    selectedSlot: _selectedSlot,
                    onSelected: (slot) => setState(() => _selectedSlot = slot),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomBar(
              feeLabel: Money.fromPaiseOrNull(doctor.feePaise),
              selectionLabel: _selectedSlot == null
                  ? 'No slot selected'
                  : '${IstTime.relativeDayLabel(_selectedDate)}, ${_selectedSlot!}',
              onContinue: _selectedSlot == null ? null : () => _continue(doctor),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorSummaryCard extends StatelessWidget {
  final BookingDoctorInfo doctor;
  const _DoctorSummaryCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Row(
        children: [
          DoctorAvatar(name: doctor.name, photoUrl: doctor.photo, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.headingText),
                ),
                if (doctor.title != null) ...[
                  const SizedBox(height: 2),
                  Text(doctor.title!, style: const TextStyle(fontSize: 12.5, color: AppColors.bodyText)),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(LucideIcons.badgeCheck, size: 14, color: AppColors.accentTeal),
                    const SizedBox(width: 4),
                    Text(
                      doctor.feePaise != null
                          ? 'Consultation ${Money.fromPaise(doctor.feePaise!)}'
                          : 'Verified physiotherapist',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.deepTeal),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const _SectionLabel({required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.headingText),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: const TextStyle(fontSize: 11.5, color: AppColors.bodyText)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _ModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: FluidPressable(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceSoft : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? AppColors.primary : AppColors.borderSoft, width: selected ? 1.6 : 1),
          ),
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: Row(
              children: [
                Icon(icon, size: 20, color: selected ? AppColors.primary : AppColors.bodyText),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.headingText,
                        ),
                      ),
                      Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.bodyText)),
                    ],
                  ),
                ),
                if (selected) const Icon(LucideIcons.checkCircle2, size: 18, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final String? feeLabel;
  final String selectionLabel;
  final VoidCallback? onContinue;

  const _BottomBar({required this.feeLabel, required this.selectionLabel, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: Color(0xE6FFFFFF),
            border: Border(top: BorderSide(color: Color(0x14000000), width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectionLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.bodyText),
                      ),
                      Text(
                        feeLabel ?? 'Fee shown at checkout',
                        style: TextStyle(
                          fontSize: feeLabel == null ? 13 : 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 160,
                  child: PrimaryActionButton(label: 'Continue', icon: LucideIcons.arrowRight, onPressed: onContinue),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
