import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_exception.dart';
import '../storage/device_identity_store.dart';
import '../storage/secure_token_store.dart';

class ApiClient {
  ApiClient({
    required SecureTokenStore tokenStore,
    required DeviceIdentityStore deviceIdentityStore,
    Future<void> Function(ApiException exception)? onAuthSessionExpired,
    Dio? dio,
  }) : _tokenStore = tokenStore,
       _deviceIdentityStore = deviceIdentityStore,
       _onAuthSessionExpired = onAuthSessionExpired,
       dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: AppConfig.apiBaseUrl,
               connectTimeout: AppConfig.requestTimeout,
               receiveTimeout: AppConfig.requestTimeout,
               sendTimeout: AppConfig.requestTimeout,
               headers: const {
                 'Accept': 'application/json',
                 'Content-Type': 'application/json',
               },
             ),
           ) {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStore.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['x-auth-token'] = token;
            options.headers['x-device-id'] = await _deviceIdentityStore
                .readOrCreateDeviceId();
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          final exception = ApiException.fromDio(error);
          final requestWasAuthenticated = error.requestOptions.headers
              .containsKey('x-auth-token');

          if (requestWasAuthenticated && exception.isAuthSessionExpired) {
            await _onAuthSessionExpired?.call(exception);
          }

          handler.next(error);
        },
      ),
    );
  }

  final SecureTokenStore _tokenStore;
  final DeviceIdentityStore _deviceIdentityStore;
  final Future<void> Function(ApiException exception)? _onAuthSessionExpired;
  final Dio dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
