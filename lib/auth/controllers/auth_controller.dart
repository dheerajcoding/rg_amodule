import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../models/auth_state.dart';
import '../models/user_model.dart';
import '../repository/auth_repository.dart';
import '../../models/role_enum.dart';

/// Orchestrates all authentication flows.
///
/// - Listens to Supabase [onAuthStateChange] stream for automatic state sync.
/// - Handles signup, login, logout and guest sessions.
/// - Exposes [AuthState] to the UI via Riverpod.
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthInitial()) {
    _init();
  }

  final AuthRepository _repository;
  StreamSubscription<supa.AuthState>? _authSub;

  // ── Initialisation ────────────────────────────────────────────────────────
  void _init() {
    _authSub = _repository.authStateStream.listen(
      _handleSupabaseAuthEvent,
      onError: (_) => state = const AuthUnauthenticated(),
    );
    // Safety fallback: if onAuthStateChange doesn't emit initialSession
    // before the first frame (can happen when the event fired before we
    // subscribed), check the current session synchronously.
    Future.microtask(() async {
      if (state is! AuthInitial) return; // stream already handled it
      final session = _repository.currentSession;
      if (session == null) {
        state = const AuthUnauthenticated();
      } else {
        await _loadProfile(session.user);
      }
    });
  }

  /// Reacts to every Supabase auth event (initial session, sign-in,
  /// token-refresh, sign-out, user-deleted, etc.)
  Future<void> _handleSupabaseAuthEvent(supa.AuthState event) async {
    final session = event.session;

    switch (event.event) {
      // ── App started with a saved session (auto-login) ─────────────────────
      case supa.AuthChangeEvent.initialSession:
        if (session == null) {
          state = const AuthUnauthenticated();
          return;
        }
        await _loadProfile(session.user);

      // ── User just signed in / signed up ───────────────────────────────────
      case supa.AuthChangeEvent.signedIn:
      case supa.AuthChangeEvent.tokenRefreshed:
      case supa.AuthChangeEvent.userUpdated:
        if (session != null) await _loadProfile(session.user);

      // ── User signed out or session expired ────────────────────────────────
      case supa.AuthChangeEvent.signedOut:
      case supa.AuthChangeEvent.userDeleted:
        state = const AuthUnauthenticated();

      default:
        break;
    }
  }

  /// Fetches the profile row and transitions to [AuthAuthenticated].
  /// Falls back to a minimal model built from auth metadata if profile is
  /// missing (e.g. email confirmation pending / trigger race).
  Future<void> _loadProfile(supa.User authUser) async {
    try {
      var profile = await _repository.fetchProfile(authUser.id);

      if (profile != null) {
        // Profiles table has no email column — fill it from auth.users
        if (profile.email.isEmpty && authUser.email != null) {
          profile = profile.copyWith(email: authUser.email);
        }
        state = AuthAuthenticated(profile);
      } else {
        // Build minimal model from auth metadata until profile is ready.
        final meta = authUser.userMetadata ?? {};
        state = AuthAuthenticated(
          UserModel(
            id: authUser.id,
            name: (meta['full_name'] as String?) ??
                (meta['name'] as String?) ??
                authUser.email?.split('@').first ??
                'User',
            email: authUser.email ?? '',
            role: UserRole.values.firstWhere(
              (r) => r.name == (meta['role'] as String?),
              orElse: () => UserRole.user,
            ),
            createdAt: DateTime.tryParse(authUser.createdAt),
          ),
        );
      }
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  // ── Sign-up ──────────────────────────────────────────────────────────────
  /// Creates a new account.
  ///
  /// On success the [onAuthStateChange] stream fires [AuthChangeEvent.signedIn]
  /// (if email confirmations are disabled) and this controller handles the rest.
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repository.signUp(
        name: name,
        email: email,
        password: password,
      );
      // If email confirmation is required the stream won't fire; show the
      // authenticated state optimistically so the user sees a welcome screen.
      // The session will be null until they confirm.
      if (supa.Supabase.instance.client.auth.currentSession != null) {
        state = AuthAuthenticated(user);
      } else {
        // Email confirmation required — inform the UI.
        state = AuthEmailConfirmationPending(email: email);
      }
    } on AuthRepositoryException catch (e) {
      state = AuthError(e.message);
    } catch (_) {
      state = const AuthError('Sign-up failed. Please try again.');
    }
  }

  // ── Login ────────────────────────────────────────────────────────────────
  /// Signs in with email and password.
  Future<void> login({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      await _repository.signIn(email: email, password: password);
      // The [onAuthStateChange] stream fires [AuthChangeEvent.signedIn]
      // automatically — [_handleSupabaseAuthEvent] handles the rest.
    } on AuthRepositoryException catch (e) {
      state = AuthError(e.message);
    } catch (_) {
      state = const AuthError('Login failed. Please try again.');
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _repository.signOut();
      // Stream fires [AuthChangeEvent.signedOut] → sets AuthUnauthenticated.
    } catch (_) {
      state = const AuthUnauthenticated(); // ensure clean state
    }
  }

  // ── Guest ─────────────────────────────────────────────────────────────────
  /// Allows browsing without an account.
  void continueAsGuest() {
    state = AuthAuthenticated(UserModel.guest());
  }

  // ── Password reset ────────────────────────────────────────────────────────
  Future<void> sendPasswordReset(String email) async {
    try {
      await _repository.sendPasswordReset(email);
    } on AuthRepositoryException catch (e) {
      state = AuthError(e.message);
    } catch (_) {
      state =
          const AuthError('Could not send reset email. Please try again.');
    }
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // ── Convenience getters ───────────────────────────────────────────────────
  UserModel? get currentUser =>
      state is AuthAuthenticated ? (state as AuthAuthenticated).user : null;

  bool get isAuthenticated =>
      state is AuthAuthenticated && currentUser?.role != UserRole.guest;
}
