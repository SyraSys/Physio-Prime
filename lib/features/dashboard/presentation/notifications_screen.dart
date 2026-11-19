import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ist_time.dart';
import '../../../core/widgets/frosted_glass.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/notification_model.dart';
import '../providers/dashboard_provider.dart';

/// Full notifications list with read/unread states and mark-as-read.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);
    final controller = ref.read(notificationsProvider.notifier);
    final topPadding = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FrostedGlassAppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () async {
                final error = await controller.markAllRead();
                if (error != null && context.mounted) showAppSnack(context, error, error: true);
              },
              child: const Text(
                'Mark all read',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        edgeOffset: topPadding,
        onRefresh: controller.load,
        child: async.when(
          skipLoadingOnRefresh: true,
          loading: () => ListView(
            padding: EdgeInsets.only(top: topPadding),
            children: const [LoadingView(message: 'Loading notifications…')],
          ),
          error: (e, _) => ListView(
            padding: EdgeInsets.only(top: topPadding),
            children: [ErrorView(error: e, onRetry: controller.load)],
          ),
          data: (items) => items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(top: topPadding),
                  children: const [
                    EmptyStateView(
                      icon: LucideIcons.bellOff,
                      title: 'You’re all caught up',
                      message: 'Booking updates, reminders and prescription alerts will appear here.',
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 40),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => NotificationTile(notification: items[i]),
                ),
        ),
      ),
    );
  }
}

/// A single notification row; tapping an unread item marks it read.
class NotificationTile extends ConsumerWidget {
  final NotificationModel notification;
  const NotificationTile({super.key, required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = notification;
    Future<void> markRead() async {
      final error = await ref.read(notificationsProvider.notifier).markRead(n.id);
      if (error != null && context.mounted) showAppSnack(context, error, error: true);
    }

    return Semantics(
      label: '${n.read ? '' : 'Unread. '}${n.title}',
      button: !n.read,
      child: Material(
        color: n.read ? Colors.white : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: n.read ? null : markRead,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: n.read ? AppColors.borderSoft : AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: n.read ? const Color(0xFFF1F5F9) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.bell, size: 16, color: n.read ? AppColors.bodyText : AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: n.read ? FontWeight.w600 : FontWeight.w800,
                          color: AppColors.headingText,
                        ),
                      ),
                      if (n.body != null) ...[
                        const SizedBox(height: 3),
                        Text(n.body!, style: const TextStyle(fontSize: 12.5, color: AppColors.bodyText, height: 1.4)),
                      ],
                      if (n.createdAt != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          IstTime.dateTime(n.createdAt!),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!n.read)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Tooltip(
                      message: 'Mark as read',
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
