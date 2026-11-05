import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(post['title']?.toString() ?? 'Health Guide', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(post['summary']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(LucideIcons.chevronRight, size: 16),
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
