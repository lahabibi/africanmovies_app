import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const productionApiBaseUrl = 'https://api.africanmovies.com/api';

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
    if (isRelease) return productionApiBaseUrl;

    final normalizedOverride = override.trim();
    if (normalizedOverride.isNotEmpty) return normalizedOverride;

    return productionApiBaseUrl;
  }

  static const requestTimeout = Duration(seconds: 20);
}
