import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ContentRepository(apiClient);
});

class ContentRepository {
  final ApiClient _apiClient;

  ContentRepository(this._apiClient);

  /// Submit Caretaker Booking Inquiry
  Future<bool> submitCaretakerInquiry({
    required String name,
    required String phone,
    required String message,
  }) async {
    final response = await _apiClient.post('/caretaker', data: {
      'name': name.trim(),
      'phone': phone.trim(),
      'message': message.trim(),
    });
    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// Submit Career / Doctor Onboarding Application
  Future<bool> submitCareerApplication(Map<String, dynamic> applicationData) async {
    final response = await _apiClient.post('/careers', data: applicationData);
    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// Submit Newsletter Subscription
  Future<bool> subscribeNewsletter(String email) async {
    final response = await _apiClient.post('/newsletter', data: {
      'email': email.trim(),
    });
    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// Fetch Blog Posts
  Future<List<dynamic>> getBlogPosts({int page = 1, String? tag}) async {
    try {
      final queryParams = <String, dynamic>{'page': page};
      if (tag != null) queryParams['tag'] = tag;
      final response = await _apiClient.get('/blog/posts', queryParameters: queryParams);
      return response.data['posts'] as List<dynamic>? ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Fetch Single Blog Post by Slug
  Future<Map<String, dynamic>?> getBlogPostBySlug(String slug) async {
    try {
      final response = await _apiClient.get('/blog/posts/${Uri.encodeComponent(slug)}');
      if (response.data is Map && response.data['post'] != null) {
        return response.data['post'] as Map<String, dynamic>;
      }
      return response.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Fetch Dynamic CMS Page Content
  Future<Map<String, dynamic>?> getCmsPage(String page) async {
    try {
      final response = await _apiClient.get('/cms/${Uri.encodeComponent(page)}');
      return response.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}
