import 'package:flutter/foundation.dart';
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
  SupabaseClient? _supabaseInstance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthRepository(this._apiClient, [this._supabaseInstance]);

  SupabaseClient get _supabase {
    if (_supabaseInstance != null) return _supabaseInstance!;
    try {
      _supabaseInstance = Supabase.instance.client;
      return _supabaseInstance!;
    } catch (_) {
      rethrow;
    }
  }

  User? get currentSupabaseUser {
    try {
      return _supabase.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  Session? get currentSession {
    try {
      return _supabase.auth.currentSession;
    } catch (_) {
      return null;
    }
  }

  bool get isAuthenticated => currentSession != null;

  /// Listen to Supabase Auth state changes (OAuth redirects, token refresh, sign-in/out)
  void listenAuthStateChanges(void Function(Session? session) onSessionChange) {
    try {
      _supabase.auth.onAuthStateChange.listen((data) async {
        if (data.session?.accessToken != null) {
          await _storage.write(key: ApiConstants.tokenKey, value: data.session!.accessToken);
        } else if (data.event == AuthChangeEvent.signedOut) {
          await _storage.delete(key: ApiConstants.tokenKey);
          await _storage.delete(key: ApiConstants.userKey);
        }
        onSessionChange(data.session);
      });
    } catch (_) {
      // Safe fallback when running in offline or test environments
    }
  }

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
      emailRedirectTo: kIsWeb ? '${Uri.base.origin}/' : 'physioprime://auth-callback',
    );

    if (response.session?.accessToken != null) {
      await _storage.write(key: ApiConstants.tokenKey, value: response.session!.accessToken);
      await syncUserProfile();
    }
  }

  /// Google OAuth Sign In
  Future<bool> signInWithGoogle() async {
    final redirectUrl = kIsWeb
        ? '${Uri.base.origin}/'
        : 'physioprime://auth-callback';
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
    );
  }

  /// Send Password Reset Email
  Future<void> resetPassword(String email) async {
    final redirectUrl = kIsWeb
        ? '${Uri.base.origin}/forgot-password'
        : 'physioprime://reset-password';
    await _supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectUrl,
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
      final meta = supaUser?.userMetadata ?? {};
      return UserModel(
        id: supaUser?.id ?? '',
        email: supaUser?.email ?? '',
        fullName: meta['fullName'] ?? meta['name'] ?? meta['full_name'],
        phone: supaUser?.phone ?? meta['phone'],
        gender: meta['gender']?.toString(),
        dateOfBirth: meta['dob']?.toString() ?? meta['dateOfBirth']?.toString() ?? meta['date_of_birth']?.toString(),
        weight: meta['weight']?.toString(),
        height: meta['height']?.toString(),
        address: UserModel.parseAddress(meta['address']),
      );
    }
  }

  /// Update Profile Details
  Future<UserModel> updateProfile({
    String? fullName,
    String? phone,
    String? gender,
    String? dateOfBirth,
    String? weight,
    String? height,
    String? address,
  }) async {
    final payload = <String, dynamic>{};
    if (fullName != null) {
      payload['name'] = fullName;
      payload['fullName'] = fullName;
    }
    if (phone != null) payload['phone'] = phone;
    if (gender != null) {
      payload['gender'] = gender.toLowerCase();
    }
    if (dateOfBirth != null) {
      final iso = UserModel.toIsoDate(dateOfBirth) ?? dateOfBirth;
      payload['dob'] = iso;
      payload['dateOfBirth'] = iso;
      payload['date_of_birth'] = iso;
    }
    if (weight != null) payload['weight'] = weight;
    if (height != null) payload['height'] = height;
    if (address != null) {
      payload['address'] = {'text': address};
    }

    try {
      final res = await _apiClient.patch('/auth/me', data: payload);
      final userRaw = res.data is Map ? (res.data['user'] ?? res.data) : res.data;
      final Map<String, dynamic> userData = userRaw is Map<String, dynamic>
          ? userRaw
          : Map<String, dynamic>.from(userRaw as Map);
      return UserModel.fromJson(userData);
    } catch (_) {
      // Fallback to update Supabase user metadata directly
      final supa = currentSupabaseUser;
      if (supa != null) {
        final currentMeta = Map<String, dynamic>.from(supa.userMetadata ?? {});
        currentMeta.addAll(payload);
        await _supabase.auth.updateUser(UserAttributes(data: currentMeta));
        return UserModel(
          id: supa.id,
          email: supa.email ?? '',
          fullName: currentMeta['fullName'] ?? currentMeta['name'] ?? currentMeta['full_name'],
          phone: phone ?? supa.phone,
          gender: currentMeta['gender']?.toString(),
          dateOfBirth: currentMeta['dob']?.toString() ?? currentMeta['dateOfBirth']?.toString() ?? currentMeta['date_of_birth']?.toString(),
          weight: currentMeta['weight']?.toString(),
          height: currentMeta['height']?.toString(),
          address: UserModel.parseAddress(currentMeta['address']),
        );
      }
      rethrow;
    }
  }

  /// Change Account Password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final supaUser = currentSupabaseUser;
    if (supaUser?.email != null && currentPassword.trim().isNotEmpty) {
      // Verify current password by signing in
      await _supabase.auth.signInWithPassword(
        email: supaUser!.email!,
        password: currentPassword.trim(),
      );
    }
    // Update password
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword.trim()),
    );
  }

  /// Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _storage.delete(key: ApiConstants.tokenKey);
    await _storage.delete(key: ApiConstants.userKey);
  }

  /// Request Permanent Account Deletion (Apple App Store Guideline 5.1.1(v))
  Future<void> deleteAccount() async {
    try {
      // 1. Notify backend to anonymize/delete patient data and past appointments
      await _apiClient.delete('/auth/me');
    } catch (_) {
      // Backend may also handle account deletion via Supabase DB triggers
    }

    try {
      // 2. Sign out and revoke local session
      await _supabase.auth.signOut();
    } catch (_) {}

    // 3. Clear all secure storage credentials
    await _storage.delete(key: ApiConstants.tokenKey);
    await _storage.delete(key: ApiConstants.userKey);
  }
}
