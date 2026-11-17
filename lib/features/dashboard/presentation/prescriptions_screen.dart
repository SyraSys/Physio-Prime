import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ist_time.dart';
import '../../../core/widgets/fluid_pressable.dart';
import '../../../core/widgets/frosted_glass.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/prescription_model.dart';
import '../providers/dashboard_provider.dart';

/// Prescriptions list backed by `GET /me/prescriptions`.
class PrescriptionsScreen extends ConsumerWidget {
  const PrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStateProvider.select((s) => s.status));
    final signedIn = ref.read(authRepositoryProvider).isAuthenticated;
    final async = ref.watch(prescriptionsProvider);
    final topPadding = MediaQuery.paddingOf(context).top + kToolbarHeight;

    Future<void> refresh() async {
      ref.invalidate(prescriptionsProvider);
      try {
        await ref.read(prescriptionsProvider.future);
      } catch (_) {}
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FrostedGlassAppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
        title: const Text('My Prescriptions'),
      ),
      body: !signedIn
          ? Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: const SignInPromptView(
                title: 'Sign in to view prescriptions',
                message: 'Prescriptions shared by your physiotherapist appear here.',
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              edgeOffset: topPadding,
              onRefresh: refresh,
              child: async.when(
                skipLoadingOnRefresh: true,
                loading: () => ListView(
                  padding: EdgeInsets.only(top: topPadding),
                  children: const [LoadingView(message: 'Loading prescriptions…')],
                ),
                error: (e, _) => ListView(
                  padding: EdgeInsets.only(top: topPadding),
                  children: [ErrorView(error: e, onRetry: refresh)],
                ),
                data: (items) => items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(top: topPadding),
                        children: const [
                          EmptyStateView(
                            icon: LucideIcons.clipboardList,
                            title: 'No prescriptions yet',
                            message:
                                'After a consultation, your physiotherapist’s prescription and exercise plan will appear here.',
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 40),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => PrescriptionCard(
                          prescription: items[i],
                          onTap: () => showPrescriptionDetail(context, items[i]),
                        ),
                      ),
              ),
            ),
    );
  }
}

/// Compact prescription summary card (also used on the dashboard).
class PrescriptionCard extends StatelessWidget {
  final PrescriptionModel prescription;
  final VoidCallback onTap;

  const PrescriptionCard({super.key, required this.prescription, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = prescription;
    final meds = p.medications;
    return Semantics(
      button: true,
      label: 'Prescription${p.doctorName == null ? '' : ' from ${p.doctorName}'}',
      child: FluidPressable(
        pressedScale: 0.985,
        onTap: onTap,
        child: InfoCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.surfaceSoft, borderRadius: BorderRadius.circular(14)),
                child: const Icon(LucideIcons.pill, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.diagnosis ?? (p.doctorName != null ? 'Prescription by ${p.doctorName}' : 'Prescription'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.headingText),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (p.doctorName != null && p.diagnosis != null) p.doctorName!,
                        if (p.issuedAt != null) IstTime.shortDate(IstTime.toIst(p.issuedAt!)),
                      ].join(' · '),
                      style: const TextStyle(fontSize: 12, color: AppColors.bodyText),
                    ),
                    if (meds.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        meds.take(3).map((m) => m.name).join(', ') +
                            (meds.length > 3 ? ' +${meds.length - 3} more' : ''),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.headingText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.bodyText),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showPrescriptionDetail(BuildContext context, PrescriptionModel p) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _PrescriptionDetailSheet(prescription: p),
  );
}

class _PrescriptionDetailSheet extends StatefulWidget {
  final PrescriptionModel prescription;
  const _PrescriptionDetailSheet({required this.prescription});

  @override
  State<_PrescriptionDetailSheet> createState() => _PrescriptionDetailSheetState();
}

class _PrescriptionDetailSheetState extends State<_PrescriptionDetailSheet> {
  bool _opening = false;

  Future<void> _openDocument(Uri url) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!ok && mounted) showAppSnack(context, 'Could not open the prescription document.', error: true);
    } catch (_) {
      if (mounted) showAppSnack(context, 'Could not open the prescription document.', error: true);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prescription;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 16),
          Text(p.diagnosis ?? 'Prescription', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          if (p.doctorName != null) DetailRow(label: 'Prescribed by', value: p.doctorName!),
          if (p.issuedAt != null) DetailRow(label: 'Date', value: IstTime.longDate(IstTime.toIst(p.issuedAt!))),
          if (p.appointmentId != null) DetailRow(label: 'Appointment', value: p.appointmentId!),
          const SizedBox(height: 14),
          if (p.medications.isNotEmpty) ...[
            const Text(
              'Medication & exercise plan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.headingText),
            ),
            const SizedBox(height: 10),
            for (final m in p.medications) ...[_MedicationTile(item: m), const SizedBox(height: 10)],
          ] else
            const InfoBanner(
              icon: LucideIcons.info,
              message: 'No medication details were included in this prescription.',
            ),
          if (p.instructions != null) ...[
            const SizedBox(height: 6),
            InfoCard(
              title: 'Instructions',
              icon: LucideIcons.clipboardList,
              child: Text(
                p.instructions!,
                style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.headingText),
              ),
            ),
          ],
          if (p.documentUrl != null) ...[
            const SizedBox(height: 18),
            PrimaryActionButton(
              label: 'View / download document',
              icon: LucideIcons.download,
              loading: _opening,
              onPressed: () => _openDocument(p.documentUrl!),
            ),
          ],
        ],
      ),
    );
  }
}

class _MedicationTile extends StatelessWidget {
  final MedicationItem item;
  const _MedicationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final chips = <(IconData, String)>[
      if (item.dosage != null) (LucideIcons.pill, item.dosage!),
      if (item.frequency != null) (LucideIcons.clock, item.frequency!),
      if (item.duration != null) (LucideIcons.calendar, item.duration!),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.headingText),
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [for (final c in chips) StatusPill(label: c.$2, color: AppColors.deepTeal, icon: c.$1)],
            ),
          ],
          if (item.instructions != null) ...[
            const SizedBox(height: 8),
            Text(item.instructions!, style: const TextStyle(fontSize: 12.5, color: AppColors.bodyText, height: 1.4)),
          ],
        ],
      ),
    );
  }
}
