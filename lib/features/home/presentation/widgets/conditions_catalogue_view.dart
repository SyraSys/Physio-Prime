import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/widgets/fluid_pressable.dart';
import '../../data/conditions_catalogue.dart';
import '../../providers/home_provider.dart';

/// Reusable Categorized Conditions Catalogue View matching the website
/// (https://www.physio-prime.in/conditions).
///
/// Features:
/// - Rounded stadium search pill at the top: `Search 48+ conditions, e.g. "back pain"...`
/// - Dynamic real-time search filtering across all 48 canonical conditions.
/// - 7 clinical categories with bold section titles and "View specialty →" links.
/// - Minimalist iOS condition cards: strictly the title on the left and chevron `>` on the right.
/// - Responsive layout: 3 columns on tablet/desktop, 2 columns on phone, 1 column on narrow viewports.
class ConditionsCatalogueView extends ConsumerStatefulWidget {
  final void Function(ConditionData condition)? onConditionSelected;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const ConditionsCatalogueView({
    super.key,
    this.onConditionSelected,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 96),
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  ConsumerState<ConditionsCatalogueView> createState() => _ConditionsCatalogueViewState();
}

class _ConditionsCatalogueViewState extends ConsumerState<ConditionsCatalogueView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (_searchQuery != query) {
      setState(() {
        _searchQuery = query;
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleConditionTap(ConditionData condition) {
    if (widget.onConditionSelected != null) {
      widget.onConditionSelected!(condition);
      return;
    }
    final liveSymptoms = ref.read(symptomsProvider).value;
    final sym = ConditionsCatalogue.findOrCreateSymptom(condition.slug, liveSymptoms: liveSymptoms);
    context.push('/conditions/${condition.slug}', extra: sym);
  }

  void _handleViewSpecialty(String specialtySlug) {
    context.push('/categories/$specialtySlug');
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchQuery.isNotEmpty;
    final matchingConditions = isSearching
        ? ConditionsCatalogue.allConditions.where((c) {
            return c.title.toLowerCase().contains(_searchQuery) ||
                c.category.toLowerCase().contains(_searchQuery) ||
                c.slug.toLowerCase().contains(_searchQuery);
          }).toList()
        : const <ConditionData>[];

    return ListView(
      physics: widget.physics ?? const BouncingScrollPhysics(),
      shrinkWrap: widget.shrinkWrap,
      padding: widget.padding,
      children: [
        // =====================================================================
        // 1. STADIUM PILL SEARCH BAR (Centered, exactly matching website)
        // =====================================================================
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(
                LucideIcons.search,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search 48+ conditions, e.g. "back pain"...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // =====================================================================
        // 2. SEARCH RESULTS VIEW (When query is active)
        // =====================================================================
        if (isSearching) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  'Search Results',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${matchingConditions.length} found',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0284C7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (matchingConditions.isEmpty)
            _buildEmptySearchState()
          else
            _buildResponsiveConditionGrid(matchingConditions),
        ] else ...[
          // =====================================================================
          // 3. CANONICAL 7 CATEGORIES (When no query is active)
          // =====================================================================
          for (int i = 0; i < ConditionsCatalogue.allCategories.length; i++) ...[
            _buildCategorySection(ConditionsCatalogue.allCategories[i]),
            if (i < ConditionsCatalogue.allCategories.length - 1)
              const SizedBox(height: 16),
          ],
        ],
      ],
    );
  }

  Widget _buildCategorySection(ConditionCategoryData category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header: Bold Title on Left, "View specialty →" on Right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                category.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FluidPressable(
              onTap: () => _handleViewSpecialty(category.specialtySlug),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View specialty',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0891B2),
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      LucideIcons.arrowRight,
                      size: 12,
                      color: Color(0xFF0891B2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Grid of Condition Cards: Title + Chevron only
        _buildResponsiveConditionGrid(category.conditions),
      ],
    );
  }

  Widget _buildResponsiveConditionGrid(List<ConditionData> conditions) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount;
        if (width >= 620) {
          crossAxisCount = 3;
        } else if (width >= 330) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: conditions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 6,
            crossAxisSpacing: 8,
            mainAxisExtent: 46,
          ),
          itemBuilder: (context, index) {
            final cond = conditions[index];
            return ConditionCard(
              title: cond.title,
              onTap: () => _handleConditionTap(cond),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptySearchState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.searchX,
              size: 28,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No conditions found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'We couldn\'t find any condition matching "$_searchQuery".',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          FluidPressable(
            onTap: () => _searchController.clear(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0891B2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Clear search',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Minimalist iOS Condition Card.
/// Strictly contains the condition title on the left and a subtle chevron `>` on the right.
class ConditionCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const ConditionCard({
    super.key,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FluidPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x050F172A),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                  letterSpacing: -0.1,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              LucideIcons.chevronRight,
              size: 15,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}
