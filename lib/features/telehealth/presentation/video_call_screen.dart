import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/widgets/frosted_glass.dart';
import '../../../core/widgets/state_views.dart';
import '../../appointments/providers/appointments_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/jaas_video_service.dart';

enum _CallPhase { fetchingToken, needsPermission, ready, joining, inCall, disconnected, finalizing, ended, error }

/// Video consultation room. Fetches a backend-signed JaaS token, checks
/// camera/microphone permissions, launches the native Jitsi Meet UI, and
/// finalizes the appointment once when the consultation ends.
class VideoCallScreen extends ConsumerStatefulWidget {
  final String appointmentId;
  final String? doctorName;

  const VideoCallScreen({super.key, required this.appointmentId, this.doctorName});

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  _CallPhase _phase = _CallPhase.fetchingToken;
  VideoToken? _token;
  Object? _error;
  String? _finalizeError;
  bool _permissionPermanentlyDenied = false;

  bool _joined = false;
  bool _endHandled = false;
  bool _finalized = false;
  bool _finalizing = false;

  late final JaasVideoService _service;

  @override
  void initState() {
    super.initState();
    _service = ref.read(jaasVideoServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  @override
  void dispose() {
    if (_phase == _CallPhase.inCall || _phase == _CallPhase.joining) {
      _service.hangUp();
    }
    super.dispose();
  }

  void _set(_CallPhase phase, {Object? error}) {
    if (!mounted) return;
    setState(() {
      _phase = phase;
      _error = error;
    });
  }

  Future<void> _prepare() async {
    _set(_CallPhase.fetchingToken);
    try {
      final token = await _service.fetchToken(widget.appointmentId);
      JaasVideoService.resolveRoom(token); // validate early
      _token = token;
    } catch (e) {
      _set(_CallPhase.error, error: e);
      return;
    }
    await _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await _service.ensureMediaPermissions();
    if (!mounted) return;
    if (status == MediaPermissionStatus.granted) {
      _set(_CallPhase.ready);
    } else {
      setState(() {
        _permissionPermanentlyDenied = status == MediaPermissionStatus.permanentlyDenied;
        _phase = _CallPhase.needsPermission;
      });
    }
  }

  Future<void> _join() async {
    final token = _token;
    if (token == null || _phase == _CallPhase.joining) return;
    _endHandled = false;
    _set(_CallPhase.joining);

    final user = ref.read(authStateProvider).user;
    final displayName = (user?.fullName?.isNotEmpty ?? false) ? user!.fullName! : (token.identity ?? 'Patient');

    try {
      await _service.join(
        token: token,
        displayName: displayName,
        email: user?.email,
        subject: widget.doctorName == null ? null : 'Consultation with ${widget.doctorName}',
        listener: JitsiMeetEventListener(
          conferenceJoined: (_) {
            _joined = true;
            _set(_CallPhase.inCall);
          },
          conferenceTerminated: (_, error) => _onTerminated(error),
          readyToClose: () => _onTerminated(null),
        ),
      );
    } catch (e) {
      _set(_CallPhase.error, error: e);
    }
  }

  void _onTerminated(Object? error) {
    if (_endHandled || !mounted) return;
    _endHandled = true;

    if (!_joined) {
      _set(
        _CallPhase.error,
        error: error ?? const ApiException('The video room closed before the consultation started.'),
      );
      return;
    }
    if (error != null) {
      // Dropped connection — do not finalize; allow the patient to rejoin.
      _set(_CallPhase.disconnected, error: error);
      return;
    }
    _finalize();
  }

  Future<void> _finalize() async {
    if (_finalized || _finalizing) return;
    _finalizing = true;
    if (mounted) {
      setState(() {
        _phase = _CallPhase.finalizing;
        _finalizeError = null;
      });
    }
    try {
      await _service.finalize(widget.appointmentId);
      _finalized = true;
      if (mounted) ref.invalidate(appointmentsProvider);
    } catch (e) {
      final apiErr = ApiException.from(e);
      // If the backend has no dedicated finalize endpoint or returns 404,
      // treat as gracefully completed because room webhooks or doctor side handles closure.
      if (apiErr.isNotFound) {
        _finalized = true;
        _finalizeError = null;
        if (mounted) ref.invalidate(appointmentsProvider);
      } else {
        _finalizeError = apiErr.message;
      }
    } finally {
      _finalizing = false;
      _set(_CallPhase.ended);
    }
  }

  Future<void> _leave() async {
    await _service.hangUp();
    // Termination callbacks handle finalization; this covers platforms where
    // no callback fires after a programmatic hang up.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_endHandled && _joined) _onTerminated(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final busy = _phase == _CallPhase.joining || _phase == _CallPhase.inCall || _phase == _CallPhase.finalizing;
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: FrostedGlassAppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: busy ? null : () => context.canPop() ? context.pop() : context.go('/appointments'),
          ),
          title: const Text('Video Consultation'),
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(key: ValueKey(_phase), child: _buildPhase()),
          ),
        ),
      ),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case _CallPhase.fetchingToken:
        return const LoadingView(message: 'Preparing your secure video room…');
      case _CallPhase.needsPermission:
        return _PermissionView(
          permanentlyDenied: _permissionPermanentlyDenied,
          onRetry: _checkPermissions,
          onOpenSettings: () async {
            await _service.openSettings();
          },
        );
      case _CallPhase.ready:
        return _ReadyView(doctorName: widget.doctorName, onJoin: _join);
      case _CallPhase.joining:
        return const LoadingView(message: 'Connecting to your physiotherapist…');
      case _CallPhase.inCall:
        return _StatusView(
          icon: LucideIcons.video,
          title: 'Consultation in progress',
          message: 'Your video call is open. Return to it from the call window, or end it below.',
          primaryLabel: 'End consultation',
          onPrimary: _leave,
        );
      case _CallPhase.disconnected:
        return _StatusView(
          icon: LucideIcons.wifiOff,
          title: 'Call disconnected',
          message: 'The connection dropped. You can rejoin the consultation.',
          primaryLabel: 'Rejoin',
          onPrimary: _join,
          secondaryLabel: 'Back to appointments',
          onSecondary: () => context.go('/appointments'),
        );
      case _CallPhase.finalizing:
        return const LoadingView(message: 'Wrapping up your consultation…');
      case _CallPhase.ended:
        return _StatusView(
          icon: _finalizeError == null ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
          title: 'Consultation ended',
          message: _finalizeError == null
              ? 'Thank you! Your prescription and notes will appear in your dashboard once shared by your physiotherapist.'
              : 'The call ended, but we could not update the session status: $_finalizeError',
          primaryLabel: _finalizeError == null ? 'Back to appointments' : 'Retry',
          onPrimary: _finalizeError == null ? () => context.go('/appointments') : _finalize,
          secondaryLabel: _finalizeError == null ? 'Go to dashboard' : 'Back to appointments',
          onSecondary: () => context.go(_finalizeError == null ? '/dashboard' : '/appointments'),
        );
      case _CallPhase.error:
        final error = _error;
        if (error is VideoConfigurationException) {
          return _StatusView(
            icon: LucideIcons.alertCircle,
            title: 'Unable to start the call',
            message: error.message,
            primaryLabel: 'Try again',
            onPrimary: _prepare,
          );
        }
        return ErrorView(
          error: error ?? const ApiException('Unable to start the video consultation.'),
          title: 'Unable to start the call',
          onRetry: _prepare,
        );
    }
  }
}

