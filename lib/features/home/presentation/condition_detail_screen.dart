import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../data/conditions_catalogue.dart';
import '../domain/symptom_model.dart';
import '../providers/home_provider.dart';

class ConditionDetailScreen extends ConsumerWidget {
  final String slug;
  final SymptomModel? symptom;

  const ConditionDetailScreen({
    super.key,
    required this.slug,
    this.symptom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symptomsAsync = ref.watch(symptomsProvider);
    final sym = symptom ??
        symptomsAsync.value?.where((s) => s.slug == slug).firstOrNull ??
        ConditionsCatalogue.findOrCreateSymptom(slug, liveSymptoms: symptomsAsync.value);

    final mediaQuery = MediaQuery.of(context);
    final viewPaddingBottom = mediaQuery.viewPadding.bottom;
    final paddingBottom = mediaQuery.padding.bottom;
    final systemBottomInset = math.max(viewPaddingBottom, paddingBottom);
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    final double effectiveBottomInset;
    if (isAndroid) {
      if (systemBottomInset >= 40.0) {
        effectiveBottomInset = systemBottomInset;
      } else if (systemBottomInset >= 12.0) {
        effectiveBottomInset = systemBottomInset;
      } else {
        // Fallback for Xiaomi/MIUI 3-button navigation reporting 0:
        effectiveBottomInset = 48.0;
      }
    } else {
      effectiveBottomInset = systemBottomInset;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          sym.title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A), size: 22),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/conditions');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sym.image != null && sym.image!.startsWith('http') && !sym.image!.contains('physio-prime.in/images/'))
              CachedNetworkImage(
                imageUrl: sym.image!,
                height: 210,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(height: 210, color: AppColors.surfaceSoft),
                errorWidget: (context, url, error) => Container(height: 210, color: AppColors.surfaceSoft),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sym.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    sym.description,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      height: 1.5,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (sym.recoveryEstimate != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF8FA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCCEBF0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(LucideIcons.clock, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estimated Recovery Timeline',
                                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sym.recoveryEstimate!,
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14.5, color: const Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  if (sym.symptomsList.isNotEmpty) ...[
                    Text(
                      'Common Symptoms',
                      style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),
                    ...sym.symptomsList.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(LucideIcons.alertCircle, color: AppColors.primary, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item,
                                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF334155), height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],

                  if (sym.treatment != null) ...[
                    Text(
                      'Physiotherapy Treatment Plan',
                      style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      sym.treatment!,
                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569), height: 1.55),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + effectiveBottomInset),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0C0F172A),
              blurRadius: 14,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              context.push('/booking-flow', extra: sym);
            },
            icon: const Icon(LucideIcons.calendar, size: 18, color: Colors.white),
            label: Text(
              'Book Doctor for ${sym.title}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ),
    );
  }
}
