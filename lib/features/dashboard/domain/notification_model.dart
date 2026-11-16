import '../../../core/utils/json_utils.dart';

/// A notification from `GET /me/notifications`.
class NotificationModel {
  final String id;
  final String title;
  final String? body;
  final DateTime? createdAt;
  final bool read;
  final String? type;

  const NotificationModel({
    required this.id,
    required this.title,
    this.body,
    this.createdAt,
    required this.read,
    this.type,
  });

  NotificationModel copyWith({bool? read}) =>
      NotificationModel(id: id, title: title, body: body, createdAt: createdAt, read: read ?? this.read, type: type);

  static NotificationModel? tryParse(dynamic raw) {
    final json = Json.map(raw);
    if (json == null) return null;
    final id = Json.string(json['id']);
    if (id == null) return null;
    final body = Json.string(Json.pick(json, const ['body', 'message', 'text', 'description']));
    final title = Json.string(json['title']) ?? body ?? 'Notification';
    final readFlag = Json.boolean(json['read']) ?? Json.boolean(json['isRead']);
    return NotificationModel(
      id: id,
      title: title,
      body: Json.string(json['title']) == null ? null : body,
      createdAt: Json.dateTime(Json.pick(json, const ['createdAt', 'sentAt', 'date'])),
      read: readFlag ?? (json['readAt'] != null),
      type: Json.string(json['type']),
    );
  }
}
