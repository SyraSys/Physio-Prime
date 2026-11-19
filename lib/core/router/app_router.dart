import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../features/home/domain/category_model.dart';
import '../../features/home/domain/symptom_model.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/category_detail_screen.dart';
import '../../features/home/presentation/condition_detail_screen.dart';
import '../../features/doctors/domain/doctor_model.dart';
import '../../features/doctors/presentation/doctors_screen.dart';
import '../../features/doctors/presentation/doctor_detail_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/content/presentation/caretaker_modal.dart';
import '../../features/content/presentation/careers_screen.dart';
import '../../features/content/presentation/blog_list_screen.dart';
import '../../features/content/presentation/blog_detail_screen.dart';
import '../../features/content/presentation/legal_screens.dart';
import '../../features/content/presentation/static_pages.dart';
import '../../features/appointments/presentation/appointments_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/appointments/domain/appointment_model.dart';
import '../../features/appointments/presentation/appointment_detail_screen.dart';
import '../../features/booking/domain/booking_request_model.dart';
import '../../features/booking/domain/booking_response_model.dart';
import '../../features/booking/presentation/booking_checkout_screen.dart';
import '../../features/booking/presentation/booking_success_screen.dart';
import '../../features/booking/presentation/booking_menu_screen.dart';
import '../../features/booking/presentation/booking_wizard_screen.dart';
import '../../features/dashboard/presentation/notifications_screen.dart';
import '../../features/dashboard/presentation/prescriptions_screen.dart';
import '../../features/telehealth/presentation/video_call_screen.dart';
import '../widgets/state_views.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/bookings',
          builder: (context, state) => const BookingMenuScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/doctors',
          builder: (context, state) => const DoctorsScreen(),
        ),
        GoRoute(
          path: '/appointments',
          builder: (context, state) => const AppointmentsScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
      ],
    ),

    // Developer 1 Modal & Deep Routes
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/categories/:slug',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final slug = state.pathParameters['slug'] ?? '';
        final cat = state.extra is CategoryModel ? state.extra as CategoryModel : null;
        return CategoryDetailScreen(slug: slug, category: cat);
      },
    ),
    GoRoute(
      path: '/conditions/:slug',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final slug = state.pathParameters['slug'] ?? '';
        final sym = state.extra is SymptomModel ? state.extra as SymptomModel : null;
        return ConditionDetailScreen(slug: slug, symptom: sym);
      },
    ),
    GoRoute(
      path: '/doctor/:slug',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final slug = state.pathParameters['slug'] ?? '';
        final doc = state.extra is DoctorModel ? state.extra as DoctorModel : null;
        return DoctorDetailScreen(slug: slug, doctor: doc);
      },
    ),
    GoRoute(
      path: '/caretaker',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CaretakerScreen(),
    ),
    GoRoute(
      path: '/careers',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CareersScreen(),
    ),
    GoRoute(
      path: '/blog',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BlogListScreen(),
    ),
    GoRoute(
      path: '/blog/:slug',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final slug = state.pathParameters['slug'] ?? '';
        final extra = state.extra is Map<String, dynamic> ? state.extra as Map<String, dynamic> : null;
        return BlogDetailScreen(slug: slug, initialData: extra);
      },
    ),
    GoRoute(
      path: '/about',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: '/how-it-works',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const HowItWorksScreen(),
    ),
    GoRoute(
      path: '/pricing',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PricingScreen(),
    ),
    GoRoute(
      path: '/privacy',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/terms',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TermsOfServiceScreen(),
    ),
    GoRoute(
      path: '/compliance',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ComplianceScreen(),
    ),
    GoRoute(
      path: '/guides/patients',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PatientGuidesScreen(),
    ),

    // Complete 4-Step Booking Wizard (Condition -> Doctor -> Schedule -> Confirm)
    GoRoute(
      path: '/booking-flow',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra;
        int step = 1;
        SymptomModel? condition;
        String? conditionName;
        DoctorModel? doctor;
        BookingDoctorInfo? doctorInfo;
        ConsultationMode mode = ConsultationMode.home;

        if (extra is Map) {
          step = (extra['initialStep'] as int?) ?? (extra['step'] as int?) ?? 1;
          if (extra['condition'] is SymptomModel) condition = extra['condition'] as SymptomModel;
          conditionName = extra['conditionName']?.toString();
          if (extra['doctor'] is DoctorModel) doctor = extra['doctor'] as DoctorModel;
          if (extra['doctorInfo'] is BookingDoctorInfo) doctorInfo = extra['doctorInfo'] as BookingDoctorInfo;
          mode = ConsultationMode.tryParse(extra['mode']?.toString()) ?? ConsultationMode.home;
        } else if (extra is SymptomModel) {
          condition = extra;
          step = 2;
        } else if (extra is DoctorModel) {
          doctor = extra;
          step = 3;
        } else if (extra is BookingDoctorInfo) {
          doctorInfo = extra;
          step = 3;
        }

        return BookingWizardScreen(
          initialStep: step,
          initialCondition: condition,
          initialConditionName: conditionName,
          initialDoctor: doctor,
          initialDoctorInfo: doctorInfo,
          initialMode: mode,
        );
      },
    ),

    // Developer 2: Booking, Payments, Appointments, Telehealth & Dashboard
    GoRoute(
      path: '/booking-slots',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final doctor = BookingDoctorInfo.fromRouteArgs(state.extra, state.uri.queryParameters);
        if (doctor == null) {
          return const MissingRouteDataScreen(
            title: 'Select a Slot',
            message: 'Please choose a physiotherapist first, then tap "Book Consultation Slot".',
          );
        }
        return BookingWizardScreen(
          initialStep: 3,
          initialDoctorInfo: doctor,
          initialMode: doctor.initialMode,
        );
      },
    ),
    GoRoute(
      path: '/booking-checkout',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final selection = state.extra;
        if (selection is! BookingSelection) {
          return const MissingRouteDataScreen(title: 'Checkout');
        }
        return BookingCheckoutScreen(selection: selection);
      },
    ),
    GoRoute(
      path: '/booking-success',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final confirmation = state.extra;
        if (confirmation is! BookingConfirmation) {
          return const MissingRouteDataScreen(
            title: 'Booking',
            message: 'Your booking details are available under My Appointments.',
          );
        }
        return BookingSuccessScreen(confirmation: confirmation);
      },
    ),
    GoRoute(
      path: '/appointment-detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra;
        final initial = extra is AppointmentModel ? extra : null;
        final id = initial?.id ??
            (extra is String ? extra : null) ??
            state.uri.queryParameters['id'];
        if (id == null || id.isEmpty) {
          return const MissingRouteDataScreen(title: 'Appointment Details');
        }
        return AppointmentDetailScreen(appointmentId: id, initial: initial);
      },
    ),
    GoRoute(
      path: '/video-call',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra;
        final map = extra is Map ? extra : const {};
        final id = (map['appointmentId'] ?? (extra is String ? extra : null) ?? state.uri.queryParameters['appointmentId'])
            ?.toString();
        if (id == null || id.isEmpty) {
          return const MissingRouteDataScreen(title: 'Video Consultation');
        }
        return VideoCallScreen(appointmentId: id, doctorName: map['doctorName']?.toString());
      },
    ),
    GoRoute(
      path: '/prescriptions',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PrescriptionsScreen(),
    ),
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationsScreen(),
    ),
  ],
);

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNavBar({required this.child, super.key});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/bookings') || location.startsWith('/appointments')) return 1;
    if (location.startsWith('/history') || location.startsWith('/dashboard')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/bookings');
        break;
      case 2:
        context.go('/history');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF8FAFB),
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140F172A),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _NavBarItem(
                      icon: LucideIcons.home,
                      label: 'Home',
                      isSelected: selectedIndex == 0,
                      onTap: () => _onItemTapped(0, context),
                    ),
                    _NavBarItem(
                      icon: LucideIcons.calendar,
                      label: 'Bookings',
                      isSelected: selectedIndex == 1,
                      onTap: () => _onItemTapped(1, context),
                    ),
                    _NavBarItem(
                      icon: LucideIcons.messageSquare,
                      label: 'History',
                      isSelected: selectedIndex == 2,
                      onTap: () => _onItemTapped(2, context),
                    ),
                    _NavBarItem(
                      icon: LucideIcons.user,
                      label: 'Profile',
                      isSelected: selectedIndex == 3,
                      onTap: () => _onItemTapped(3, context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Container(
                  width: 134,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(2.5),
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

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF0891B2);
    const inactiveColor = Color(0xFF94A3B8);
    final color = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 22,
              height: 2.5,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
