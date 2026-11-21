import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/frosted_glass.dart';

/// Clean iOS-styled Section Card for Legal & Compliance documents
class _LegalSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> bulletPoints;
  final String? leadText;

  const _LegalSectionCard({
    required this.title,
    required this.icon,
    required this.bulletPoints,
    this.leadText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF8FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          if (leadText != null) ...[
            const SizedBox(height: 12),
            Text(
              leadText!,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: const Color(0xFF475569),
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Column(
            children: bulletPoints.map((pt) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 10),
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        pt,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF334155),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 1. Privacy Policy Screen (`/privacy`)
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: FrostedGlassAppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.paddingOf(context).top + kToolbarHeight + 16,
          20,
          40,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCCFBF1)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HIPAA & DPDP Act Compliant',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Last updated: November 2026 · PhysioPrime Healthcare Network',
                        style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _LegalSectionCard(
            title: '1. Information We Collect',
            icon: LucideIcons.fileText,
            leadText: 'PhysioPrime collects patient information strictly necessary to provide clinical musculoskeletal assessment and safe physiotherapy care:',
            bulletPoints: [
              'Demographic & contact info (Full name, phone number, email address, age, gender).',
              'Home visit dispatch coordinates and street address for home consultations.',
              'Clinical concerns, symptoms, pain severity, and mobility limitations provided during booking.',
              'Digital prescriptions, session notes, and exercise regimes generated by your licensed physiotherapist.',
            ],
          ),
          const _LegalSectionCard(
            title: '2. Clinical Video & Audio Data',
            icon: LucideIcons.video,
            leadText: 'Online teleconsultations operate on encrypted 8x8 JaaS WebRTC medical channels:',
            bulletPoints: [
              'Live video feeds are ephemeral and encrypted in transit.',
              'No audio or video recordings are captured or stored on servers without express written clinical consent.',
              'Camera and microphone permissions are only active while you are in an ongoing session.',
            ],
          ),
          const _LegalSectionCard(
            title: '3. Financial & Payment Data',
            icon: LucideIcons.creditCard,
            leadText: 'Online transactions are processed via RBI-authorized payment aggregator Razorpay:',
            bulletPoints: [
              'PhysioPrime never sees, handles, or stores debit/credit card numbers or UPI PINs.',
              'We only store the Razorpay payment ID and order ID for appointment reconciliation and audit records.',
            ],
          ),
          const _LegalSectionCard(
            title: '4. Your Data Rights & Account Deletion',
            icon: LucideIcons.userCheck,
            bulletPoints: [
              'You retain complete ownership over your personal medical records and digital prescriptions.',
              'In accordance with Apple App Store guidelines and the DPDP Act, you can permanently delete your account, patient profile, and stored records at any time from Profile → Privacy & Security.',
              'For privacy inquiries or compliance data exports, contact care@physio-prime.in.',
            ],
          ),
        ],
      ),
    );
  }
}

/// 2. Terms of Service Screen (`/terms`)
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: FrostedGlassAppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(
          'Terms of Service',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.paddingOf(context).top + kToolbarHeight + 16,
          20,
          40,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCCFBF1)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.checkCircle2, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient Service Agreement',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Governs appointments, cancellations, and treatment standards.',
                        style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _LegalSectionCard(
            title: '1. Services Offered',
            icon: LucideIcons.activity,
            bulletPoints: [
              'PhysioPrime provides doorstep home visit physiotherapy sessions across covered metropolitan locations and video consultations nationwide across India.',
              'All consultations are conducted by licensed physiotherapists verified against state councils.',
            ],
          ),
          const _LegalSectionCard(
            title: '2. Booking, Capacity & Unpaid Holds',
            icon: LucideIcons.calendar,
            bulletPoints: [
              'Appointments are scheduled in 1-hour time windows in Indian Standard Time (IST).',
              'Unpaid online prepay bookings are held temporarily for 15 minutes before the slot capacity is released back to the clinical schedule.',
              'For home visits, patients must provide an accurate address within the active doctor’s service coverage area.',
            ],
          ),
          const _LegalSectionCard(
            title: '3. Rescheduling & Cancellation Policy',
            icon: LucideIcons.clock,
            bulletPoints: [
              'Patients may reschedule an upcoming appointment up to 4 hours prior to the slot window at no additional charge.',
              'Cancellations requested before the dispatch window are eligible for refund/credit according to PhysioPrime refund terms.',
              'Late cancellations after the clinician has departed for a home visit or joined the video room are non-refundable.',
            ],
          ),
          const _LegalSectionCard(
            title: '4. Non-Emergency Medical Disclaimer',
            icon: LucideIcons.alertCircle,
            bulletPoints: [
              'PhysioPrime is an elective rehabilitation and musculoskeletal physiotherapy platform.',
              'If you are experiencing acute chest pain, sudden numbness, uncontrolled bleeding, or severe head trauma, call national emergency services (112 / 108) immediately.',
            ],
          ),
        ],
      ),
    );
  }
}

