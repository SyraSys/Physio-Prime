import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fluid_pressable.dart';
import '../../../core/widgets/frosted_glass.dart';
import '../../appointments/domain/appointment_model.dart';
import '../../appointments/providers/appointments_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../home/providers/home_provider.dart';
import '../domain/user_model.dart';
import '../providers/auth_provider.dart';

/// Redesigned Patient Profile Screen matching DESIGN.md specification
/// Features high-clarity typography (Plus Jakarta Sans & Inter), soft organic elevation,
/// clinical health stats, grouped Apple-style settings cards, and direct care concierge.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _launchExternalUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open $urlString')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open link on this device')),
        );
      }
    }
  }

  void _showEditProfileSheet(BuildContext context, UserModel user) {
    final nameController = TextEditingController(text: user.fullName ?? '');
    final phoneController = TextEditingController(text: user.phone ?? '');
    bool isSaving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x260F172A),
                    blurRadius: 28,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Sheet Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF8FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.userCheck, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Edit Patient Profile',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Full Name Input
                    Text(
                      'Full Name',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'Enter your full name',
                        hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                        prefixIcon: const Icon(LucideIcons.user, size: 18, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone Number Input
                    Text(
                      'Phone Number',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'e.g. +91 98765 43210',
                        hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                        prefixIcon: const Icon(LucideIcons.phone, size: 18, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Action Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                setSheetState(() => isSaving = true);
                                final scaffoldMessenger = ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(sheetContext);
                                final newName = nameController.text.trim();
                                final newPhone = phoneController.text.trim();
                                await ref.read(authStateProvider.notifier).updateProfile(
                                      fullName: newName.isNotEmpty ? newName : null,
                                      phone: newPhone.isNotEmpty ? newPhone : null,
                                    );
                                if (sheetContext.mounted) {
                                  navigator.pop();
                                }
                                if (mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Profile updated successfully!'),
                                      backgroundColor: Color(0xFF0D9488),
                                    ),
                                  );
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                'Save Changes',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Sign Out',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: Text(
            'Are you sure you want to sign out from PhysioPrime on this device?',
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signed out successfully')),
                  );
                }
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final topPadding = MediaQuery.paddingOf(context).top + kToolbarHeight;
    final isAuthenticated = authState.status == AuthStatus.authenticated && user != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8FAFB), // Exact bgPrimary from DESIGN.md
      appBar: FrostedGlassAppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          if (isAuthenticated)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Edit Profile',
                icon: const Icon(LucideIcons.edit3, size: 20, color: AppColors.primary),
                onPressed: () => _showEditProfileSheet(context, user),
              ),
            ),
        ],
      ),
      body: isAuthenticated
          ? _buildAuthenticatedContent(context, user, topPadding)
          : _buildGuestContent(context, topPadding),
    );
  }

  Widget _buildAuthenticatedContent(BuildContext context, UserModel user, double topPadding) {
    final appointments = ref.watch(appointmentsProvider).value ?? const <AppointmentModel>[];
    final completedCount = appointments.where((a) => a.isCompleted).length;
    final prescriptions = ref.watch(prescriptionsProvider).value ?? const [];
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final selectedCity = ref.watch(selectedCityProvider);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 120),
      children: [
        // 1. Patient Hero Card
        _PatientHeroCard(
          user: user,
          onEdit: () => _showEditProfileSheet(context, user),
        ),
        const SizedBox(height: 16),

        // 2. Health & Recovery Overview Strip
        _RecoveryStatsStrip(
          consultationsCount: completedCount,
          prescriptionsCount: prescriptions.length,
        ),
        const SizedBox(height: 24),

        // 3. Medical & Records Section
        _SectionLabel(title: 'Medical & Consultations'),
        const SizedBox(height: 8),
        _GroupedCard(
          children: [
            _ProfileNavTile(
              icon: LucideIcons.fileText,
              iconColor: const Color(0xFF0891B2),
              iconBgColor: const Color(0xFFEBF8FA),
              title: 'Prescriptions & Exercises',
              subtitle: 'Doctor rehabilitation notes and PDFs',
              badgeText: prescriptions.isNotEmpty ? '${prescriptions.length}' : null,
              onTap: () => context.push('/prescriptions'),
            ),
            const _TileDivider(),
            _ProfileNavTile(
              icon: LucideIcons.calendar,
              iconColor: const Color(0xFF0D9488),
              iconBgColor: const Color(0xFFE6FFFA),
              title: 'My Consultations',
              subtitle: 'Upcoming sessions and history',
              onTap: () => context.go('/appointments'),
            ),
            const _TileDivider(),
            _ProfileNavTile(
              icon: LucideIcons.stethoscope,
              iconColor: const Color(0xFF6366F1),
              iconBgColor: const Color(0xFFEEF2FF),
              title: 'Find & Book Physiotherapists',
              subtitle: 'Home visits & video teleconsultations',
              onTap: () => context.go('/doctors'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 4. Preferences & Location Section
        _SectionLabel(title: 'Preferences & City'),
        const SizedBox(height: 8),
        _GroupedCard(
          children: [
            _ProfileNavTile(
              icon: LucideIcons.bell,
              iconColor: const Color(0xFFF59E0B),
              iconBgColor: const Color(0xFFFEF3C7),
              title: 'Notifications & Alerts',
              subtitle: 'Appointment reminders & status updates',
              badgeText: unreadCount > 0 ? '$unreadCount new' : null,
              badgeColor: const Color(0xFFEF4444),
              onTap: () => context.push('/notifications'),
            ),
            const _TileDivider(),
            _ProfileNavTile(
              icon: LucideIcons.mapPin,
              iconColor: const Color(0xFF06B6D4),
              iconBgColor: const Color(0xFFCFFAFE),
              title: 'Service City',
              subtitle: 'Serving $selectedCity and surrounding areas',
              trailingWidget: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  selectedCity,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              onTap: () => context.go('/'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 5. Direct Care Concierge & Support Section
        _SectionLabel(title: 'PhysioPrime Care Concierge'),
        const SizedBox(height: 8),
        _GroupedCard(
          children: [
            _ProfileNavTile(
              icon: LucideIcons.messageCircle,
              iconColor: const Color(0xFF10B981),
              iconBgColor: const Color(0xFFECFDF5),
              title: 'Chat with Care Team',
              subtitle: 'Instant WhatsApp booking assistance',
              trailingIcon: LucideIcons.externalLink,
              onTap: () => _launchExternalUrl(ApiConstants.supportWhatsApp),
            ),
            const _TileDivider(),
            _ProfileNavTile(
              icon: LucideIcons.phoneCall,
              iconColor: const Color(0xFF0D9488),
              iconBgColor: const Color(0xFFE6FFFA),
              title: 'Call Patient Helpline',
              subtitle: ApiConstants.supportPhone,
              trailingIcon: LucideIcons.externalLink,
              onTap: () => _launchExternalUrl('tel:${ApiConstants.supportPhone}'),
            ),
            const _TileDivider(),
            _ProfileNavTile(
              icon: LucideIcons.mail,
              iconColor: const Color(0xFF64748B),
              iconBgColor: const Color(0xFFF1F5F9),
              title: 'Email Medical Support',
              subtitle: ApiConstants.supportEmail,
              trailingIcon: LucideIcons.externalLink,
              onTap: () => _launchExternalUrl('mailto:${ApiConstants.supportEmail}'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 6. About & Information
        _SectionLabel(title: 'About PhysioPrime'),
        const SizedBox(height: 8),
        _GroupedCard(
          children: [
            _ProfileNavTile(
              icon: LucideIcons.helpCircle,
              iconColor: const Color(0xFF0891B2),
              iconBgColor: const Color(0xFFEBF8FA),
              title: 'How It Works',
              subtitle: 'Our home visit & telehealth clinical protocols',
              onTap: () => context.push('/how-it-works'),
            ),
            const _TileDivider(),
            _ProfileNavTile(
              icon: LucideIcons.shieldCheck,
              iconColor: const Color(0xFF0D9488),
              iconBgColor: const Color(0xFFE6FFFA),
              title: 'Clinical Accreditation & Privacy',
              subtitle: 'Council-verified physiotherapists & data safety',
              onTap: () => context.push('/about'),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // 7. Sign Out Button
        FluidPressable(
          onTap: () => _showSignOutDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFEE2E2), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.logOut, size: 18, color: Color(0xFFDC2626)),
                const SizedBox(width: 8),
                Text(
                  'Sign Out of PhysioPrime',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // App Version Footer
        Center(
          child: Text(
            'PhysioPrime Mobile v1.0.0 (Build 2026.11)',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestContent(BuildContext context, double topPadding) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 120),
      children: [
        // Premium Guest Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo Monogram
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEBF8FA), Color(0xFFE0F7FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFB2EBF2), width: 1.5),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/pp_monogram.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                'Your Health Portal',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                'Sign in to manage your appointments, view digital prescriptions, follow exercise routines, and message your therapists.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),

              // Sign In CTA
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => context.push('/login'),
                  child: Text(
                    'Sign In / Create Account',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Explore Doctors Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => context.go('/doctors'),
                  child: Text(
                    'Browse Physiotherapists',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Why Register With PhysioPrime
        _SectionLabel(title: 'Patient Benefits'),
        const SizedBox(height: 10),
        _GroupedCard(
          children: const [
            _FeatureBenefitTile(
              icon: LucideIcons.home,
              title: 'Doorstep Physiotherapy',
              subtitle: 'Qualified physiotherapists visit your residence with electrotherapy modalities',
            ),
            _TileDivider(),
            _FeatureBenefitTile(
              icon: LucideIcons.fileCheck,
              title: 'Digital Prescriptions',
              subtitle: 'Review clinical exercise plans, posture guides, and progress notes anytime',
            ),
            _TileDivider(),
            _FeatureBenefitTile(
              icon: LucideIcons.video,
              title: 'HD Teleconsultation',
              subtitle: '1-on-1 secure virtual sessions with specialist orthopedic & neuro rehab physiotherapists',
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Patient Care Support
        _SectionLabel(title: 'Need Immediate Help?'),
        const SizedBox(height: 10),
        _GroupedCard(
          children: [
            _ProfileNavTile(
              icon: LucideIcons.messageCircle,
              iconColor: const Color(0xFF10B981),
              iconBgColor: const Color(0xFFECFDF5),
              title: 'Chat on WhatsApp',
              subtitle: 'Speak with our patient care coordinator',
              trailingIcon: LucideIcons.externalLink,
              onTap: () => _launchExternalUrl(ApiConstants.supportWhatsApp),
            ),
            const _TileDivider(),
            _ProfileNavTile(
              icon: LucideIcons.phoneCall,
              iconColor: const Color(0xFF0D9488),
              iconBgColor: const Color(0xFFE6FFFA),
              title: 'Direct Call Assistance',
              subtitle: ApiConstants.supportPhone,
              trailingIcon: LucideIcons.externalLink,
              onTap: () => _launchExternalUrl('tel:${ApiConstants.supportPhone}'),
            ),
          ],
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// Component Subwidgets
// -------------------------------------------------------------

class _PatientHeroCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;

  const _PatientHeroCard({required this.user, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final initials = (user.fullName != null && user.fullName!.trim().isNotEmpty)
        ? user.fullName!.trim()[0].toUpperCase()
        : (user.email.isNotEmpty ? user.email[0].toUpperCase() : 'P');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with subtle status ring
              Stack(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0891B2), Color(0xFF14B8A6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x260891B2),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0D9488),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.check, size: 10, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Name & Contact Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName ?? 'PhysioPrime Patient',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Phone or Add Phone Pill
                    if (user.phone != null && user.phone!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(LucideIcons.phone, size: 12, color: Color(0xFF0891B2)),
                          const SizedBox(width: 4),
                          Text(
                            user.phone!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0891B2),
                            ),
                          ),
                        ],
                      )
                    else
                      GestureDetector(
                        onTap: onEdit,
                        child: Text(
                          '+ Add Phone Number',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0891B2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Edit Button
              FluidPressable(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(LucideIcons.pencil, size: 16, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Verified Patient Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCCFBF1)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.shieldCheck, size: 15, color: Color(0xFF0D9488)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Registered & Verified PhysioPrime Patient',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F766E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryStatsStrip extends StatelessWidget {
  final int consultationsCount;
  final int prescriptionsCount;

  const _RecoveryStatsStrip({
    required this.consultationsCount,
    required this.prescriptionsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          title: 'Consultations',
          value: '$consultationsCount',
          icon: LucideIcons.calendarCheck,
          accentColor: const Color(0xFF0891B2),
        ),
        const SizedBox(width: 12),
        _StatCard(
          title: 'Prescriptions',
          value: '$prescriptionsCount',
          icon: LucideIcons.fileText,
          accentColor: const Color(0xFF0D9488),
        ),
        const SizedBox(width: 12),
        const _StatCard(
          title: 'Care Status',
          value: 'Active',
          icon: LucideIcons.heartHandshake,
          accentColor: Color(0xFF10B981),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x080F172A),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: accentColor),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class _GroupedCard extends StatelessWidget {
  final List<Widget> children;
  const _GroupedCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 56, right: 16),
      child: Divider(height: 1, thickness: 0.8, color: Color(0xFFF1F5F9)),
    );
  }
}

class _ProfileNavTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final IconData trailingIcon;
  final Widget? trailingWidget;
  final VoidCallback onTap;

  const _ProfileNavTile({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.badgeColor,
    this.trailingIcon = LucideIcons.chevronRight,
    this.trailingWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FluidPressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            // Leading Icon with soft pastel background
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 19, color: iconColor),
            ),
            const SizedBox(width: 14),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // Optional Badge
            if (badgeText != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor ?? const Color(0xFF0891B2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Trailing widget or Chevron
            trailingWidget ??
                Icon(
                  trailingIcon,
                  size: 16,
                  color: const Color(0xFF94A3B8),
                ),
          ],
        ),
      ),
    );
  }
}

class _FeatureBenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureBenefitTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF8FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
