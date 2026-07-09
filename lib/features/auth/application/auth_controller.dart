import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/app_providers.dart';
import '../domain/auth_session.dart';
import '../domain/auth_verification_result.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    ref.watch(authSessionInvalidationProvider);

    final tokenStore = ref.watch(secureTokenStoreProvider);
    final sessionStore = ref.watch(authSessionStoreProvider);

    final token = await tokenStore.readAccessToken();
    if (token == null || token.isEmpty) {
      await sessionStore.clear();
      return null;
    }

    final cachedSession = await sessionStore.read();
    if (cachedSession != null) {
      if (cachedSession.token == token) return cachedSession;

      final session = AuthSession(token: token, user: cachedSession.user);
      await sessionStore.save(session);
      return session;
    }

    try {
      final session = AuthSession.fromToken(token);
      await sessionStore.save(session);
      return session;
    } on FormatException {
      await tokenStore.clear();
      return null;
    }
  }

  Future<AuthVerificationResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final previousSession = state.asData?.value;
    state = const AsyncLoading();

    try {
      final result = await ref
          .read(authRepositoryProvider)
          .verifyOtp(email: email, otp: otp);
      final session = result.session;

      await ref.read(authSessionStoreProvider).save(session);
      state = AsyncData(session);
      return result;
    } catch (error, stackTrace) {
      state = AsyncData(previousSession);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<AuthSession> updateUsername(String username) async {
    final currentSession = _requireSession();
    final updatedUser = await ref
        .read(authRepositoryProvider)
        .updateUsername(username);

    final session = currentSession.copyWith(
      user: _mergeUser(currentSession.user, updatedUser),
    );

    await _saveSession(session);
    return session;
  }

  Future<AuthSession> uploadProfileImage({
    required String filePath,
    required String fileName,
  }) async {
    final currentSession = _requireSession();
    final profileUrl = await ref
        .read(authRepositoryProvider)
        .uploadProfileImage(filePath: filePath, fileName: fileName);

    final session = currentSession.copyWith(
      user: currentSession.user.copyWith(profileUrl: profileUrl),
    );

    await _saveSession(session);
    return session;
  }

  Future<AuthSession> deleteProfileImage() async {
    final currentSession = _requireSession();
    await ref.read(authRepositoryProvider).deleteProfileImage();

    final session = currentSession.copyWith(
      user: currentSession.user.copyWith(
        profileUrl: AuthUser.defaultProfileUrl,
      ),
    );

    await _saveSession(session);
    return session;
  }

  Future<void> signOut() async {
    state = const AsyncLoading();

    await ref.read(authRepositoryProvider).signOut();
    await ref.read(authSessionStoreProvider).clear();

    state = const AsyncData(null);
  }

  Future<void> deleteAccount() async {
    final previousSession = state.asData?.value;
    state = const AsyncLoading();

    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      await ref.read(authSessionStoreProvider).clear();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncData(previousSession);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> signOutAllDevices() async {
    final previousSession = state.asData?.value;
    state = const AsyncLoading();

    try {
      await ref.read(authRepositoryProvider).logoutAllDevices();
      await ref.read(authSessionStoreProvider).clear();

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncData(previousSession);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<bool> validateCurrentSession() async {
    final session = state.asData?.value;
    if (session == null) return false;

    try {
      await ref.read(authRepositoryProvider).fetchDevices();
      return true;
    } catch (error) {
      if (error is ApiException && error.isAuthSessionExpired) {
        await ref.read(secureTokenStoreProvider).clear();
        await ref.read(authSessionStoreProvider).clear();
        state = const AsyncData(null);

        return false;
      }

      return true;
    }
  }

  AuthSession _requireSession() {
    final session = state.asData?.value;
    if (session == null) {
      throw const ApiException('Sign in to update your profile.');
    }

    return session;
  }

  Future<void> _saveSession(AuthSession session) async {
    await ref.read(authSessionStoreProvider).save(session);
    state = AsyncData(session);
  }

  AuthUser _mergeUser(AuthUser currentUser, AuthUser updatedUser) {
    return currentUser.copyWith(
      id: updatedUser.id.isNotEmpty ? updatedUser.id : currentUser.id,
      email: updatedUser.email.isNotEmpty
          ? updatedUser.email
          : currentUser.email,
      username: updatedUser.username.isNotEmpty
          ? updatedUser.username
          : currentUser.username,
      profileUrl: updatedUser.profileUrl ?? currentUser.profileUrl,
    );
  }
}
