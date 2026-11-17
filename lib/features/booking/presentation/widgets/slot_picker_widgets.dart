import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/ist_time.dart';
import '../../../../core/widgets/fluid_pressable.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/slot_model.dart';
import '../../providers/booking_provider.dart';

/// Horizontally scrolling date pills for the next N IST days.
class DatePillsRow extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;
  final EdgeInsetsGeometry padding;

  const DatePillsRow({
    super.key,
    required this.days,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        padding: padding,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final day = days[i];
          final isSelected = IstTime.isSameDay(day, selected);
          return Semantics(
            selected: isSelected,
            button: true,
            label: IstTime.longDate(day),
            child: FluidPressable(
              onTap: () => onSelected(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 64,
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isSelected ? Colors.transparent : AppColors.borderSoft),
                  boxShadow: isSelected
                      ? const [BoxShadow(color: Color(0x330891B2), blurRadius: 10, offset: Offset(0, 3))]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      IstTime.relativeDayLabel(day),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white70 : AppColors.bodyText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: isSelected ? Colors.white : AppColors.headingText,
                      ),
                    ),
                    Text(
                      IstTime.month(day),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white70 : AppColors.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Loads and renders slots for [query], handling loading / error / empty
/// states. Slots that are booked, or already started today (IST), are shown
/// disabled.
class SlotAvailabilityGrid extends ConsumerWidget {
  final SlotQuery query;
  final DateTime date;
  final String? selectedSlot;
  final ValueChanged<String> onSelected;

  /// A slot to treat as unavailable (e.g. the appointment's current slot when
  /// rescheduling).
  final String? excludedSlot;

  const SlotAvailabilityGrid({
    super.key,
    required this.query,
    required this.date,
    required this.selectedSlot,
    required this.onSelected,
    this.excludedSlot,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(slotAvailabilityProvider(query));

    return async.when(
      skipLoadingOnRefresh: false,
      loading: () => const LoadingView(message: 'Checking availability…'),
      error: (e, _) => ErrorView(
        error: e,
        compact: true,
        title: 'Could not load slots',
        onRetry: () => ref.invalidate(slotAvailabilityProvider(query)),
      ),
      data: (availability) {
        if (availability.windows.isEmpty) {
          return const EmptyStateView(
            icon: LucideIcons.calendarX,
            title: 'No slots on this day',
            message: 'The physiotherapist is not available on this date. Please pick another day.',
          );
        }
        final slots = availability.windows.map((w) {
          final started = IstTime.slotHasStarted(date, w.slot);
          final excluded = excludedSlot != null && excludedSlot == w.slot;
          return (slot: w.slot, enabled: w.available && !started && !excluded, booked: !w.available);
        }).toList();

        final anyEnabled = slots.any((s) => s.enabled);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final s in slots)
                  _SlotChip(
                    label: s.slot,
                    enabled: s.enabled,
                    booked: s.booked,
                    selected: selectedSlot == s.slot,
                    onTap: () => onSelected(s.slot),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                _LegendDot(color: AppColors.primary, label: 'Available'),
                SizedBox(width: 16),
                _LegendDot(color: Color(0xFFCBD5E1), label: 'Booked / unavailable'),
              ],
            ),
            if (!anyEnabled) ...[
              const SizedBox(height: 12),
              const InfoBanner(
                icon: LucideIcons.info,
                message: 'All slots on this day are taken. Please choose another date.',
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SlotChip extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool booked;
  final bool selected;
  final VoidCallback onTap;

  const _SlotChip({
    required this.label,
    required this.enabled,
    required this.booked,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 32 - 10) / 2;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: enabled ? 'Slot $label' : 'Slot $label, unavailable',
      child: FluidPressable(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: width.clamp(140, 220).toDouble(),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : enabled
                ? Colors.white
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : enabled
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected
                    ? LucideIcons.checkCircle2
                    : enabled
                    ? LucideIcons.clock
                    : LucideIcons.xCircle,
                size: 14,
                color: selected
                    ? Colors.white
                    : enabled
                    ? AppColors.primary
                    : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white
                        : enabled
                        ? AppColors.headingText
                        : const Color(0xFF94A3B8),
                    decoration: booked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.bodyText)),
      ],
    );
  }
}

/// Avatar with network photo fallback to initials.
class DoctorAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double size;

  const DoctorAvatar({super.key, required this.name, this.photoUrl, this.size = 52});

  String get _initials {
    final parts = name
        .replaceAll(RegExp(r'^(Dr\.?\s+)', caseSensitive: false), '')
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'Dr';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: Text(
        _initials,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.32),
      ),
    );
    final url = photoUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.3),
      child: (url == null || !url.startsWith('http'))
          ? fallback
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
              loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
            ),
    );
  }
}
