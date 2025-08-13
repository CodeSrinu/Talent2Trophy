import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/services/auth_service.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/network_info.dart';
import '../../../profile/data/profile_repository.dart';

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

// Offline-aware current user provider: serves cache first, then Firestore when online
final currentUserProvider = StreamProvider<UserModel?>((ref) async* {
  final authService = ref.watch(authServiceProvider);

  await for (final fbUser in authService.authStateChanges) {
    if (fbUser == null) {
      yield null;
      continue;
    }

    final prefs = await SharedPreferences.getInstance();
    final repo = ProfileRepository(FirebaseFirestore.instance, prefs, NetworkInfo());

    // Try flushing any pending local updates when we have connectivity
    if (await NetworkInfo().isConnected) {
      await repo.flushPending(fbUser.uid);
    }

    // Emit cached user immediately; then keep streaming Firestore changes when online
    try {
      yield* repo.watchUser(fbUser.uid);
    } catch (_) {
      // If snapshot stream errors (e.g., permission issues during sign-out),
      // treat as unauthenticated state instead of erroring the app.
      yield null;
    }
  }
});

// Auth state class
class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  // Sign in
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = await _authService.getUserData(_authService.currentUserId!);

      state = state.copyWith(
        isLoading: false,
        user: user,
        isAuthenticated: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Sign up
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String userType,
  }) async {
    print('AuthProvider: signUp called with email: $email, name: $name, userType: $userType');
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('AuthProvider: Calling authService.signUpWithEmailAndPassword');
      await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        userType: userType,
      );

      print('AuthProvider: User created successfully, getting user data');
      final user = await _authService.getUserData(_authService.currentUserId!);

      print('AuthProvider: User data retrieved: ${user?.email}');

      state = state.copyWith(
        isLoading: false,
        user: user,
        isAuthenticated: true,
      );

      print('AuthProvider: Sign up completed successfully');
    } catch (e) {
      print('AuthProvider: Sign up failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.signOut();

      state = state.copyWith(
        isLoading: false,
        user: null,
        isAuthenticated: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.resetPassword(email);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Update user data
  Future<void> updateUserData(Map<String, dynamic> data) async {
    if (state.user == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final prefs = await SharedPreferences.getInstance();
      final repo = ProfileRepository(FirebaseFirestore.instance, prefs, NetworkInfo());

      await repo.updateUser(state.user!.id, data);

      final updatedUser = await repo.getUser(state.user!.id);

      state = state.copyWith(
        isLoading: false,
        user: updatedUser,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Request scout verification
  Future<void> requestScoutVerification({
    required String organization,
    required String designation,
    required String experience,
    required List<String> specializations,
    required String documentUrl,
  }) async {
    if (state.user == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.requestScoutVerification(
        userId: state.user!.id,
        organization: organization,
        designation: designation,
        experience: experience,
        specializations: specializations,
        documentUrl: documentUrl,
      );

      final updatedUser = await _authService.getUserData(state.user!.id);

      state = state.copyWith(
        isLoading: false,
        user: updatedUser,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Set user
  void setUser(UserModel user) {
    state = state.copyWith(
      user: user,
      isAuthenticated: true,
    );
  }
}
