import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthTokens {
  final String accessToken;
  final String? refreshToken;

  const AuthTokens({required this.accessToken, this.refreshToken});
}

class SecureTokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'auth.access_token';
  static const _refreshTokenKey = 'auth.refresh_token';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token == null || token.isEmpty) return token;

    return _tokenWithoutBearer(token);
  }

  Future<String?> readRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<AuthTokens?> readTokens() async {
    final accessToken = await readAccessToken();
    if (accessToken == null || accessToken.isEmpty) return null;

    return AuthTokens(
      accessToken: accessToken,
      refreshToken: await readRefreshToken(),
    );
  }

  Future<void> saveTokens(AuthTokens tokens) async {
    await _storage.write(
      key: _accessTokenKey,
      value: _tokenWithoutBearer(tokens.accessToken),
    );

    final refreshToken = tokens.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await _storage.delete(key: _refreshTokenKey);
      return;
    }

    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  String _tokenWithoutBearer(String token) {
    final trimmed = token.trim();
    const prefix = 'bearer ';

    if (!trimmed.toLowerCase().startsWith(prefix)) return trimmed;

    return trimmed.substring(prefix.length).trim();
  }
}
