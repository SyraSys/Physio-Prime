import '../../../core/utils/json_utils.dart';

/// One bookable time window returned by `GET /doctors/:slug/slots`.
class SlotModel {
  /// Display + API label, e.g. `"09:00 AM - 10:00 AM"`. Sent back verbatim
  /// when booking or rescheduling.
  final String slot;
  final bool available;

  const SlotModel({required this.slot, required this.available});

  static SlotModel? tryParse(dynamic raw) {
    final json = Json.map(raw);
    if (json == null) return null;
    final label = Json.string(json['slot']);
    if (label == null) return null;
    return SlotModel(slot: label, available: Json.boolean(json['available']) ?? false);
  }

  @override
  bool operator ==(Object other) => other is SlotModel && other.slot == slot && other.available == available;

  @override
  int get hashCode => Object.hash(slot, available);
}

/// Parsed availability response for a single date.
class SlotAvailability {
  final String date;
  final List<SlotModel> windows;

  const SlotAvailability({required this.date, required this.windows});

  bool get hasAnyAvailable => windows.any((w) => w.available);

  factory SlotAvailability.fromResponse(String date, dynamic body) {
    final windows = Json.listFromBody(body, const [
      'windows',
      'slots',
    ]).map(SlotModel.tryParse).whereType<SlotModel>().toList(growable: false);
    return SlotAvailability(date: date, windows: windows);
  }
}

/// Provider key for slot lookups.
class SlotQuery {
  final String doctorSlug;
  final String date; // YYYY-MM-DD

  const SlotQuery({required this.doctorSlug, required this.date});

  @override
  bool operator ==(Object other) => other is SlotQuery && other.doctorSlug == doctorSlug && other.date == date;

  @override
  int get hashCode => Object.hash(doctorSlug, date);
}
