import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/frosted_glass.dart';
import '../data/content_repository.dart';

final blogDetailProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, slug) async {
  return ref.read(contentRepositoryProvider).getBlogPostBySlug(slug);
});

class BlogDetailScreen extends ConsumerWidget {
  final String slug;
  final Map<String, dynamic>? initialData;

  const BlogDetailScreen({
    super.key,
    required this.slug,
    this.initialData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(blogDetailProvider(slug));
    final post = async.value ?? initialData;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: FrostedGlassAppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => context.canPop() ? context.pop() : context.go('/blog'),
        ),
        title: Text(
          'Health Guide',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: post != null
          ? _buildArticleBody(context, post)
          : async.when(
              data: (data) => data != null ? _buildArticleBody(context, data) : _buildNotFound(context),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => _buildError(context, err.toString()),
            ),
    );
  }

  Widget _buildArticleBody(BuildContext context, Map<String, dynamic> post) {
    final title = post['title']?.toString() ?? 'Musculoskeletal Recovery Guide';
    final summary = post['summary']?.toString() ?? post['excerpt']?.toString() ?? '';
    final content = post['content']?.toString() ?? post['body']?.toString() ?? summary;
    final imageUrl = post['coverImage']?.toString() ?? post['image']?.toString();
    final authorName = post['author']?['name']?.toString() ?? post['authorName']?.toString() ?? 'PhysioPrime Clinical Team';
    final category = post['category']?['name']?.toString() ?? post['categoryName']?.toString() ?? 'Physiotherapy';
    final readTime = post['readTime']?.toString() ?? '4 min read';

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + kToolbarHeight + 16,
        20,
        40,
      ),
      children: [
        // Category & Read Time
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF8FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                category,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                const Icon(LucideIcons.clock, size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  readTime,
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Article Title
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 14),

        // Author / Reviewer Byline
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFEBF8FA),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.stethoscope, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        authorName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF0891B2)),
                    ],
                  ),
                  Text(
                    'Medically reviewed by certified OTPT practitioner',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Optional Cover Image
        if (imageUrl != null && imageUrl.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 18),
        ],

        // Summary Card
        if (summary.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCCFBF1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.lightbulb, size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    summary,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0F766E),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Article Content Body
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clinical Overview & Recommendations',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                content.isNotEmpty
                    ? content
                    : 'Early diagnosis and gentle range-of-motion physiotherapy are proven to significantly reduce musculoskeletal recovery timelines. Follow your prescribed exercise regimen and consult an accredited therapist if pain persists.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF334155),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // CTA Card to Book a Specialist
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x280891B2),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.stethoscope, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Need Specialist Advice?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Connect with verified orthopedic and neurological physiotherapists for doorstep visits or HD video teleconsultations.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0E7490),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => context.push('/doctors'),
                  child: Text(
                    'Find a Specialist',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0E7490),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.fileQuestion, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Article Not Found',
              style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'This health guide may have been updated or moved.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.bodyText),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Back to Blog'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertTriangle, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              'Unable to load article',
              style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(message, style: GoogleFonts.inter(fontSize: 13, color: AppColors.bodyText)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
