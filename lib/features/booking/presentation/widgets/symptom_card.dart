import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/widgets/fluid_pressable.dart';
import '../../../home/domain/symptom_model.dart';

/// Compact, minimalist Symptom Card for booking screens.
/// Features:
/// - Small, compact height (~68-72px) for fast and easy scanning.
/// - 3D category/symptom icon identical to the Home Page.
/// - Title, 1-line description, recovery estimate, and symptom micro-tags.
class SymptomCard extends StatelessWidget {
  final SymptomModel item;
  final VoidCallback onTap;

  const SymptomCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  static String getIconAsset(SymptomModel item) {
    final dept = (item.department ?? '').toLowerCase();
    final title = item.title.toLowerCase();
    final slug = item.slug.toLowerCase();

    // 1. Department match
    if (dept.contains('sport')) return 'assets/images/cat_sport_injury.png';
    if (dept.contains('neuro')) return 'assets/images/cat_neurological.png';
    if (dept.contains('pediatric') || dept.contains('child')) return 'assets/images/cat_pediatric.png';
    if (dept.contains('cardio') || dept.contains('respirat') || dept.contains('pulmonary')) {
      return 'assets/images/cat_cardiac.png';
    }
    if (dept.contains('geriatric') || dept.contains('elderly') || dept.contains('aging')) {
      return 'assets/images/cat_geriatric.png';
    }
    if (dept.contains('women') || dept.contains('prenatal') || dept.contains('postnatal')) {
      return 'assets/images/cat_womens_health.png';
    }
    if (dept.contains('ortho') || dept.contains('musculo')) return 'assets/images/cat_orthopedic.png';

    // 2. Title & slug keyword match
    if (title.contains('sport') ||
        title.contains('acl') ||
        title.contains('elbow') ||
        title.contains('sprain') ||
        title.contains('strain') ||
        title.contains('runner') ||
        title.contains('ligament') ||
        slug.contains('sport')) {
      return 'assets/images/cat_sport_injury.png';
    }
    if (title.contains('neuro') ||
        title.contains('stroke') ||
        title.contains('palsy') ||
        title.contains('parkinson') ||
        title.contains('paralysis') ||
        title.contains('brain') ||
        title.contains('nerve') ||
        slug.contains('neuro')) {
      return 'assets/images/cat_neurological.png';
    }
    if (title.contains('pediatric') || title.contains('child') || title.contains('infant')) {
      return 'assets/images/cat_pediatric.png';
    }
    if (title.contains('cardio') ||
        title.contains('heart') ||
        title.contains('chest') ||
        title.contains('breath') ||
        title.contains('pulmonary') ||
        title.contains('asthma') ||
        title.contains('copd')) {
      return 'assets/images/cat_cardiac.png';
    }
    if (title.contains('geriatric') || title.contains('elderly') || title.contains('aging') || title.contains('fall')) {
      return 'assets/images/cat_geriatric.png';
    }
    if (title.contains('women') ||
        title.contains('pelvic') ||
        title.contains('prenatal') ||
        title.contains('postnatal') ||
        title.contains('pregnancy')) {
      return 'assets/images/cat_womens_health.png';
    }

    // Default to orthopedic / musculoskeletal icon
    return 'assets/images/cat_orthopedic.png';
  }

  Widget _buildIcon() {
    if (item.image != null && item.image!.startsWith('http') && !item.image!.contains('physio-prime.in/images/')) {
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: CachedNetworkImage(
              imageUrl: item.image!,
              width: 30,
              height: 30,
              fit: BoxFit.contain,
              errorWidget: (context, error, stackTrace) => _buildAssetIcon(),
            ),
          ),
        ),
      );
    }
    return _buildAssetIcon();
  }

  Widget _buildAssetIcon() {
    final assetPath = getIconAsset(item);
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Center(
          child: Image.asset(
            assetPath,
            width: 28,
            height: 28,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFEBF8FA),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.activity, size: 16, color: Color(0xFF0891B2)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FluidPressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 3D Symptom Icon matching Home Page
            _buildIcon(),
            const SizedBox(width: 12),

            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title + Recovery Estimate Row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (item.recoveryEstimate != null && item.recoveryEstimate!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            item.recoveryEstimate!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0284C7),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),

                  // 1-line description
                  Text(
                    item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Micro-tags (Top symptom pill + count + department)
                  Row(
                    children: [
                      if (item.symptomsList.isNotEmpty) ...[
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF8FA),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              item.symptomsList.first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0891B2),
                              ),
                            ),
                          ),
                        ),
                        if (item.symptomsList.length > 1) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+${item.symptomsList.length - 1}',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                      ],
                      if (item.department != null && item.department!.isNotEmpty)
                        Flexible(
                          child: Text(
                            item.department!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Circular Chevron Right Indicator
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFF0FDFA),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFF0891B2)),
            ),
          ],
        ),
      ),
    );
  }
}
