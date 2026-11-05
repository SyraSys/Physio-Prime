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

    // Developer 2 Hand-off Placeholder
    GoRoute(
      path: '/booking-slots',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra is Map<String, dynamic> ? state.extra as Map<String, dynamic> : {};
        return Scaffold(
          appBar: AppBar(title: const Text('Select Booking Slot')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.calendar, size: 56, color: Colors.cyan),
                  const SizedBox(height: 16),
                  Text('Slot Picker: ${extra['doctorName'] ?? 'Doctor'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Developer 2 will implement the dynamic slot selection and Razorpay checkout engine here.', textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
      },
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
