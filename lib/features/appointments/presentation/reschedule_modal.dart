import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/utils/api_error.dart';
import '../../../core/utils/ist_time.dart';
import '../../../core/widgets/state_views.dart';
import '../../booking/domain/slot_model.dart';
import '../../booking/presentation/widgets/slot_picker_widgets.dart';
import '../../booking/providers/booking_provider.dart';
import '../data/appointments_repository.dart';
import '../domain/appointment_model.dart';
import '../providers/appointments_provider.dart';
import 'widgets/sheet_scaffold.dart';

/// Opens the reschedule sheet. Resolves to `true` when rescheduled.
Future<bool> showRescheduleModal(BuildContext context, AppointmentModel appointment) async {
  final result = await showActionSheet<bool>(context, RescheduleModal(appointment: appointment));
  return result ?? false;
}

class RescheduleModal extends ConsumerStatefulWidget {
  final AppointmentModel appointment;
  const RescheduleModal({super.key, required this.appointment});

  @override
  ConsumerState<RescheduleModal> createState() => _RescheduleModalState();
}

class _RescheduleModalState extends ConsumerState<RescheduleModal> {
  late final List<DateTime> _days = IstTime.upcomingDays(14);
  late DateTime _date = _days.first;
  String? _slot;
  bool _submitting = false;
  String? _error;

  String? get _slug => widget.appointment.doctor.slug;

  bool get _isCurrentSlot => widget.appointment.date == IstTime.apiDate(_date) && widget.appointment.slot == _slot;

  Future<void> _submit() async {
    final slot = _slot;
    if (_submitting || slot == null) return;
    if (_isCurrentSlot) {
      setState(() => _error = 'This is your current slot. Choose a different date or time.');
      return;
    }
    if (IstTime.slotHasStarted(_date, slot)) {
      setState(() {
        _slot = null;
        _error = 'That slot has already started. Please pick another.';
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm reschedule'),
        content: Text('Move your appointment to ${IstTime.longDate(_date)}, $slot (IST)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Back')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Reschedule')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final container = ProviderScope.containerOf(context, listen: false);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(appointmentsRepositoryProvider)
          .reschedule(id: widget.appointment.id, date: IstTime.apiDate(_date), slot: slot);
      container.invalidate(appointmentsProvider);
      if (!mounted) return;
      showAppSnack(context, 'Appointment rescheduled to ${IstTime.shortDate(_date)}, $slot');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final api = ApiException.from(e);
      setState(() {
        _submitting = false;
        _error = api.isConflict ? 'That slot was just booked by someone else. Please choose another.' : api.message;
        if (api.isConflict) {
          _slot = null;
          final slug = _slug;
          if (slug != null) {
            container.invalidate(slotAvailabilityProvider(SlotQuery(doctorSlug: slug, date: IstTime.apiDate(_date))));
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final slug = _slug;
    final appointment = widget.appointment;

    return PopScope(
      canPop: !_submitting,
      child: ActionSheetScaffold(
        title: 'Reschedule appointment',
        subtitle: 'Currently ${appointment.whenLabel}',
        busy: _submitting,
        footer: PrimaryActionButton(
          label: _submitting ? 'Rescheduling…' : 'Confirm new slot',
          icon: LucideIcons.calendarCheck,
          loading: _submitting,
          onPressed: (_slot == null || slug == null) ? null : _submit,
        ),
        child: slug == null
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: InfoBanner(
                  icon: LucideIcons.alertTriangle,
                  message:
                      'Live availability for this doctor is not available, so this appointment cannot be '
                      'rescheduled in the app. Please contact PhysioPrime support.',
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
                    child: Text('Pick a new date', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                  DatePillsRow(
                    days: _days,
                    selected: _date,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    onSelected: (d) => setState(() {
                      _date = d;
                      _slot = null;
                      _error = null;
                    }),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
                    child: Text('Available slots (IST)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SlotAvailabilityGrid(
                      key: ValueKey(IstTime.apiDate(_date)),
                      query: SlotQuery(doctorSlug: slug, date: IstTime.apiDate(_date)),
                      date: _date,
                      selectedSlot: _slot,
                      excludedSlot: appointment.date == IstTime.apiDate(_date) ? appointment.slot : null,
                      onSelected: (s) => setState(() {
                        _slot = s;
                        _error = null;
                      }),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: InfoBanner(
                        icon: LucideIcons.alertCircle,
                        color: const Color(0xFFDC2626),
                        message: _error!,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
