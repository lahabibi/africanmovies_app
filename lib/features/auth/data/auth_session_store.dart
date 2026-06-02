import '../../../core/storage/json_cache_store.dart';
import '../domain/auth_session.dart';

class AuthSessionStore {
  AuthSessionStore({required JsonCacheStore cacheStore})
    : _cacheStore = cacheStore;

  static const _cacheKey = 'auth.session';

  final JsonCacheStore _cacheStore;

  Future<AuthSession?> read() async {
    final cached = await _cacheStore.read(_cacheKey);
    final data = cached?.data;
    if (data is! Map) return null;

    return AuthSession.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> save(AuthSession session) {
    return _cacheStore.write(_cacheKey, session.toJson());
  }

  Future<void> clear() {
    return _cacheStore.remove(_cacheKey);
  }
}
