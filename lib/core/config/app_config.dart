import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const productionApiBaseUrl = 'https://api.africanmovies.com/api';
  static const localNetworkDevApiBaseUrl = 'http://172.20.10.9:3200/api';
  static const androidEmulatorDevApiBaseUrl = 'http://10.0.2.2:3200/api';

  static const _apiBaseUrlOverride = String.fromEnvironment(
    'AFRICAN_MOVIES_API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    return resolveApiBaseUrl(
      isRelease: kReleaseMode,
      override: _apiBaseUrlOverride,
    );
  }

  static String resolveApiBaseUrl({
    required bool isRelease,
    String override = '',
  }) {
    final normalizedOverride = override.trim();
    if (normalizedOverride.isNotEmpty) return normalizedOverride;

    return isRelease ? productionApiBaseUrl : localNetworkDevApiBaseUrl;
  }

  static const requestTimeout = Duration(seconds: 20);
}
