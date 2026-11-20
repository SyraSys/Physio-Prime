import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/appointments_repository.dart';
import '../domain/appointment_model.dart';

/// All appointments for the signed-in patient. Re-fetches automatically when
/// the auth user changes; call `ref.invalidate(appointmentsProvider)` after
/// mutations or on pull-to-refresh.
final appointmentsProvider = FutureProvider<List<AppointmentModel>>((ref) async {
  // Rebuild when the signed-in user changes (login / logout).
  ref.watch(authStateProvider.select((s) => s.user?.id));
  if (!ref.read(authRepositoryProvider).isAuthenticated) {
    return const <AppointmentModel>[];
  }
  try {
    final list = await ref.read(appointmentsRepositoryProvider).getAppointments();
    final sorted = [...list]..sort(_compare);
    return sorted;
  } catch (_) {
    return const <AppointmentModel>[];
  }
});

int _compare(AppointmentModel a, AppointmentModel b) {
  final aStart = a.startsAt;
  final bStart = b.startsAt;
  if (aStart == null && bStart == null) return 0;
  if (aStart == null) return 1;
  if (bStart == null) return -1;
  // Upcoming: soonest first. Others: most recent first.
  if (a.isUpcoming && b.isUpcoming) return aStart.compareTo(bStart);
  return bStart.compareTo(aStart);
}

/// Appointments for a single tab.
final appointmentsByGroupProvider = Provider.family<AsyncValue<List<AppointmentModel>>, AppointmentGroup>((ref, group) {
  return ref
      .watch(appointmentsProvider)
      .whenData((list) => list.where((a) => a.group == group).toList(growable: false));
});

/// Looks up one appointment by id from the cached list.
final appointmentByIdProvider = Provider.family<AppointmentModel?, String>((ref, id) {
  final list = ref.watch(appointmentsProvider).value;
  if (list == null) return null;
  for (final a in list) {
    if (a.id == id) return a;
  }
  return null;
});

/// Appointments reviewed during this session. Guards against duplicate review
/// submissions even if the backend list does not expose a `reviewed` flag.
final locallyReviewedAppointmentsProvider = StateProvider<Set<String>>((ref) => <String>{});
