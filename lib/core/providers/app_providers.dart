import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../network/api_client.dart';
import '../storage/device_identity_store.dart';
import '../storage/json_cache_store.dart';
import '../storage/secure_token_store.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/auth_session_store.dart';

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

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokenStore: ref.watch(secureTokenStoreProvider),
    deviceIdentityStore: ref.watch(deviceIdentityStoreProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStore: ref.watch(secureTokenStoreProvider),
    deviceIdentityStore: ref.watch(deviceIdentityStoreProvider),
  );
});

final authSessionStoreProvider = Provider<AuthSessionStore>((ref) {
  return AuthSessionStore(cacheStore: ref.watch(jsonCacheStoreProvider));
});
