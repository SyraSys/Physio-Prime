import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return AuthRepository(apiClient);
});

class AuthRepository {
  final ApiClient _apiClient;
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthRepository(this._apiClient);

  User? get currentSupabaseUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  bool get isAuthenticated => currentSession != null;

  /// Sign In with Email & Password
  Future<UserModel> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    if (response.session?.accessToken != null) {
      await _storage.write(key: ApiConstants.tokenKey, value: response.session!.accessToken);
    }

    return await syncUserProfile();
  }

  /// Sign Up with Email & Password
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'fullName': fullName.trim(),
        if (phone != null) 'phone': phone.trim(),
      },
      emailRedirectTo: 'physioprime://auth-callback',
    );

    if (response.session?.accessToken != null) {
      await _storage.write(key: ApiConstants.tokenKey, value: response.session!.accessToken);
      await syncUserProfile();
    }
  }

  /// Google OAuth Sign In
  Future<bool> signInWithGoogle() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'physioprime://auth-callback',
    );
  }

  /// Send Password Reset Email
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'physioprime://reset-password',
    );
  }

  /// Synchronize User Profile from Backend API
  Future<UserModel> syncUserProfile() async {
    try {
      final res = await _apiClient.get('/auth/me');
      final userData = res.data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userData);
      await _storage.write(key: ApiConstants.userKey, value: user.id);
      return user;
    } catch (_) {
      // Fallback if /auth/me fails before profile completion
      final supaUser = currentSupabaseUser;
      return UserModel(
        id: supaUser?.id ?? '',
        email: supaUser?.email ?? '',
        fullName: supaUser?.userMetadata?['fullName'] ?? supaUser?.userMetadata?['name'],
        phone: supaUser?.phone,
      );
    }
  }

  /// Update Profile Details
  Future<UserModel> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    final payload = <String, dynamic>{};
    if (fullName != null) payload['fullName'] = fullName;
    if (phone != null) payload['phone'] = phone;

    final res = await _apiClient.patch('/auth/me', data: payload);
    final userData = res.data['user'] as Map<String, dynamic>;
    return UserModel.fromJson(userData);
  }

  /// Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _storage.delete(key: ApiConstants.tokenKey);
    await _storage.delete(key: ApiConstants.userKey);
  }
}
