import 'package:intl/intl.dart';

/// Date helpers pinned to India Standard Time (Asia/Kolkata, UTC+05:30).
///
/// IST has no daylight saving, so a fixed offset is exact. All calendar dates
/// returned here are date-only values whose year/month/day are the IST calendar
/// date regardless of the device time zone.
class IstTime {
  IstTime._();

  static const Duration offset = Duration(hours: 5, minutes: 30);

  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');
  static final DateFormat _longDate = DateFormat('EEE, d MMM yyyy');
  static final DateFormat _shortDate = DateFormat('d MMM yyyy');
  static final DateFormat _weekday = DateFormat('EEE');
  static final DateFormat _month = DateFormat('MMM');
  static final DateFormat _dateTime = DateFormat('d MMM yyyy, h:mm a');

  /// Current wall-clock time in IST (fields reflect IST, not device zone).
  static DateTime now() {
    final u = DateTime.now().toUtc().add(offset);
    return DateTime(u.year, u.month, u.day, u.hour, u.minute, u.second);
  }

  /// Today's calendar date in IST.
  static DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }

  /// The next [count] calendar days in IST, starting today.
  static List<DateTime> upcomingDays([int count = 14]) {
    final start = today();
    return List.generate(count, (i) => DateTime(start.year, start.month, start.day + i));
  }

  static bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  static String apiDate(DateTime date) => _apiDate.format(date);

  /// Parses a `YYYY-MM-DD` (or ISO) string to a calendar date.
  static DateTime? parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim();
    final direct = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(v);
    if (direct != null) {
      return DateTime(int.parse(direct.group(1)!), int.parse(direct.group(2)!), int.parse(direct.group(3)!));
    }
    final parsed = DateTime.tryParse(v);
    if (parsed == null) return null;
    final ist = toIst(parsed);
    return DateTime(ist.year, ist.month, ist.day);
  }

  /// Converts an absolute timestamp to IST wall-clock fields.
  static DateTime toIst(DateTime value) {
    final u = value.toUtc().add(offset);
    return DateTime(u.year, u.month, u.day, u.hour, u.minute, u.second);
  }

  static String longDate(DateTime date) => _longDate.format(date);
  static String shortDate(DateTime date) => _shortDate.format(date);
  static String weekday(DateTime date) => _weekday.format(date);
  static String month(DateTime date) => _month.format(date);
  static String dateTime(DateTime timestamp) => _dateTime.format(toIst(timestamp));

  /// Formats an API date string for display, falling back to the raw value.
  static String displayDate(String? apiDateValue) {
    final d = parseDate(apiDateValue);
    if (d == null) return apiDateValue ?? '—';
    return longDate(d);
  }

  /// Relative label: Today / Tomorrow / weekday.
  static String relativeDayLabel(DateTime date) {
    final t = today();
    if (isSameDay(date, t)) return 'Today';
    if (isSameDay(date, DateTime(t.year, t.month, t.day + 1))) {
      return 'Tomorrow';
    }
    return weekday(date);
  }

  /// Parses the start time of a slot label such as `"09:00 AM - 10:00 AM"`
  /// and combines it with [date]. Returns null if the label is not parseable.
  static DateTime? slotStart(DateTime date, String slot) {
    final match = RegExp(r'^\s*(\d{1,2}):(\d{2})\s*([AaPp][Mm])').firstMatch(slot);
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final pm = match.group(3)!.toUpperCase() == 'PM';
    if (hour == 12) hour = 0;
    if (pm) hour += 12;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// True when a slot on [date] has already started in IST.
  static bool slotHasStarted(DateTime date, String slot) {
    final start = slotStart(date, slot);
    if (start == null) return false;
    return !start.isAfter(now());
  }
}
