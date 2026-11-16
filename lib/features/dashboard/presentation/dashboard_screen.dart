import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fluid_pressable.dart';
import '../../../core/widgets/frosted_glass.dart';
import '../../../core/widgets/state_views.dart';
import '../../appointments/domain/appointment_model.dart';
import '../../appointments/presentation/widgets/appointment_card.dart';
import '../../appointments/providers/appointments_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import 'notifications_screen.dart';
import 'prescriptions_screen.dart';

/// Patient dashboard: next appointment, recent activity, prescriptions,
/// notifications and shortcuts — all from live APIs.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(appointmentsProvider);
    ref.invalidate(prescriptionsProvider);
    await Future.wait<void>([
      ref.read(notificationsProvider.notifier).load(),
      ref.read(appointmentsProvider.future).then((_) {}, onError: (_) {}),
      ref.read(prescriptionsProvider.future).then((_) {}, onError: (_) {}),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final signedIn = ref.read(authRepositoryProvider).isAuthenticated;
    final topPadding = MediaQuery.paddingOf(context).top + kToolbarHeight;
    final unread = signedIn ? ref.watch(unreadNotificationsCountProvider) : 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FrostedGlassAppBar(
        title: const Text('My Health'),
        actions: [
          if (signedIn)
            IconButton(
              tooltip: unread > 0 ? '$unread unread notifications' : 'Notifications',
              onPressed: () => context.push('/notifications'),
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                backgroundColor: AppColors.error,
                child: const Icon(LucideIcons.bell),
              ),
            ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.push(signedIn ? '/profile' : '/login'),
            icon: const Icon(LucideIcons.user),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: !signedIn
          ? Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: const SignInPromptView(
                title: 'Your health dashboard',
                message: 'Sign in to track appointments, prescriptions and updates from your physiotherapist.',
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              edgeOffset: topPadding,
              onRefresh: () => _refresh(ref),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 120),
                children: [
                  _GreetingHeader(name: auth.user?.fullName),
                  const SizedBox(height: 18),
                  const _Shortcuts(),
                  const SizedBox(height: 24),
                  const _NextAppointmentSection(),
                  const SizedBox(height: 24),
                  const _RecentAppointmentsSection(),
                  const SizedBox(height: 24),
                  const _PrescriptionsSection(),
                  const SizedBox(height: 24),
                  const _NotificationsSection(),
                ],
              ),
            ),
    );
  }
}

class _GreetingHeader extends ConsumerWidget {
  final String? name;
  const _GreetingHeader({required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(appointmentsProvider).value ?? const <AppointmentModel>[];
    final upcoming = appointments.where((a) => a.isUpcoming).length;
    final completed = appointments.where((a) => a.isCompleted).length;
    final prescriptions = ref.watch(prescriptionsProvider).value?.length;
    final firstName = (name == null || name!.trim().isEmpty) ? null : name!.trim().split(' ').first;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x330891B2), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            firstName == null ? 'Welcome back' : 'Hello, $firstName',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4),
          ),
          const SizedBox(height: 4),
          const Text('Here’s your recovery at a glance.', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 18),
          Row(
            children: [
              _Stat(value: '$upcoming', label: 'Upcoming'),
              _Stat(value: '$completed', label: 'Completed'),
              _Stat(value: prescriptions == null ? '–' : '$prescriptions', label: 'Prescriptions'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Shortcuts extends StatelessWidget {
  const _Shortcuts();

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, VoidCallback)>[
      (LucideIcons.stethoscope, 'Book visit', () => context.go('/doctors')),
      (LucideIcons.calendar, 'Appointments', () => context.go('/appointments')),
      (LucideIcons.pill, 'Prescriptions', () => context.push('/prescriptions')),
      (LucideIcons.bell, 'Updates', () => context.push('/notifications')),
    ];
    return Row(
      children: [
        for (final item in items)
          Expanded(
            child: Semantics(
              button: true,
              label: item.$2,
              child: FluidPressable(
                onTap: item.$3,
                child: Column(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borderSoft),
                      ),
                      child: Icon(item.$1, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.headingText),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.headingText),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

class _NextAppointmentSection extends ConsumerWidget {
  const _NextAppointmentSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appointmentsByGroupProvider(AppointmentGroup.upcoming));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'Upcoming appointments',
          actionLabel: 'See all',
          onAction: () => context.go('/appointments'),
        ),
        async.when(
          skipLoadingOnRefresh: true,
          loading: () => const LoadingView(padding: EdgeInsets.all(16)),
          error: (e, _) => InfoCard(
            child: ErrorView(error: e, compact: true, onRetry: () => ref.invalidate(appointmentsProvider)),
          ),
          data: (items) => items.isEmpty
              ? InfoCard(
                  child: EmptyStateView(
                    icon: LucideIcons.calendarCheck,
                    title: 'No upcoming sessions',
                    message: 'Book your next physiotherapy session.',
                    actionLabel: 'Book now',
                    onAction: () => context.go('/doctors'),
                  ),
                )
              : Column(
                  children: [
                    for (final a in items.take(2)) ...[AppointmentCard(appointment: a), const SizedBox(height: 12)],
                  ],
                ),
        ),
      ],
    );
  }
}

class _RecentAppointmentsSection extends ConsumerWidget {
  const _RecentAppointmentsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(appointmentsProvider).value;
    if (list == null) return const SizedBox.shrink();
    final recent = list.where((a) => !a.isUpcoming).take(3).toList();
    if (recent.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'Recent appointments',
          actionLabel: 'History',
          onAction: () => context.go('/appointments'),
        ),
        for (final a in recent) ...[
          AppointmentCard(appointment: a, showActions: a.canReview),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _PrescriptionsSection extends ConsumerWidget {
  const _PrescriptionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(prescriptionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: 'Prescriptions', actionLabel: 'View all', onAction: () => context.push('/prescriptions')),
        async.when(
          skipLoadingOnRefresh: true,
          loading: () => const LoadingView(padding: EdgeInsets.all(16)),
          error: (e, _) => InfoCard(
            child: ErrorView(error: e, compact: true, onRetry: () => ref.invalidate(prescriptionsProvider)),
          ),
          data: (items) => items.isEmpty
              ? const InfoCard(
                  child: EmptyStateView(
                    icon: LucideIcons.clipboardList,
                    title: 'No prescriptions yet',
                    message: 'They will appear here after your consultation.',
                  ),
                )
              : Column(
                  children: [
                    for (final p in items.take(2)) ...[
                      PrescriptionCard(prescription: p, onTap: () => showPrescriptionDetail(context, p)),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _NotificationsSection extends ConsumerWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: unread > 0 ? 'Notifications ($unread new)' : 'Notifications',
          actionLabel: 'View all',
          onAction: () => context.push('/notifications'),
        ),
        async.when(
          skipLoadingOnRefresh: true,
          loading: () => const LoadingView(padding: EdgeInsets.all(16)),
          error: (e, _) => InfoCard(
            child: ErrorView(error: e, compact: true, onRetry: () => ref.read(notificationsProvider.notifier).load()),
          ),
          data: (items) => items.isEmpty
              ? const InfoCard(
                  child: EmptyStateView(icon: LucideIcons.bellOff, title: 'No notifications'),
                )
              : Column(
                  children: [
                    for (final n in items.take(3)) ...[NotificationTile(notification: n), const SizedBox(height: 8)],
                  ],
                ),
        ),
      ],
    );
  }
}
