import '../../../core/utils/json_utils.dart';

/// One bookable time window returned by `GET /doctors/:slug/slots`.
class SlotModel {
  /// Display + API label, e.g. `"09:00 AM - 10:00 AM"` or `"Early Morning (7:00 AM - 9:00 AM)"`.
  final String slot;
  final bool available;
  final String? label;
  final String? start;
  final String? end;
  final int maxPatients;
  final int bookedCount;

  const SlotModel({
    required this.slot,
    required this.available,
    this.label,
    this.start,
    this.end,
    this.maxPatients = 3,
    this.bookedCount = 0,
  });

  int get availableSpots => (maxPatients - bookedCount).clamp(0, 99);

  String get displayTitle => label ?? slot;

  String get timeRange {
    if (start != null && end != null) {
      return '${_formatTime(start!)} – ${_formatTime(end!)}';
    }
    return slot;
  }

  static String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.isEmpty) return time;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? parts[1] : '00';
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $period';
  }

  static SlotModel? tryParse(dynamic raw) {
    final json = Json.map(raw);
    if (json == null) return null;

    final available = Json.boolean(json['available']) ?? true;
    final label = Json.string(json['label']);
    final start = Json.string(json['start']);
    final end = Json.string(json['end']);
    final maxPatients = Json.integer(json['maxPatients']) ?? 3;
    final bookedCount = Json.integer(json['bookedCount']) ?? 0;

    String? slot = Json.string(json['slot']);
    if (slot == null || slot.isEmpty) {
      if (start != null && end != null) {
        slot = '${_formatTime(start)} - ${_formatTime(end)}';
      } else if (label != null) {
        slot = label;
      }
    }

    if (slot == null) return null;

    return SlotModel(
      slot: slot,
      available: available,
      label: label,
      start: start,
      end: end,
      maxPatients: maxPatients,
      bookedCount: bookedCount,
    );
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
