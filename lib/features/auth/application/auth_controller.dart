import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../domain/auth_session.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
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

  Future<AuthSession> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final previousSession = state.asData?.value;
    state = const AsyncLoading();

    try {
      final session = await ref
          .read(authRepositoryProvider)
          .verifyOtp(email: email, otp: otp);

      await ref.read(authSessionStoreProvider).save(session);
      state = AsyncData(session);
      return session;
    } catch (error, stackTrace) {
      state = AsyncData(previousSession);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();

    await ref.read(authRepositoryProvider).signOut();
    await ref.read(authSessionStoreProvider).clear();

    state = const AsyncData(null);
  }
}
