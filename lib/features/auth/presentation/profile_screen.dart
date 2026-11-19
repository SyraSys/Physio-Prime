import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fluid_pressable.dart';
import '../../../core/widgets/frosted_glass.dart';
import '../../appointments/domain/appointment_model.dart';
import '../../appointments/providers/appointments_provider.dart';
import '../../dashboard/domain/prescription_model.dart';
import '../../dashboard/presentation/notifications_screen.dart';
import '../../dashboard/presentation/prescriptions_screen.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../domain/user_model.dart';
import '../providers/auth_provider.dart';

/// Redesigned Profile Screen conforming strictly to DESIGN.md and the web reference layout.
/// Features:
/// 1. Shared Patient Header Card (Avatar, Name, Patient Badge, Email, Completed & Upcoming Session counts).
/// 2. 4 Horizontal Segmented Tabs:
///    - Personal Profile (Account Details grid, Edit Profile, Sign Out)
///    - Digital Prescriptions (Digital EHR & Session Summaries)
///    - Notifications (Notifications & Activity)
///    - Privacy & Security (Change Account Password)
/// 3. 120px bottom padding to prevent overlap with the floating navigation bar.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _selectedTabIndex = 0;

  // Password controllers for Tab 3 (Privacy & Security)
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isUpdatingPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showEditProfileSheet(BuildContext context, UserModel user) {
    final nameController = TextEditingController(text: user.fullName ?? '');
    final phoneController = TextEditingController(text: user.phone ?? '');
    final genderController = TextEditingController(text: user.gender ?? '');
    final dobController = TextEditingController(text: user.dateOfBirth ?? '');
    final weightController = TextEditingController(text: user.weight ?? '');
    final heightController = TextEditingController(text: user.height ?? '');
    final addressController = TextEditingController(text: user.address ?? '');
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
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
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
                          'Edit Profile Details',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Full Name
                    _buildInputLabel('Full Name'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: nameController,
                      hint: 'Enter your full name',
                      icon: LucideIcons.user,
                    ),
                    const SizedBox(height: 14),

                    // Phone Number
                    _buildInputLabel('Phone Number'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: phoneController,
                      hint: '+91 98765 43210',
                      icon: LucideIcons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),

                    // Gender & Date of Birth
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('Gender'),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: genderController,
                                hint: 'Male / Female',
                                icon: LucideIcons.user,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('Date of Birth'),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: dobController,
                                hint: 'DD/MM/YYYY',
                                icon: LucideIcons.calendar,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Weight & Height
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('Weight'),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: weightController,
                                hint: 'e.g. 68 kg',
                                icon: LucideIcons.activity,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('Height'),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: heightController,
                                hint: 'e.g. 175 cm',
                                icon: LucideIcons.maximize2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Address
                    _buildInputLabel('Address'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: addressController,
                      hint: 'Residential address',
                      icon: LucideIcons.mapPin,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // Save Button
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

                                await ref.read(authStateProvider.notifier).updateProfile(
                                      fullName: nameController.text.trim().isNotEmpty
                                          ? nameController.text.trim()
                                          : null,
                                      phone: phoneController.text.trim().isNotEmpty
                                          ? phoneController.text.trim()
                                          : null,
                                      gender: genderController.text.trim().isNotEmpty
                                          ? genderController.text.trim()
                                          : null,
                                      dateOfBirth: dobController.text.trim().isNotEmpty
                                          ? dobController.text.trim()
                                          : null,
                                      weight: weightController.text.trim().isNotEmpty
                                          ? weightController.text.trim()
                                          : null,
                                      height: heightController.text.trim().isNotEmpty
                                          ? heightController.text.trim()
                                          : null,
                                      address: addressController.text.trim().isNotEmpty
                                          ? addressController.text.trim()
                                          : null,
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

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF475569),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
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

  Future<void> _handlePasswordUpdate() async {
    final currentPw = _currentPasswordController.text.trim();
    final newPw = _newPasswordController.text.trim();
    final confirmPw = _confirmPasswordController.text.trim();

    if (newPw.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be at least 8 characters long.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (newPw != confirmPw) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New passwords do not match.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isUpdatingPassword = true);
    final success = await ref.read(authStateProvider.notifier).changePassword(
          currentPassword: currentPw,
          newPassword: newPw,
        );
    if (!mounted) return;
    setState(() => _isUpdatingPassword = false);

    if (success) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully!'),
          backgroundColor: Color(0xFF0D9488),
        ),
      );
    } else {
      final err = ref.read(authStateProvider).errorMessage ?? 'Failed to update password.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
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
      ),
      body: isAuthenticated
          ? _buildAuthenticatedContent(context, user, topPadding)
          : _buildGuestContent(context, topPadding),
    );
  }

  Widget _buildGuestContent(BuildContext context, double topPadding) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFEBF8FA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.user, size: 30, color: AppColors.primary),
              ),
              const SizedBox(height: 18),
              Text(
                'Welcome to PhysioPrime',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to manage your appointments, view clinical prescriptions, and access your profile.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => context.push('/login'),
                  child: Text(
                    'Sign In / Register',
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
      ],
    );
  }

  Widget _buildAuthenticatedContent(BuildContext context, UserModel user, double topPadding) {
    final appointments = ref.watch(appointmentsProvider).value ?? const <AppointmentModel>[];
    final completedCount = appointments.where((a) => a.isCompleted).length;
    final upcomingCount = appointments.where((a) => a.isUpcoming).length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 120),
      children: [
        // 1. Shared Profile Header Card (Website Style)
        _buildProfileHeaderCard(user, completedCount, upcomingCount),
        const SizedBox(height: 16),

        // 2. Segmented Horizontal Tab Bar (4 Tabs)
        _buildSegmentedTabBar(),
        const SizedBox(height: 16),

        // 3. Tab Content Card
        IndexedStack(
          index: _selectedTabIndex,
          children: [
            _buildTabPersonalProfile(user),
            _buildTabDigitalPrescriptions(),
            _buildTabNotifications(),
            _buildTabPrivacySecurity(),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. PROFILE HEADER CARD (Matches website top profile card)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildProfileHeaderCard(UserModel user, int completedCount, int upcomingCount) {
    final initialLetter = (user.fullName?.isNotEmpty == true
            ? user.fullName![0]
            : (user.email.isNotEmpty ? user.email[0] : 'U'))
        .toUpperCase();

    final displayName = user.fullName?.isNotEmpty == true
        ? user.fullName!
        : (user.email.split('@').first.isNotEmpty ? user.email.split('@').first : 'User');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Avatar + Name + Patient Pill + Email
          Row(
            children: [
              // Avatar
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initialLetter,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F7FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFB2EBF2)),
                          ),
                          child: Text(
                            user.role?.isNotEmpty == true ? user.role! : 'Patient',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Two Stat Boxes in a row (Completed Sessions & Upcoming Sessions)
          Row(
            children: [
              Expanded(
                child: _buildHeaderStatBox(
                  title: 'Completed Sessions',
                  count: completedCount,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHeaderStatBox(
                  title: 'Upcoming Sessions',
                  count: upcomingCount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatBox({required String title, required int count}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA), // Very soft teal/mint
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCCFBF1)),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. SEGMENTED TAB BAR (Matches website 4-pill segmented buttons)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildSegmentedTabBar() {
    final tabs = [
      {'title': 'Personal Profile', 'icon': LucideIcons.user},
      {'title': 'Digital Prescriptions', 'icon': LucideIcons.fileText},
      {'title': 'Notifications', 'icon': LucideIcons.bell},
      {'title': 'Privacy & Security', 'icon': LucideIcons.shield},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          final tab = tabs[index];

          return Padding(
            padding: EdgeInsets.only(right: index == tabs.length - 1 ? 0 : 8),
            child: FluidPressable(
              onTap: () {
                setState(() => _selectedTabIndex = index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x330891B2),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 15,
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      tab['title'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. TAB 1: PERSONAL PROFILE ("Account Details")
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTabPersonalProfile(UserModel user) {
    final weightStr = user.weight?.isNotEmpty == true ? user.weight! : '—';
    final heightStr = user.height?.isNotEmpty == true ? user.height! : '—';
    final weightHeight = '$weightStr • $heightStr';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Title + Edit Profile Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Account Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              FluidPressable(
                onTap: () => _showEditProfileSheet(context, user),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.edit3, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Edit Profile',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 7 Account Details fields matching the website layout:
          // 1. Full Name
          _buildDetailCard(label: 'Full Name', value: user.fullName?.isNotEmpty == true ? user.fullName! : '—'),
          const SizedBox(height: 10),

          // 2. Email Address
          _buildDetailCard(label: 'Email Address', value: user.email.isNotEmpty ? user.email : '—'),
          const SizedBox(height: 10),

          // 3 & 4. Phone Number & Gender (Side by side on mobile)
          Row(
            children: [
              Expanded(
                child: _buildDetailCard(
                  label: 'Phone Number',
                  value: user.phone?.isNotEmpty == true ? user.phone! : '—',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDetailCard(
                  label: 'Gender',
                  value: user.gender?.isNotEmpty == true ? user.gender! : '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 5 & 6. Date of Birth & Weight / Height (Side by side on mobile)
          Row(
            children: [
              Expanded(
                child: _buildDetailCard(
                  label: 'Date of Birth',
                  value: user.dateOfBirth?.isNotEmpty == true ? user.dateOfBirth! : '—',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDetailCard(
                  label: 'Weight / Height',
                  value: weightHeight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 7. Address
          _buildDetailCard(
            label: 'Address',
            value: user.address?.isNotEmpty == true ? user.address! : '—',
          ),
          const SizedBox(height: 24),

          // Sign Out Button
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFECACA)),
                backgroundColor: const Color(0xFFFEF2F2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _showSignOutDialog(context),
              icon: const Icon(LucideIcons.logOut, size: 16, color: Color(0xFFEF4444)),
              label: Text(
                'Sign Out',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. TAB 2: DIGITAL PRESCRIPTIONS ("Digital EHR & Session Summaries")
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTabDigitalPrescriptions() {
    final async = ref.watch(prescriptionsProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Digital EHR & Session Summaries',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Official clinical notes, rehabilitation exercises, and prescriptions issued by your physiotherapists.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),

          async.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
              ),
            ),
            error: (_, _) => _buildEmptyPrescriptionsBox(),
            data: (prescriptions) {
              if (prescriptions.isEmpty) {
                return _buildEmptyPrescriptionsBox();
              }
              return Column(
                children: prescriptions.map((p) => _buildPrescriptionItem(p)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPrescriptionsBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(LucideIcons.fileText, size: 36, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 14),
          Text(
            'No prescriptions issued yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your session notes, prescribed exercises, and clinical summaries will appear here once your physiotherapist completes your consultation.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionItem(PrescriptionModel p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF8FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.fileText, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.diagnosis ?? 'Prescription Record',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (p.doctorName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Dr. ${p.doctorName}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: () => showPrescriptionDetail(context, p),
            child: Text(
              'View Details',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. TAB 3: NOTIFICATIONS ("Notifications & Activity")
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTabNotifications() {
    final async = ref.watch(notificationsProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Notifications & Activity',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Real-time updates for your bookings, sessions, and prescriptions.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),

          async.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
              ),
            ),
            error: (_, _) => _buildEmptyNotificationsBox(),
            data: (items) {
              if (items.isEmpty) {
                return _buildEmptyNotificationsBox();
              }
              return Column(
                children: items.map((item) => NotificationTile(notification: item)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNotificationsBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(LucideIcons.bell, size: 36, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 14),
          Text(
            "You're all caught up",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Booking confirmations and clinical updates will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 6. TAB 4: PRIVACY & SECURITY ("Privacy & Security Controls")
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTabPrivacySecurity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Privacy & Security Controls',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your health data is encrypted according to HIPAA and ISO-27001 medical standards.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),

          // Change Account Password Subheader
          Row(
            children: [
              const Icon(LucideIcons.key, size: 16, color: Color(0xFF0F172A)),
              const SizedBox(width: 8),
              Text(
                'Change Account Password',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Field 1: Current Password
          _buildPasswordLabel('Current Password *'),
          const SizedBox(height: 6),
          _buildPasswordField(
            controller: _currentPasswordController,
            hint: '••••••••',
            obscureText: _obscureCurrent,
            onToggleObscure: () => setState(() => _obscureCurrent = !_obscureCurrent),
          ),
          const SizedBox(height: 14),

          // Field 2: New Password
          _buildPasswordLabel('New Password *'),
          const SizedBox(height: 6),
          _buildPasswordField(
            controller: _newPasswordController,
            hint: 'At least 8 characters',
            obscureText: _obscureNew,
            onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 14),

          // Field 3: Confirm New Password
          _buildPasswordLabel('Confirm New Password *'),
          const SizedBox(height: 6),
          _buildPasswordField(
            controller: _confirmPasswordController,
            hint: '••••••••',
            obscureText: _obscureConfirm,
            onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          const SizedBox(height: 20),

          // Update Password Button
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isUpdatingPassword ? null : _handlePasswordUpdate,
              icon: _isUpdatingPassword
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(LucideIcons.key, size: 16, color: Colors.white),
              label: Text(
                _isUpdatingPassword ? 'Updating...' : 'Update Password',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 24),

          // iOS App Store Requirement: In-App Account Deletion
          Row(
            children: [
              const Icon(LucideIcons.alertTriangle, size: 16, color: Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Text(
                'Delete Account',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Permanently delete your PhysioPrime patient account, health profile, session history, and stored medical prescriptions. This action is irreversible.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: const Color(0xFFFEF2F2),
              ),
              onPressed: () => _confirmAccountDeletion(context),
              icon: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFEF4444)),
              label: Text(
                'Delete Account Permanently',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAccountDeletion(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogCtx) => CupertinoAlertDialog(
        title: const Text('Delete Account?'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'Are you sure you want to permanently delete your PhysioPrime account? All your medical appointments, prescriptions, and health records will be erased immediately. This cannot be undone.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(authStateProvider.notifier).deleteAccount();
      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Your account and personal health data have been deleted.'),
            backgroundColor: Color(0xFF0F172A),
          ),
        );
        router.go('/');
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to delete account. Please try again or contact support.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Widget _buildPasswordLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF475569),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? LucideIcons.eyeOff : LucideIcons.eye,
            size: 18,
            color: const Color(0xFF94A3B8),
          ),
          onPressed: onToggleObscure,
        ),
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
    );
  }
}
