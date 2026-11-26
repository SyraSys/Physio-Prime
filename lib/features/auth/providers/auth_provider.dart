import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(UserModel user) => AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated() => const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.error(String message) => AuthState(status: AuthStatus.error, errorMessage: message);
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return AuthNotifier(repo);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState.initial()) {
    checkCurrentSession();
    _repository.listenAuthStateChanges((session) async {
      if (session != null) {
        try {
          final user = await _repository.syncUserProfile();
          state = AuthState.authenticated(user);
        } catch (_) {
          final supaUser = _repository.currentSupabaseUser;
          if (supaUser != null) {
            final meta = supaUser.userMetadata ?? {};
            state = AuthState.authenticated(
              UserModel(
                id: supaUser.id,
                email: supaUser.email ?? '',
                fullName: meta['fullName'] ??
                    meta['name'] ??
                    meta['full_name'],
                phone: supaUser.phone ?? meta['phone'],
                gender: meta['gender']?.toString(),
                dateOfBirth: meta['dob']?.toString() ?? meta['dateOfBirth']?.toString() ?? meta['date_of_birth']?.toString(),
                weight: meta['weight']?.toString(),
                height: meta['height']?.toString(),
                address: UserModel.parseAddress(meta['address']),
              ),
            );
          } else {
            state = AuthState.unauthenticated();
          }
        }
      } else {
        state = AuthState.unauthenticated();
      }
    });
  }

  Future<void> checkCurrentSession() async {
    if (_repository.isAuthenticated) {
      try {
        final user = await _repository.syncUserProfile();
        state = AuthState.authenticated(user);
      } catch (_) {
        state = AuthState.unauthenticated();
      }
    } else {
      state = AuthState.unauthenticated();
    }
  }

  Future<bool> login(String email, String password) async {
    state = AuthState.loading();
    try {
      final user = await _repository.signInWithPassword(email: email, password: password);
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = AuthState.loading();
    try {
      await _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      if (_repository.isAuthenticated) {
        final user = await _repository.syncUserProfile();
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.unauthenticated();
      }
      return true;
    } catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    state = AuthState.loading();
    try {
      final success = await _repository.signInWithGoogle();
      return success;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _repository.resetPassword(email);
      return true;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? gender,
    String? dateOfBirth,
    String? weight,
    String? height,
    String? address,
  }) async {
    if (state.user == null) return;
    try {
      final updated = await _repository.updateProfile(
        fullName: fullName,
        phone: phone,
        gender: gender,
        dateOfBirth: dateOfBirth,
        weight: weight,
        height: height,
        address: address,
      );
      state = AuthState.authenticated(updated);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.signOut();
    state = AuthState.unauthenticated();
  }

  /// Request Permanent Account Deletion (Apple App Store Guideline 5.1.1(v))
  Future<bool> deleteAccount() async {
    state = AuthState.loading();
    try {
      await _repository.deleteAccount();
      state = AuthState.unauthenticated();
      return true;
    } catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}
