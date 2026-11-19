import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ist_time.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/frosted_glass.dart';
import '../../../core/widgets/state_views.dart';
import '../../booking/domain/booking_request_model.dart';
import '../../booking/presentation/widgets/slot_picker_widgets.dart';
import '../domain/appointment_model.dart';
import '../providers/appointments_provider.dart';
import 'cancel_modal.dart';
import 'reschedule_modal.dart';
import 'review_modal.dart';

/// Full appointment details with status-aware actions. Uses the latest copy
/// from [appointmentsProvider] so changes after actions are reflected.
class AppointmentDetailScreen extends ConsumerWidget {
  final String appointmentId;
  final AppointmentModel? initial;

  const AppointmentDetailScreen({super.key, required this.appointmentId, this.initial});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(appointmentByIdProvider(appointmentId));
    final listState = ref.watch(appointmentsProvider);
    final appointment = latest ?? initial;
    final topPadding = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FrostedGlassAppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.canPop() ? context.pop() : context.go('/appointments'),
        ),
        title: const Text('Appointment Details'),
      ),
      body: appointment == null
          ? Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: listState.when(
                loading: () => const LoadingView(message: 'Loading appointment…'),
                error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(appointmentsProvider)),
                data: (_) => const EmptyStateView(
                  icon: LucideIcons.calendarX,
                  title: 'Appointment not found',
                  message: 'This appointment is no longer available on your account.',
                ),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              edgeOffset: topPadding,
              onRefresh: () async {
                ref.invalidate(appointmentsProvider);
                try {
                  await ref.read(appointmentsProvider.future);
                } catch (_) {}
              },
              child: _DetailBody(appointment: appointment, topPadding: topPadding),
            ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  final AppointmentModel appointment;
  final double topPadding;

  const _DetailBody({required this.appointment, required this.topPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = appointment;
    final reviewed = a.reviewed || ref.watch(locallyReviewedAppointmentsProvider).contains(a.id);
    final statusColor = AppointmentStatusStyle.statusColor(a.status);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 40),
      children: [
        // Status header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: statusColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(
                a.isCancelled
                    ? LucideIcons.calendarX
                    : a.isCompleted
                    ? LucideIcons.checkCircle2
                    : LucideIcons.clock,
                color: statusColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppointmentStatusStyle.statusLabel(a.status),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: statusColor),
                    ),
                    Text(a.whenLabel, style: const TextStyle(fontSize: 12.5, color: AppColors.headingText)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        InfoCard(
          child: Row(
            children: [
              DoctorAvatar(name: a.doctor.name, photoUrl: a.doctor.photo, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.doctor.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.headingText),
                    ),
                    if (a.doctor.title != null)
                      Text(a.doctor.title!, style: const TextStyle(fontSize: 12.5, color: AppColors.bodyText)),
                  ],
                ),
              ),
              if (a.doctor.slug != null)
                IconButton(
                  tooltip: 'View profile',
                  onPressed: () => context.push('/doctor/${a.doctor.slug}'),
                  icon: const Icon(LucideIcons.chevronRight, color: AppColors.primary),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        InfoCard(
          title: 'Schedule',
          icon: LucideIcons.calendar,
          child: Column(
            children: [
              DetailRow(label: 'Date', value: IstTime.displayDate(a.date)),
              if (a.slot != null) DetailRow(label: 'Time', value: '${a.slot} IST'),
              if (a.mode != null) DetailRow(label: 'Consultation', value: a.mode!.label),
              if (a.mode == ConsultationMode.home && a.address != null)
                DetailRow(label: 'Visit address', value: a.address!.display),
            ],
          ),
        ),
        if (_hasPatientInfo(a)) ...[
          const SizedBox(height: 14),
          InfoCard(
            title: 'Patient',
            icon: LucideIcons.user,
            child: Column(
              children: [
                if (a.patientName != null) DetailRow(label: 'Name', value: a.patientName!),
                if (a.patientRelation != null)
                  DetailRow(label: 'Booked for', value: a.patientRelation == 'self' ? 'Self' : 'Family member'),
                if (a.patientPhone != null) DetailRow(label: 'Phone', value: a.patientPhone!),
                if (a.patientEmail != null) DetailRow(label: 'Email', value: a.patientEmail!),
                if (_vitals(a) != null) DetailRow(label: 'Details', value: _vitals(a)!),
              ],
            ),
          ),
        ],
        if (a.symptom != null) ...[
          const SizedBox(height: 14),
          InfoCard(
            title: 'Symptoms / concern',
            icon: LucideIcons.activity,
            child: Text(a.symptom!, style: const TextStyle(fontSize: 13.5, color: AppColors.headingText, height: 1.45)),
          ),
        ],
        if (a.paymentStatus.toLowerCase() == 'pending' && a.isUpcoming) ...[
          const SizedBox(height: 14),
          const InfoBanner(
            icon: LucideIcons.clock,
            message: 'Unpaid prepay bookings are held for 15 minutes before the slot is released to other patients. Complete payment to secure your appointment.',
          ),
        ],
        const SizedBox(height: 14),
        InfoCard(
          title: 'Payment',
          icon: LucideIcons.wallet,
          trailing: StatusPill(
            label: AppointmentStatusStyle.paymentLabel(a.paymentStatus),
            color: AppointmentStatusStyle.paymentColor(a.paymentStatus),
          ),
          child: Column(
            children: [
              if (a.paymentMode != null)
                DetailRow(
                  label: 'Method',
                  value: a.paymentMode == PaymentMode.prepay ? 'Online prepayment' : 'Pay after consultation',
                ),
              if (a.feePaise != null)
                DetailRow(
                  label: a.isPaid ? 'Amount paid' : 'Amount payable',
                  value: Money.fromPaise(a.feePaise!),
                  emphasize: true,
                ),
            ],
          ),
        ),
        if (a.isCancelled && a.cancelReason != null) ...[
          const SizedBox(height: 14),
          InfoCard(
            title: 'Cancellation reason',
            icon: LucideIcons.info,
            child: Text(a.cancelReason!, style: const TextStyle(fontSize: 13.5, color: AppColors.headingText)),
          ),
        ],
        const SizedBox(height: 14),
        InfoCard(
          child: DetailRow(
            label: 'Appointment ID',
            value: a.id,
            trailing: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: a.id));
                showAppSnack(context, 'Appointment ID copied');
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(LucideIcons.fileText, size: 16, color: AppColors.primary, semanticLabel: 'Copy ID'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ..._actions(context, a, reviewed),
      ],
    );
  }

  bool _hasPatientInfo(AppointmentModel a) =>
      a.patientName != null || a.patientPhone != null || a.patientEmail != null || _vitals(a) != null;

  String? _vitals(AppointmentModel a) {
    final parts = <String>[
      if (a.patientGender != null) '${a.patientGender![0].toUpperCase()}${a.patientGender!.substring(1)}',
      if (a.patientAge != null) '${a.patientAge} yrs',
      if (a.patientWeight != null) '${a.patientWeight} kg',
      if (a.patientHeight != null) '${a.patientHeight} cm',
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }

  List<Widget> _actions(BuildContext context, AppointmentModel a, bool reviewed) {
    final widgets = <Widget>[];
    void add(Widget w) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 10));
      widgets.add(w);
    }

    if (a.isOnline && a.isUpcoming) {
      if (a.canJoinVideo) {
        add(
          PrimaryActionButton(
            label: 'Join Video Consultation',
            icon: LucideIcons.video,
            onPressed: () => context.push('/video-call', extra: {'appointmentId': a.id, 'doctorName': a.doctor.name}),
          ),
        );
      } else {
        add(
          const InfoBanner(
            icon: LucideIcons.video,
            message: 'The video room opens when your physiotherapist starts the session. Pull down to refresh.',
          ),
        );
      }
    }
    if (a.isUpcoming) {
      if (a.canReschedule) {
        add(
          SecondaryActionButton(
            label: 'Reschedule',
            icon: LucideIcons.clock,
            onPressed: () => showRescheduleModal(context, a),
          ),
        );
      }
      if (a.canCancel) {
        add(
          SecondaryActionButton(
            label: 'Cancel appointment',
            icon: LucideIcons.xCircle,
            color: AppColors.error,
            onPressed: () => showCancelModal(context, a),
          ),
        );
      }
    }
    if (a.isCompleted) {
      if (!reviewed) {
        add(
          PrimaryActionButton(
            label: 'Rate your consultation',
            icon: LucideIcons.star,
            onPressed: () => showReviewModal(context, a),
          ),
        );
      } else {
        add(const InfoBanner(icon: LucideIcons.checkCircle, message: 'Thanks — you have reviewed this consultation.'));
      }
      add(
        SecondaryActionButton(
          label: 'View prescriptions',
          icon: LucideIcons.pill,
          onPressed: () => context.push('/prescriptions'),
        ),
      );
    }
    if (a.isCancelled) {
      add(
        PrimaryActionButton(
          label: 'Book again',
          icon: LucideIcons.calendarCheck,
          onPressed: () => a.doctor.slug != null ? context.push('/doctor/${a.doctor.slug}') : context.go('/doctors'),
        ),
      );
    }
    return widgets;
  }
}
