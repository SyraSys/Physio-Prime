import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../utils/api_error.dart';
import 'fluid_pressable.dart';
import 'frosted_glass.dart';

/// Centered progress indicator with an optional caption.
class LoadingView extends StatelessWidget {
  final String? message;
  final EdgeInsetsGeometry padding;

  const LoadingView({super.key, this.message, this.padding = const EdgeInsets.all(32)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.primary),
            ),
            if (message != null) ...[
              const SizedBox(height: 14),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.bodyText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error panel that maps any error to a friendly message, offers retry and,
/// for expired sessions, a sign-in shortcut.
class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final String? title;
  final bool compact;

  const ErrorView({super.key, required this.error, this.onRetry, this.title, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final api = ApiException.from(error);
    final icon = api.isNetworkError
        ? LucideIcons.wifiOff
        : api.isUnauthorized
        ? LucideIcons.lock
        : LucideIcons.alertCircle;
    final heading =
        title ??
        (api.isNetworkError
            ? 'You appear to be offline'
            : api.isUnauthorized
            ? 'Sign in required'
            : 'Something went wrong');

    return Padding(
      padding: EdgeInsets.all(compact ? 16 : 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 44 : 60,
              height: compact ? 44 : 60,
              decoration: BoxDecoration(
                color: api.isUnauthorized ? AppColors.surfaceSoft : const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: compact ? 20 : 26,
                color: api.isUnauthorized ? AppColors.primary : AppColors.error,
              ),
            ),
            SizedBox(height: compact ? 10 : 16),
            Text(
              heading,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.headingText),
            ),
            const SizedBox(height: 6),
            Text(
              api.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.bodyText, height: 1.4),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                if (api.isUnauthorized)
                  PrimaryActionButton(
                    label: 'Sign in',
                    icon: LucideIcons.user,
                    expand: false,
                    onPressed: () => context.push('/login'),
                  ),
                if (onRetry != null)
                  SecondaryActionButton(
                    label: 'Try again',
                    icon: LucideIcons.refreshCw,
                    expand: false,
                    onPressed: onRetry,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Friendly empty-state panel.
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: AppColors.surfaceSoft, shape: BoxShape.circle),
              child: Icon(icon, size: 28, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.headingText),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.bodyText, height: 1.4),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              PrimaryActionButton(label: actionLabel!, expand: false, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

/// Gradient primary CTA with loading and disabled states.
class PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expand;

  const PrimaryActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
        else if (icon != null)
          Icon(icon, size: 17, color: Colors.white),
        if (loading || icon != null) const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white, letterSpacing: -0.1),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: FluidPressable(
        onTap: enabled ? onPressed : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled || loading ? 1 : 0.45,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: enabled
                  ? const [BoxShadow(color: Color(0x330891B2), blurRadius: 10, offset: Offset(0, 3))]
                  : null,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Outlined secondary action.
class SecondaryActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expand;
  final Color color;
  final bool loading;

  const SecondaryActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.expand = true,
    this.color = AppColors.primary,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: FluidPressable(
        onTap: enabled ? onPressed : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled || loading ? 1 : 0.45,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                else if (icon != null)
                  Icon(icon, size: 16, color: color),
                if (loading || icon != null) const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// White rounded card used across Developer 2 screens.
class InfoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final String? title;
  final IconData? icon;
  final Widget? trailing;

  const InfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.title,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: title == null
          ? child
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[Icon(icon, size: 16, color: AppColors.primary), const SizedBox(width: 8)],
                    Expanded(
                      child: Text(
                        title!,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.headingText),
                      ),
                    ),
                    ?trailing,
                  ],
                ),
                const SizedBox(height: 12),
                child,
              ],
            ),
    );
  }
}

/// Label/value row for detail cards.
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  final Widget? trailing;

  const DetailRow({super.key, required this.label, required this.value, this.emphasize = false, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.bodyText)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: emphasize ? 15 : 13,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                color: emphasize ? AppColors.primary : AppColors.headingText,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Small colored status pill.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusPill({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 11, color: color), const SizedBox(width: 4)],
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

/// Soft informational banner.
class InfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const InfoBanner({super.key, required this.icon, required this.message, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: color == AppColors.primary ? AppColors.darkTeal : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when a route is opened without the arguments it requires.
class MissingRouteDataScreen extends StatelessWidget {
  final String title;
  final String message;

  const MissingRouteDataScreen({
    super.key,
    required this.title,
    this.message = 'This page was opened without the information it needs. Please go back and try again.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FrostedGlassAppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(title),
      ),
      body: EmptyStateView(
        icon: LucideIcons.alertTriangle,
        title: 'Nothing to show here',
        message: message,
        actionLabel: 'Go to Home',
        onAction: () => context.go('/'),
      ),
    );
  }
}

/// Prompts a signed-out user to sign in before using a personal feature.
class SignInPromptView extends StatelessWidget {
  final String title;
  final String message;

  const SignInPromptView({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: LucideIcons.lock,
      title: title,
      message: message,
      actionLabel: 'Sign in',
      onAction: () => context.push('/login'),
    );
  }
}

/// Floating snack helper using brand styling.
void showAppSnack(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? AppColors.error : AppColors.headingText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
}
