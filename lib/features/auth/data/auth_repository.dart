import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/device_identity_store.dart';
import '../../../core/storage/secure_token_store.dart';
import '../domain/auth_session.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required SecureTokenStore tokenStore,
    required DeviceIdentityStore deviceIdentityStore,
  }) : _apiClient = apiClient,
       _tokenStore = tokenStore,
       _deviceIdentityStore = deviceIdentityStore;

  final ApiClient _apiClient;
  final SecureTokenStore _tokenStore;
  final DeviceIdentityStore _deviceIdentityStore;

  Future<void> requestOtp(String email) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '/auth/request-otp',
        data: {'email': email.trim().toLowerCase()},
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<AuthSession> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/auth/verify-otp',
        data: {
          'email': email.trim().toLowerCase(),
          'otp': otp.trim(),
          ...await _devicePayload(),
        },
      );

      final data = response.data;
      if (data == null) {
        throw const ApiException('Missing verification response');
      }

      final session = AuthSession.fromJson(data);
      await _tokenStore.saveTokens(AuthTokens(accessToken: session.token));

      return session;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> signOut() async {
    try {
      await _apiClient.post<Map<String, dynamic>>('/auth/logout');
    } on DioException {
      // Local sign-out should still succeed if the server session is gone.
    } finally {
      await _tokenStore.clear();
    }
  }

  Future<Map<String, String>> _devicePayload() async {
    final platform = defaultTargetPlatform.name;

    return {
      'deviceId': await _deviceIdentityStore.readOrCreateDeviceId(),
      'deviceType': _deviceTypeForPlatform(defaultTargetPlatform),
      'deviceName': 'AfricanMovies App',
      'platform': platform,
      'os': platform,
      'userAgentName': 'AfricanMovies Flutter',
    };
  }

  String _deviceTypeForPlatform(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.android || TargetPlatform.iOS => 'Mobile',
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux => 'Desktop',
      TargetPlatform.fuchsia => 'Unknown',
    };
  }
}
