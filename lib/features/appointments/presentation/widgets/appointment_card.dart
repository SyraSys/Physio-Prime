import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/fluid_pressable.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../booking/presentation/widgets/slot_picker_widgets.dart';
import '../../domain/appointment_model.dart';
import '../../providers/appointments_provider.dart';
import '../cancel_modal.dart';
import '../reschedule_modal.dart';
import '../review_modal.dart';

/// Appointment summary card with context-aware actions.
class AppointmentCard extends ConsumerWidget {
  final AppointmentModel appointment;
  final bool showActions;

  const AppointmentCard({super.key, required this.appointment, this.showActions = true});

  void _openDetail(BuildContext context) {
    context.push('/appointment-detail', extra: appointment);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = appointment;
    final reviewed = a.reviewed || ref.watch(locallyReviewedAppointmentsProvider).contains(a.id);

    return Semantics(
      button: true,
      label: 'Appointment with ${a.doctor.name}, ${a.whenLabel}',
      child: FluidPressable(
        pressedScale: 0.985,
        onTap: () => _openDetail(context),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 14, offset: Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DoctorAvatar(name: a.doctor.name, photoUrl: a.doctor.photo, size: 50),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.doctor.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.headingText,
                            ),
                          ),
                          if (a.doctor.title != null)
                            Text(
                              a.doctor.title!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.bodyText),
                            ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              StatusPill(
                                label: AppointmentStatusStyle.statusLabel(a.status),
                                color: AppointmentStatusStyle.statusColor(a.status),
                              ),
                              StatusPill(
                                label: AppointmentStatusStyle.paymentLabel(a.paymentStatus),
                                color: AppointmentStatusStyle.paymentColor(a.paymentStatus),
                              ),
                              if (a.paymentStatus.toLowerCase() == 'pending' && a.isUpcoming)
                                const StatusPill(
                                  label: '15-min hold',
                                  color: Color(0xFFD97706),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (a.feePaise != null)
                      Text(
                        Money.fromPaise(a.feePaise!),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFF8FBFA), borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    _MetaRow(icon: LucideIcons.calendar, text: a.whenLabel),
                    if (a.mode != null) ...[
                      const SizedBox(height: 6),
                      _MetaRow(icon: a.isOnline ? LucideIcons.video : LucideIcons.home, text: a.mode!.label),
                    ],
                  ],
                ),
              ),
              if (showActions) _buildActions(context, reviewed),
              if (!showActions) const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool reviewed) {
    final a = appointment;
    final actions = <Widget>[];

    if (a.isOnline && a.isUpcoming) {
      actions.add(
        _ActionChip(
          icon: LucideIcons.video,
          label: a.canJoinVideo ? 'Join call' : 'Call not open yet',
          primary: a.canJoinVideo,
          onTap: a.canJoinVideo
              ? () => context.push('/video-call', extra: {'appointmentId': a.id, 'doctorName': a.doctor.name})
              : null,
        ),
      );
    }
    if (a.canReschedule) {
      actions.add(
        _ActionChip(icon: LucideIcons.clock, label: 'Reschedule', onTap: () => showRescheduleModal(context, a)),
      );
    }
    if (a.canCancel) {
      actions.add(
        _ActionChip(icon: LucideIcons.xCircle, label: 'Cancel', danger: true, onTap: () => showCancelModal(context, a)),
      );
    }
    if (a.isCompleted && !reviewed) {
      actions.add(
        _ActionChip(
          icon: LucideIcons.star,
          label: 'Rate visit',
          primary: true,
          onTap: () => showReviewModal(context, a),
        ),
      );
    }
    if (a.isCompleted && reviewed) {
      actions.add(const _ActionChip(icon: LucideIcons.checkCircle, label: 'Reviewed'));
    }

    if (actions.isEmpty) return const SizedBox(height: 14);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Wrap(spacing: 8, runSpacing: 8, children: actions),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.headingText),
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool danger;

  const _ActionChip({required this.icon, required this.label, this.onTap, this.primary = false, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.primary;
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: FluidPressable(
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: primary && enabled ? AppColors.primaryGradient : null,
              color: primary && enabled ? null : color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: primary && enabled ? Colors.white : color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: primary && enabled ? Colors.white : color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
