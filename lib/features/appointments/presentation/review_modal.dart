import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/widgets/state_views.dart';
import '../data/appointments_repository.dart';
import '../domain/appointment_model.dart';
import '../providers/appointments_provider.dart';
import 'widgets/sheet_scaffold.dart';

/// Opens the review sheet. Resolves to `true` when a review was submitted.
Future<bool> showReviewModal(BuildContext context, AppointmentModel appointment) async {
  final result = await showActionSheet<bool>(context, ReviewModal(appointment: appointment));
  return result ?? false;
}

class ReviewModal extends ConsumerStatefulWidget {
  final AppointmentModel appointment;
  const ReviewModal({super.key, required this.appointment});

  @override
  ConsumerState<ReviewModal> createState() => _ReviewModalState();
}

class _ReviewModalState extends ConsumerState<ReviewModal> {
  static const _minLength = 10;
  static const _labels = ['', 'Poor', 'Fair', 'Good', 'Very good', 'Excellent'];

  int _rating = 0;
  final _comment = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  bool get _alreadyReviewed =>
      widget.appointment.reviewed || ref.read(locallyReviewedAppointmentsProvider).contains(widget.appointment.id);

  Future<void> _submit() async {
    if (_submitting) return;
    if (_alreadyReviewed) {
      setState(() => _error = 'You have already reviewed this appointment.');
      return;
    }
    if (_rating < 1 || _rating > 5) {
      setState(() => _error = 'Please select a star rating.');
      return;
    }
    final comment = _comment.text.trim();
    if (comment.length < _minLength) {
      setState(() => _error = 'Please write at least $_minLength characters about your experience.');
      return;
    }
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(appointmentsRepositoryProvider)
          .submitReview(appointmentId: widget.appointment.id, rating: _rating, comment: comment);
      _markReviewed(container);
      container.invalidate(appointmentsProvider);
      if (!mounted) return;
      showAppSnack(context, 'Thank you! Your review has been submitted.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final api = ApiException.from(e);
      if (api.isConflict) _markReviewed(container);
      setState(() {
        _submitting = false;
        _error = api.isConflict ? 'You have already reviewed this appointment.' : api.message;
      });
    }
  }

  void _markReviewed(ProviderContainer container) {
    final notifier = container.read(locallyReviewedAppointmentsProvider.notifier);
    notifier.state = {...notifier.state, widget.appointment.id};
  }

  @override
  Widget build(BuildContext context) {
    final reviewed =
        widget.appointment.reviewed || ref.watch(locallyReviewedAppointmentsProvider).contains(widget.appointment.id);

    return PopScope(
      canPop: !_submitting,
      child: ActionSheetScaffold(
        title: 'Rate your consultation',
        subtitle: widget.appointment.doctor.name,
        busy: _submitting,
        footer: PrimaryActionButton(
          label: reviewed ? 'Review submitted' : (_submitting ? 'Submitting…' : 'Submit review'),
          icon: LucideIcons.send,
          loading: _submitting,
          onPressed: (reviewed || _rating == 0) ? null : _submit,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      tooltip: '$i star${i == 1 ? '' : 's'}',
                      iconSize: 38,
                      onPressed: (_submitting || reviewed)
                          ? null
                          : () => setState(() {
                              _rating = i;
                              _error = null;
                            }),
                      icon: Icon(
                        i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: i <= _rating ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                      ),
                    ),
                ],
              ),
              SizedBox(
                height: 20,
                child: Text(
                  _labels[_rating],
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.headingText),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _comment,
                enabled: !_submitting && !reviewed,
                maxLines: 4,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: InputDecoration(
                  hintText: 'How was your session? What helped most?',
                  filled: true,
                  fillColor: const Color(0xFFF8FBFA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderSoft),
                  ),
                ),
              ),
              if (reviewed && _error == null)
                const InfoBanner(icon: LucideIcons.checkCircle, message: 'You have already reviewed this appointment.'),
              if (_error != null) InfoBanner(icon: LucideIcons.alertCircle, color: AppColors.error, message: _error!),
            ],
          ),
        ),
      ),
    );
  }
}
