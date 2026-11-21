import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../features/home/domain/category_model.dart';
import '../../features/home/domain/symptom_model.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/category_detail_screen.dart';
import '../../features/home/presentation/condition_detail_screen.dart';
import '../../features/home/presentation/conditions_screen.dart';
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
import '../../features/splash/presentation/splash_screen.dart';
import 'router_state.dart';
import '../widgets/state_views.dart';

export 'router_state.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  redirect: (context, state) {
    final isSplash = state.matchedLocation == '/splash';
    if (!isAppInitialized) {
      if (!isSplash) {
        final loc = state.matchedLocation;
        return (loc.isEmpty || loc == '/')
            ? '/splash'
            : '/splash?from=${Uri.encodeComponent(loc)}';
      }
      return null;
    }
    // If already initialized and route is /splash without explicit force, return home
    if (isSplash && state.uri.queryParameters['force'] != 'true') {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final target = state.uri.queryParameters['from'];
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: SplashScreen(targetLocation: target),
          transitionDuration: const Duration(milliseconds: 320),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
        );
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/bookings',
              builder: (context, state) => const BookingMenuScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/doctors',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DoctorsScreen(),
    ),
    GoRoute(
      path: '/appointments',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AppointmentsScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      redirect: (context, state) => '/',
    ),
    GoRoute(
      path: '/auth-callback',
      redirect: (context, state) => '/',
    ),

    // Developer 1 Modal & Deep Routes (Smooth Apple iOS Bottom Sheet Entrance)
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildModalPage(
        state: state,
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/register',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildModalPage(
        state: state,
        child: const RegisterScreen(),
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildModalPage(
        state: state,
        child: const ForgotPasswordScreen(),
      ),
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
      path: '/conditions',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ConditionsScreen(),
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
      pageBuilder: (context, state) => _buildModalPage(
        state: state,
        child: const CaretakerScreen(),
      ),
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

/// Modal presentation transition builder: bottom-sheet slide up with subtle fade.
Page<dynamic> _buildModalPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.15),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: FadeTransition(
          opacity: curvedAnimation,
          child: child,
        ),
      );
    },
  );
}

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = navigationShell.currentIndex;

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF8FAFB),
      // Stateful IndexedStack preserves all screen instances, scroll offsets,
      // and state, enabling instant 0ms switching with zero jank or rebuild overhead.
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: RepaintBoundary(
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(33),
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
                    onTap: () => _onItemTapped(0),
                  ),
                  _NavBarItem(
                    icon: LucideIcons.calendar,
                    label: 'Bookings',
                    isSelected: selectedIndex == 1,
                    onTap: () => _onItemTapped(1),
                  ),
                  _NavBarItem(
                    icon: LucideIcons.messageSquare,
                    label: 'History',
                    isSelected: selectedIndex == 2,
                    onTap: () => _onItemTapped(2),
                  ),
                  _NavBarItem(
                    icon: LucideIcons.user,
                    label: 'Profile',
                    isSelected: selectedIndex == 3,
                    onTap: () => _onItemTapped(3),
                  ),
                ],
              ),
            ),
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 21,
                color: color,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 20,
                height: 2.5,
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
