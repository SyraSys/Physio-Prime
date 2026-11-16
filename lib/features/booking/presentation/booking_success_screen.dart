import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ist_time.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/state_views.dart';
import '../../appointments/domain/appointment_model.dart';
import '../domain/booking_request_model.dart';
import '../domain/booking_response_model.dart';

/// Confirmation screen shown after a postpay booking is created or a prepay
/// booking's payment has been verified by the backend.
class BookingSuccessScreen extends StatelessWidget {
  final BookingConfirmation confirmation;

  const BookingSuccessScreen({super.key, required this.confirmation});

  @override
  Widget build(BuildContext context) {
    final appointment = confirmation.appointment;
    final request = confirmation.request;
    final selection = confirmation.selection;
    final paymentLabel = AppointmentStatusStyle.paymentLabel(appointment.paymentStatus);
    final paid = AppointmentStatusStyle.isPaid(appointment.paymentStatus);
    final amount = Money.fromPaiseOrNull(confirmation.amountPaise);

    final headline = confirmation.isPrepaid ? 'Payment successful' : 'Booking confirmed';
    final subline = confirmation.isPrepaid
        ? 'Your appointment is confirmed and your payment has been verified.'
        : 'Your appointment is booked. Pay your physiotherapist after the consultation.';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/appointments');
      },
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            physics: const BouncingScrollPhysics(),
            children: [
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: const BoxDecoration(
                      gradient: AppColors.brandGradient,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Color(0x440891B2), blurRadius: 24, offset: Offset(0, 8))],
                    ),
                    child: const Icon(LucideIcons.check, color: Colors.white, size: 44),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(headline, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                subline,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.5, color: AppColors.bodyText, height: 1.4),
              ),
              const SizedBox(height: 24),
              InfoCard(
                title: 'Appointment',
                icon: LucideIcons.calendarCheck,
                trailing: StatusPill(
                  label: AppointmentStatusStyle.statusLabel(appointment.status),
                  color: AppointmentStatusStyle.statusColor(appointment.status),
                ),
                child: Column(
                  children: [
                    DetailRow(
                      label: 'Appointment ID',
                      value: appointment.id,
                      trailing: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: appointment.id));
                          showAppSnack(context, 'Appointment ID copied');
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            LucideIcons.fileText,
                            size: 16,
                            color: AppColors.primary,
                            semanticLabel: 'Copy ID',
                          ),
                        ),
                      ),
                    ),
                    DetailRow(label: 'Doctor', value: appointment.doctorName ?? selection.doctor.name),
                    DetailRow(label: 'Date', value: IstTime.displayDate(selection.date)),
                    DetailRow(label: 'Time slot', value: '${selection.slot} IST'),
                    DetailRow(label: 'Consultation', value: selection.mode.label),
                    if (selection.mode == ConsultationMode.home && request.address != null)
                      DetailRow(label: 'Visit address', value: request.address!.display),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              InfoCard(
                title: 'Patient',
                icon: LucideIcons.user,
                child: Column(
                  children: [
                    DetailRow(label: 'Name', value: request.patientName),
                    DetailRow(
                      label: 'Booked for',
                      value: request.patientRelation == PatientRelation.self ? 'Self' : 'Family member',
                    ),
                    DetailRow(label: 'Phone', value: request.patientPhone),
                    DetailRow(label: 'Email', value: request.patientEmail),
                    DetailRow(
                      label: 'Details',
                      value:
                          '${request.patientGender.label}, ${request.patientAge} yrs, '
                          '${request.patientWeight} kg, ${request.patientHeight} cm',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              InfoCard(
                title: 'Payment',
                icon: LucideIcons.wallet,
                trailing: StatusPill(
                  label: paymentLabel,
                  color: paid ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                ),
                child: Column(
                  children: [
                    DetailRow(
                      label: 'Method',
                      value: confirmation.isPrepaid ? 'Paid online (Razorpay)' : 'Pay after consultation',
                    ),
                    DetailRow(
                      label: paid ? 'Amount paid' : 'Amount payable',
                      value: amount ?? 'As per doctor’s fee',
                      emphasize: amount != null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryActionButton(
                label: 'View My Appointments',
                icon: LucideIcons.calendar,
                onPressed: () => context.go('/appointments'),
              ),
              const SizedBox(height: 10),
              SecondaryActionButton(label: 'Return Home', icon: LucideIcons.home, onPressed: () => context.go('/')),
            ],
          ),
        ),
      ),
    );
  }
}
