import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/utils/json_utils.dart';

final jaasVideoServiceProvider = Provider<JaasVideoService>((ref) {
  return JaasVideoService(ref.read(apiClientProvider));
});

/// Backend-issued JaaS credentials from `GET /appointments/:id/video-token`.
class VideoToken {
  final String token;
  final String roomName;
  final String? identity;

  const VideoToken({required this.token, required this.roomName, this.identity});

  factory VideoToken.fromResponse(dynamic body) {
    final json = Json.map(body);
    final root = Json.map(json?['data']) ?? json;
    final token = Json.string(root?['token']);
    final room = Json.string(root?['roomName']);
    if (token == null || room == null) {
      throw const FormatException('Video token response is missing token or roomName');
    }
    return VideoToken(token: token, roomName: room, identity: Json.string(root?['identity']));
  }
}

enum MediaPermissionStatus { granted, denied, permanentlyDenied }

class VideoConfigurationException implements Exception {
  final String message;
  const VideoConfigurationException(this.message);
  @override
  String toString() => message;
}

/// JaaS (8x8 Jitsi as a Service) integration using the official
/// `jitsi_meet_flutter_sdk` (native Jitsi Meet SDK on iOS/Android).
class JaasVideoService {
  /// JaaS meetings are served from 8x8.vc.
  static const String jaasServerUrl = 'https://8x8.vc';

  final ApiClient _api;
  final JitsiMeet _jitsi = JitsiMeet();

  JaasVideoService(this._api);

  /// `GET /appointments/:id/video-token`
  Future<VideoToken> fetchToken(String appointmentId) async {
    try {
      final res = await _api.get('/appointments/${Uri.encodeComponent(appointmentId)}/video-token');
      return VideoToken.fromResponse(res.data);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// `POST /appointments/:id/finalize`
  Future<void> finalize(String appointmentId) async {
    try {
      await _api.post('/appointments/${Uri.encodeComponent(appointmentId)}/finalize');
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Requests camera + microphone access before joining.
  Future<MediaPermissionStatus> ensureMediaPermissions() async {
    final statuses = await [Permission.camera, Permission.microphone].request();
    final values = statuses.values;
    if (values.every((s) => s.isGranted || s.isLimited)) return MediaPermissionStatus.granted;
    if (values.any((s) => s.isPermanentlyDenied || s.isRestricted)) {
      return MediaPermissionStatus.permanentlyDenied;
    }
    return MediaPermissionStatus.denied;
  }

  Future<bool> openSettings() => openAppSettings();

  /// JaaS rooms are addressed as `<AppID>/<room>`. If the backend returns a
  /// bare room name, the AppID is read from the backend-signed JWT's `sub`
  /// claim (JaaS puts the tenant `vpaas-magic-cookie-…` there). The token is
  /// only decoded, never created or modified.
  static String resolveRoom(VideoToken token) {
    if (token.roomName.contains('/')) return token.roomName;
    final appId = _jwtClaim(token.token, 'sub');
    if (appId == null || appId.isEmpty) {
      throw const VideoConfigurationException(
        'The video room could not be resolved (missing JaaS app ID). Please contact support.',
      );
    }
    return '$appId/${token.roomName}';
  }

  static String? _jwtClaim(String jwt, String claim) {
    final parts = jwt.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final decoded = jsonDecode(payload);
      return decoded is Map ? Json.string(decoded[claim]) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> join({
    required VideoToken token,
    required String displayName,
    String? email,
    String? subject,
    required JitsiMeetEventListener listener,
  }) async {
    final options = JitsiMeetConferenceOptions(
      serverURL: jaasServerUrl,
      room: resolveRoom(token),
      token: token.token,
      configOverrides: {
        'startWithAudioMuted': false,
        'startWithVideoMuted': false,
        'prejoinPageEnabled': false,
        'subject': subject ?? 'PhysioPrime Consultation',
        'disableInviteFunctions': true,
      },
      featureFlags: {
        'welcomepage.enabled': false,
        'invite.enabled': false,
        'add-people.enabled': false,
        'calendar.enabled': false,
        'live-streaming.enabled': false,
        'recording.enabled': false,
        'meeting-password.enabled': false,
        'prejoinpage.enabled': false,
        'unsaferoomwarning.enabled': false,
        'pip.enabled': true,
      },
      userInfo: JitsiMeetUserInfo(displayName: displayName, email: email),
    );
    final response = await _jitsi.join(options, listener);
    if (!response.isSuccess) {
      throw VideoConfigurationException(
        response.message ?? 'Unable to start the video consultation. Please try again.',
      );
    }
  }

  Future<void> hangUp() async {
    try {
      await _jitsi.hangUp();
    } catch (_) {
      // Already disconnected.
    }
  }
}