class _ReadyView extends StatelessWidget {
  final String? doctorName;
  final VoidCallback onJoin;
  const _ReadyView({required this.doctorName, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
            child: const Icon(LucideIcons.video, color: Colors.white, size: 42),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          doctorName == null ? 'Your room is ready' : 'Ready to meet $doctorName',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Find a quiet, well-lit space where you can move freely — your physiotherapist may ask you to demonstrate movements.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: AppColors.bodyText, height: 1.45),
        ),
        const SizedBox(height: 24),
        const InfoCard(
          child: Column(
            children: [
              _Tip(icon: LucideIcons.wifiOff, text: 'Use a stable Wi-Fi or 4G/5G connection'),
              _Tip(icon: LucideIcons.mic, text: 'Camera and microphone access are enabled'),
              _Tip(icon: LucideIcons.shieldCheck, text: 'Private, encrypted session for you and your physio'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PrimaryActionButton(label: 'Join consultation', icon: LucideIcons.video, onPressed: onJoin),
      ],
    );
  }
}

class _Tip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Tip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.headingText)),
          ),
        ],
      ),
    );
  }
}

class _PermissionView extends StatelessWidget {
  final bool permanentlyDenied;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  const _PermissionView({required this.permanentlyDenied, required this.onRetry, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return _StatusView(
      icon: LucideIcons.videoOff,
      title: 'Camera & microphone needed',
      message: permanentlyDenied
          ? 'Access is turned off for PhysioPrime. Enable Camera and Microphone in Settings, then come back and try again.'
          : 'Allow camera and microphone access so your physiotherapist can see and hear you.',
      primaryLabel: permanentlyDenied ? 'Open Settings' : 'Allow access',
      onPrimary: permanentlyDenied ? onOpenSettings : onRetry,
      secondaryLabel: permanentlyDenied ? 'I’ve enabled it' : null,
      onSecondary: permanentlyDenied ? onRetry : null,
    );
  }
}

class _StatusView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _StatusView({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(color: AppColors.surfaceSoft, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: AppColors.bodyText, height: 1.45),
            ),
            const SizedBox(height: 24),
            PrimaryActionButton(label: primaryLabel, onPressed: onPrimary),
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 10),
              SecondaryActionButton(label: secondaryLabel!, onPressed: onSecondary),
            ],
          ],
        ),
      ),
    );
  }
}
