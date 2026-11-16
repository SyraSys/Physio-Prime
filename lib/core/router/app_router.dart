import 'dart:ui';
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
import '../../features/content/presentation/static_pages.dart';
import '../../features/appointments/presentation/appointments_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/appointments/domain/appointment_model.dart';
import '../../features/appointments/presentation/appointment_detail_screen.dart';
import '../../features/booking/domain/booking_request_model.dart';
import '../../features/booking/domain/booking_response_model.dart';
import '../../features/booking/presentation/booking_checkout_screen.dart';
import '../../features/booking/presentation/booking_slots_screen.dart';
import '../../features/booking/presentation/booking_success_screen.dart';
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
      path: '/profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileScreen(),
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
        return BookingSlotsScreen(doctor: doctor);
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
    if (location.startsWith('/doctors')) return 1;
    if (location.startsWith('/appointments')) return 2;
    if (location.startsWith('/dashboard')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/doctors');
        break;
      case 2:
        context.go('/appointments');
        break;
      case 3:
        context.go('/dashboard');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xE6FFFFFF), // 90% translucent white
              border: Border(
                top: BorderSide(color: Color(0x14000000), width: 0.5),
              ),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              indicatorColor: const Color(0x1F0891B2),
              selectedIndex: _calculateSelectedIndex(context),
              onDestinationSelected: (idx) => _onItemTapped(idx, context),
              destinations: const [
                NavigationDestination(
                  icon: Icon(LucideIcons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(LucideIcons.stethoscope),
                  label: 'Doctors',
                ),
                NavigationDestination(
                  icon: Icon(LucideIcons.calendar),
                  label: 'Appointments',
                ),
                NavigationDestination(
                  icon: Icon(LucideIcons.user),
                  label: 'Dashboard',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
