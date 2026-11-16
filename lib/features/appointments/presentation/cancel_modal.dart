import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/widgets/state_views.dart';
import '../data/appointments_repository.dart';
import '../domain/appointment_model.dart';
import '../providers/appointments_provider.dart';
import 'widgets/sheet_scaffold.dart';

/// Opens the cancellation sheet. Resolves to `true` when cancelled.
Future<bool> showCancelModal(BuildContext context, AppointmentModel appointment) async {
  final result = await showActionSheet<bool>(context, CancelModal(appointment: appointment));
  return result ?? false;
}

class CancelModal extends ConsumerStatefulWidget {
  final AppointmentModel appointment;
  const CancelModal({super.key, required this.appointment});

  @override
  ConsumerState<CancelModal> createState() => _CancelModalState();
}

class _CancelModalState extends ConsumerState<CancelModal> {
  static const _reasons = [
    'Patient unwell',
    'Schedule conflict',
    'Booked by mistake',
    'Feeling better / no longer needed',
    'Chose another provider',
    'Other',
  ];

  String? _reason;
  final _otherController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  String? get _finalReason {
    if (_reason == null) return null;
    if (_reason == 'Other') {
      final text = _otherController.text.trim();
      return text.length >= 5 ? text : null;
    }
    return _reason;
  }

  Future<void> _submit() async {
    final reason = _finalReason;
    if (_submitting) return;
    if (reason == null) {
      setState(
        () => _error = _reason == 'Other'
            ? 'Please describe the reason (at least 5 characters).'
            : 'Please choose a reason for cancelling.',
      );
      return;
    }
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(appointmentsRepositoryProvider).cancel(id: widget.appointment.id, reason: reason);
      container.invalidate(appointmentsProvider);
      if (!mounted) return;
      showAppSnack(context, 'Your appointment has been cancelled.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = ApiException.from(e).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    return PopScope(
      canPop: !_submitting,
      child: ActionSheetScaffold(
        title: 'Cancel appointment?',
        subtitle: '${appointment.doctor.name} · ${appointment.whenLabel}',
        busy: _submitting,
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DangerButton(
              label: _submitting ? 'Cancelling…' : 'Cancel appointment',
              loading: _submitting,
              onPressed: _reason == null ? null : _submit,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
              child: const Text(
                'Keep appointment',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (appointment.isPaid)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: InfoBanner(
                    icon: LucideIcons.info,
                    message:
                        'This appointment is prepaid. Any refund is processed as per the PhysioPrime cancellation policy.',
                  ),
                ),
              const Text(
                'Reason for cancelling',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.headingText),
              ),
              const SizedBox(height: 8),
              for (final r in _reasons)
                _ReasonTile(
                  label: r,
                  selected: _reason == r,
                  onTap: _submitting
                      ? null
                      : () => setState(() {
                          _reason = r;
                          _error = null;
                        }),
                ),
              if (_reason == 'Other') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _otherController,
                  enabled: !_submitting,
                  maxLines: 3,
                  maxLength: 300,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() => _error = null),
                  decoration: InputDecoration(
                    hintText: 'Tell us briefly why you are cancelling',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                InfoBanner(icon: LucideIcons.alertCircle, color: AppColors.error, message: _error!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _ReasonTile({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? AppColors.error : const Color(0xFFCBD5E1), width: 2),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.headingText,
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

class _DangerButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const _DangerButton({required this.label, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          disabledBackgroundColor: AppColors.error.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: enabled ? onPressed : null,
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(LucideIcons.calendarX, size: 18),
        label: Text(label),
      ),
    );
  }
}
