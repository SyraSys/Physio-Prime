import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fluid_pressable.dart';
import '../../../core/widgets/frosted_glass.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/appointment_model.dart';
import '../providers/appointments_provider.dart';
import 'widgets/appointment_card.dart';

/// My Appointments: Upcoming / Completed / Cancelled tabs backed by
/// `GET /appointments`.
class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  AppointmentGroup _tab = AppointmentGroup.upcoming;

  Future<void> _refresh() async {
    ref.invalidate(appointmentsProvider);
    try {
      await ref.read(appointmentsProvider.future);
    } catch (_) {
      // Error state is rendered by the list.
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateProvider.select((s) => s.status));
    final signedIn = ref.read(authRepositoryProvider).isAuthenticated;
    final topPadding = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FrostedGlassAppBar(
        title: const Text('My Appointments'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FluidPressable(
              onTap: () => context.go('/doctors'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.plus, size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Book',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: !signedIn
          ? Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: const SignInPromptView(
                title: 'Sign in to see your appointments',
                message: 'Book, reschedule and join video consultations from one place.',
              ),
            )
          : _buildSignedIn(topPadding),
    );
  }

  Widget _buildSignedIn(double topPadding) {
    final all = ref.watch(appointmentsProvider);
    final counts = <AppointmentGroup, int>{
      for (final g in AppointmentGroup.values) g: all.value?.where((a) => a.group == g).length ?? 0,
    };
    final tabData = ref.watch(appointmentsByGroupProvider(_tab));

    return RefreshIndicator(
      color: AppColors.primary,
      edgeOffset: topPadding,
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 12),
            sliver: SliverToBoxAdapter(
              child: _SegmentedTabs(
                selected: _tab,
                counts: all.hasValue ? counts : null,
                onChanged: (g) => setState(() => _tab = g),
              ),
            ),
          ),
          ...tabData.when(
            skipLoadingOnRefresh: true,
            loading: () => [
              const SliverFillRemaining(hasScrollBody: false, child: LoadingView(message: 'Loading appointments…')),
            ],
            error: (e, _) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorView(error: e, onRetry: _refresh),
              ),
            ],
            data: (items) {
              if (items.isEmpty) {
                return [SliverFillRemaining(hasScrollBody: false, child: _EmptyTab(group: _tab))];
              }
              return [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => AppointmentCard(appointment: items[i]),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final AppointmentGroup selected;
  final Map<AppointmentGroup, int>? counts;
  final ValueChanged<AppointmentGroup> onChanged;

  const _SegmentedTabs({required this.selected, required this.counts, required this.onChanged});

  String _label(AppointmentGroup g) {
    final base = switch (g) {
      AppointmentGroup.upcoming => 'Upcoming',
      AppointmentGroup.completed => 'Completed',
      AppointmentGroup.cancelled => 'Cancelled',
    };
    final c = counts?[g];
    return c == null || c == 0 ? base : '$base ($c)';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          for (final g in AppointmentGroup.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: g == selected,
                child: GestureDetector(
                  onTap: () => onChanged(g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: g == selected ? AppColors.primaryGradient : null,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _label(g),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: g == selected ? Colors.white : AppColors.bodyText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final AppointmentGroup group;
  const _EmptyTab({required this.group});

  @override
  Widget build(BuildContext context) {
    switch (group) {
      case AppointmentGroup.upcoming:
        return EmptyStateView(
          icon: LucideIcons.calendar,
          title: 'No upcoming appointments',
          message: 'Book a home visit or video consultation with a verified physiotherapist.',
          actionLabel: 'Find a physiotherapist',
          onAction: () => context.go('/doctors'),
        );
      case AppointmentGroup.completed:
        return const EmptyStateView(
          icon: LucideIcons.checkCircle,
          title: 'No completed sessions yet',
          message: 'Completed consultations will appear here so you can review them.',
        );
      case AppointmentGroup.cancelled:
        return const EmptyStateView(
          icon: LucideIcons.calendarX,
          title: 'No cancelled appointments',
          message: 'Appointments you cancel will be listed here.',
        );
    }
  }
}
