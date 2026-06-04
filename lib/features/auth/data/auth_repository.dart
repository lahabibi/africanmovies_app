import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/secure_token_store.dart';
import '../domain/auth_device_session.dart';
import '../domain/auth_session.dart';
import '../domain/auth_verification_result.dart';
import 'device_metadata_service.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required SecureTokenStore tokenStore,
    required DeviceMetadataService deviceMetadataService,
  }) : _apiClient = apiClient,
       _tokenStore = tokenStore,
       _deviceMetadataService = deviceMetadataService;

  final ApiClient _apiClient;
  final SecureTokenStore _tokenStore;
  final DeviceMetadataService _deviceMetadataService;

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

  Future<AuthVerificationResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/auth/verify-otp',
        data: {
          'email': email.trim().toLowerCase(),
          'otp': otp.trim(),
          ...await _deviceMetadataService.verificationPayload(),
        },
      );

      final data = response.data;
      if (data == null) {
        throw const ApiException('Missing verification response');
      }

      final result = AuthVerificationResult.fromJson(data);
      await _tokenStore.saveTokens(
        AuthTokens(accessToken: result.session.token),
      );

      return result;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<AuthUser> updateUsername(String username) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/auth/update-username',
        data: {'username': username.trim()},
      );

      final data = response.data;
      final user = data?['user'];
      if (user is! Map) {
        throw const ApiException('Missing updated profile');
      }

      return AuthUser.fromJson(Map<String, dynamic>.from(user));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<String> uploadProfileImage({
    required String filePath,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/auth/upload',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final fileLocation = response.data?['fileLocation'];
      if (fileLocation is! String || fileLocation.trim().isEmpty) {
        throw const ApiException('Missing uploaded profile image');
      }

      return fileLocation;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> deleteProfileImage() async {
    try {
      await _apiClient.delete<dynamic>('/auth/profileimage');
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return;
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

  Future<List<AuthDeviceSession>> fetchDevices() async {
    try {
      final response = await _apiClient.get<dynamic>('/auth/devices');
      final data = response.data;

      if (data is List) {
        return data.whereType<Map>().map((item) {
          return AuthDeviceSession.fromJson(Map<String, dynamic>.from(item));
        }).toList();
      }

      if (data is Map && data['devices'] is List) {
        return (data['devices'] as List).whereType<Map>().map((item) {
          return AuthDeviceSession.fromJson(Map<String, dynamic>.from(item));
        }).toList();
      }

      throw const ApiException('Missing logged in devices');
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> enrichCurrentDevice() async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '/auth/devices/enrich',
        data: await _deviceMetadataService.enrichPayload(),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> logoutDevice(String id) async {
    try {
      await _apiClient.post<Map<String, dynamic>>('/auth/devices/logout/$id');
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> logoutOtherDevices() async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '/auth/devices/logout-others',
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> logoutAllDevices() async {
    try {
      await _apiClient.post<Map<String, dynamic>>('/auth/logout-all');
      await _tokenStore.clear();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
