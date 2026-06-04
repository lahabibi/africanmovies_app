import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../network/api_client.dart';
import '../storage/device_identity_store.dart';
import '../storage/json_cache_store.dart';
import '../storage/secure_token_store.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/auth_session_store.dart';
import '../../features/auth/data/device_metadata_service.dart';

final authSessionInvalidationProvider =
    NotifierProvider<AuthSessionInvalidationController, int>(
      AuthSessionInvalidationController.new,
    );

final authSessionExpiredMessageProvider =
    NotifierProvider<AuthSessionExpiredMessageController, String?>(
      AuthSessionExpiredMessageController.new,
    );

class AuthSessionInvalidationController extends Notifier<int> {
  @override
  int build() => 0;

  void invalidateSession() {
    state++;
  }
}

class AuthSessionExpiredMessageController extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String message) {
    state ??= message;
  }

  void clear() {
    state = null;
  }
}

final apiBaseUrlProvider = Provider<String>((ref) {
  return AppConfig.apiBaseUrl;
});

final secureTokenStoreProvider = Provider<SecureTokenStore>((ref) {
  return SecureTokenStore();
});

final jsonCacheStoreProvider = Provider<JsonCacheStore>((ref) {
  return JsonCacheStore();
});

final deviceIdentityStoreProvider = Provider<DeviceIdentityStore>((ref) {
  return DeviceIdentityStore();
});

final deviceMetadataServiceProvider = Provider<DeviceMetadataService>((ref) {
  return DeviceMetadataService(
    deviceIdentityStore: ref.watch(deviceIdentityStoreProvider),
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokenStore: ref.watch(secureTokenStoreProvider),
    deviceIdentityStore: ref.watch(deviceIdentityStoreProvider),
    onAuthSessionExpired: (exception) async {
      await ref.read(secureTokenStoreProvider).clear();
      await ref.read(authSessionStoreProvider).clear();

      ref
          .read(authSessionExpiredMessageProvider.notifier)
          .show(_authSessionExpiredMessage(exception.code));

      ref.read(authSessionInvalidationProvider.notifier).invalidateSession();
    },
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStore: ref.watch(secureTokenStoreProvider),
    deviceMetadataService: ref.watch(deviceMetadataServiceProvider),
  );
});

final authSessionStoreProvider = Provider<AuthSessionStore>((ref) {
  return AuthSessionStore(cacheStore: ref.watch(jsonCacheStoreProvider));
});

String _authSessionExpiredMessage(String? code) {
  if (code == 'INVALID_DEVICE') {
    return 'Your session expired because this account was signed in on another device. Please sign in again.';
  }

  if (code == 'TOKEN_EXPIRED') {
    return 'Your session expired. Please sign in again.';
  }

  return 'Please sign in again to continue.';
}