/// 3. Clinical & Council Compliance Screen (`/compliance`)
class ComplianceScreen extends StatelessWidget {
  const ComplianceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: FrostedGlassAppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(
          'Clinical Compliance',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.paddingOf(context).top + kToolbarHeight + 16,
          20,
          40,
        ),
        children: const [
          _LegalSectionCard(
            title: 'State OTPT Registration Verification',
            icon: LucideIcons.award,
            leadText: 'Every practitioner on the PhysioPrime network is verified against their respective State Council of Occupational and Physiotherapy (OTPT):',
            bulletPoints: [
              'Mandatory verification of B.P.T / M.P.T degrees from accredited medical universities.',
              'Council registration numbers and good standing certified prior to onboarding.',
              'Continuous peer audits and patient clinical outcome tracking.',
            ],
          ),
          _LegalSectionCard(
            title: 'Portable Clinical Equipment Protocols',
            icon: LucideIcons.briefcase,
            leadText: 'Home visit specialists carry medical-grade, sanitized rehabilitation equipment:',
            bulletPoints: [
              'Pre-calibrated digital electrotherapy units (IFT, TENS, and Therapeutic Ultrasound).',
              'Hospital-grade surface sanitization of exercise bands, goniometers, and tapping equipment between every patient visit.',
              'Strict adherence to contactless digital health summaries and digital prescriptions.',
            ],
          ),
          _LegalSectionCard(
            title: 'Telemedicine Practice Guidelines',
            icon: LucideIcons.smartphone,
            bulletPoints: [
              'Strict compliance with the National Medical Commission (NMC) Telemedicine Practice Guidelines.',
              'Mandatory patient identity verification before issuing exercise prescriptions.',
              'Doctor-patient confidentiality protected via end-to-end encrypted session keys.',
            ],
          ),
        ],
      ),
    );
  }
}

/// 4. Patient Recovery Guides Screen (`/guides/patients`)
class PatientGuidesScreen extends StatelessWidget {
  const PatientGuidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: FrostedGlassAppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(
          'Patient Recovery Guides',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.paddingOf(context).top + kToolbarHeight + 16,
          20,
          40,
        ),
        children: [
          _buildGuideCard(
            context,
            icon: LucideIcons.home,
            title: 'Preparing for Your Home Visit',
            description: 'Ensure a clean, well-ventilated space with a firm bed or mat. Wear loose, comfortable athletic clothing allowing free joint mobility. Keep any recent X-ray or MRI reports handy.',
            badge: 'Home Care',
          ),
          const SizedBox(height: 14),
          _buildGuideCard(
            context,
            icon: LucideIcons.video,
            title: 'Joining an HD Video Consultation',
            description: 'Connect 5 minutes before your slot from a quiet, well-lit room. Position your phone or laptop camera so your physiotherapist can clearly observe your posture, gait, and spinal alignment.',
            badge: 'Telehealth',
          ),
          const SizedBox(height: 14),
          _buildGuideCard(
            context,
            icon: LucideIcons.activity,
            title: 'Post-Session Recovery & Ergonomics',
            description: 'Follow your digital prescription carefully. Avoid high-impact strains for 2 hours following manual therapy or electrotherapy. Hydrate well and maintain ergonomic desk posture.',
            badge: 'Ergonomics',
          ),
          const SizedBox(height: 14),
          _buildGuideCard(
            context,
            icon: LucideIcons.fileText,
            title: 'Accessing Digital Prescriptions',
            description: 'Your physiotherapist uploads your customized recovery protocol and exercise regimen immediately after your session. View them under Profile → Digital Prescriptions or in your Dashboard.',
            badge: 'Prescriptions',
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF8FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCCFBF1)),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: const Color(0xFF475569),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
