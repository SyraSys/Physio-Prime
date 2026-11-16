import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/api_error.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/dashboard_repository.dart';
import '../domain/notification_model.dart';
import '../domain/prescription_model.dart';

const _signedOut = ApiException('Please sign in to continue.', statusCode: 401);

final prescriptionsProvider = FutureProvider<List<PrescriptionModel>>((ref) async {
  ref.watch(authStateProvider.select((s) => s.user?.id));
  if (!ref.read(authRepositoryProvider).isAuthenticated) throw _signedOut;
  return ref.read(dashboardRepositoryProvider).getPrescriptions();
});

final notificationsProvider = StateNotifierProvider<NotificationsController, AsyncValue<List<NotificationModel>>>((
  ref,
) {
  ref.watch(authStateProvider.select((s) => s.user?.id));
  return NotificationsController(
    ref.read(dashboardRepositoryProvider),
    () => ref.read(authRepositoryProvider).isAuthenticated,
  );
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).value?.where((n) => !n.read).length ?? 0;
});

/// Loads notifications and marks them read with optimistic updates and
/// per-notification in-flight protection.
class NotificationsController extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final DashboardRepository _repository;
  final bool Function() _isSignedIn;
  final Set<String> _marking = {};

  NotificationsController(this._repository, this._isSignedIn) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    if (!_isSignedIn()) {
      state = AsyncValue.error(_signedOut, StackTrace.current);
      return;
    }
    if (!state.hasValue) state = const AsyncValue.loading();
    try {
      final items = await _repository.getNotifications();
      if (mounted) state = AsyncValue.data(items);
    } catch (e, st) {
      if (mounted) state = AsyncValue<List<NotificationModel>>.error(e, st).copyWithPrevious(state);
    }
  }

  bool isMarking(String id) => _marking.contains(id);

  /// Returns null on success, or a user-facing error message.
  Future<String?> markRead(String id) async {
    final current = state.value;
    if (current == null || _marking.contains(id)) return null;
    final index = current.indexWhere((n) => n.id == id);
    if (index == -1 || current[index].read) return null;

    _marking.add(id);
    final optimistic = [...current]..[index] = current[index].copyWith(read: true);
    state = AsyncValue.data(optimistic);
    try {
      await _repository.markNotificationRead(id);
      return null;
    } catch (e) {
      if (mounted) {
        final latest = state.value ?? optimistic;
        final i = latest.indexWhere((n) => n.id == id);
        if (i != -1) {
          state = AsyncValue.data([...latest]..[i] = latest[i].copyWith(read: false));
        }
      }
      return ApiException.from(e).message;
    } finally {
      _marking.remove(id);
    }
  }

  /// Marks every unread notification read (sequentially, one request each).
  Future<String?> markAllRead() async {
    final unread = state.value?.where((n) => !n.read).map((n) => n.id).toList() ?? const [];
    String? firstError;
    for (final id in unread) {
      final error = await markRead(id);
      firstError ??= error;
      if (!mounted) break;
    }
    return firstError;
  }
}
