import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/utils/json_utils.dart';
import '../domain/notification_model.dart';
import '../domain/prescription_model.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.read(apiClientProvider));
});

class DashboardRepository {
  final ApiClient _api;

  DashboardRepository(this._api);

  /// `GET /me/prescriptions`
  Future<List<PrescriptionModel>> getPrescriptions() async {
    try {
      final res = await _api.get('/me/prescriptions');
      final list = Json.listFromBody(res.data, const [
        'prescriptions',
        'items',
        'results',
      ]).map(PrescriptionModel.tryParse).whereType<PrescriptionModel>().toList();
      list.sort((a, b) {
        final ad = a.issuedAt, bd = b.issuedAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });
      return list;
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// `GET /me/notifications`
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final res = await _api.get('/me/notifications');
      final list = Json.listFromBody(res.data, const [
        'notifications',
        'items',
        'results',
      ]).map(NotificationModel.tryParse).whereType<NotificationModel>().toList();
      list.sort((a, b) {
        final ad = a.createdAt, bd = b.createdAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });
      return list;
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// `PATCH /me/notifications/:id/read`
  Future<void> markNotificationRead(String id) async {
    try {
      await _api.patch('/me/notifications/${Uri.encodeComponent(id)}/read');
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
