import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/utils/json_utils.dart';
import '../domain/appointment_model.dart';

final appointmentsRepositoryProvider = Provider<AppointmentsRepository>((ref) {
  return AppointmentsRepository(ref.read(apiClientProvider));
});

class AppointmentsRepository {
  final ApiClient _api;

  AppointmentsRepository(this._api);

  String _path(String id, [String? action]) =>
      '/appointments/${Uri.encodeComponent(id)}${action == null ? '' : '/$action'}';

  /// `GET /appointments`
  Future<List<AppointmentModel>> getAppointments() async {
    try {
      final res = await _api.get('/appointments');
      return Json.listFromBody(res.data, const [
        'appointments',
        'items',
        'results',
      ]).map(AppointmentModel.tryParse).whereType<AppointmentModel>().toList(growable: false);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// `POST /appointments/:id/reschedule`
  Future<void> reschedule({required String id, required String date, required String slot}) async {
    try {
      await _api.post(_path(id, 'reschedule'), data: {'date': date, 'slot': slot});
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// `POST /appointments/:id/cancel`
  Future<void> cancel({required String id, required String reason}) async {
    try {
      await _api.post(_path(id, 'cancel'), data: {'reason': reason});
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// `POST /reviews`
  Future<void> submitReview({required String appointmentId, required int rating, required String comment}) async {
    try {
      await _api.post('/reviews', data: {'appointmentId': appointmentId, 'rating': rating, 'comment': comment});
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
