import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../data/content_repository.dart';

final blogPostsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(contentRepositoryProvider).getBlogPosts();
});

class BlogListScreen extends ConsumerWidget {
  const BlogListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blogsAsync = ref.watch(blogPostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Health Guides & Blog'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(blogPostsProvider),
        child: blogsAsync.when(
          data: (posts) {
            if (posts.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.bookOpen, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No articles published yet.', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text('Clinical health guides will appear here soon.', style: TextStyle(color: AppColors.bodyText)),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final post = posts[index] as Map<String, dynamic>;
                final slug = post['slug']?.toString() ?? post['id']?.toString() ?? 'article-$index';
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.push('/blog/$slug', extra: post),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF8FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.bookOpen, size: 20, color: AppColors.primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post['title']?.toString() ?? 'Health Guide',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                                if (post['summary'] != null && post['summary'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    post['summary']!.toString(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: AppColors.bodyText, fontSize: 13),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.chevronRight, size: 18, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
