class AppConfig {
  AppConfig._();

  static const localNetworkDevApiBaseUrl = 'http://172.20.10.9:3200/api';
  static const androidEmulatorDevApiBaseUrl = 'http://10.0.2.2:3200/api';

  static const _apiBaseUrlOverride = String.fromEnvironment(
    'AFRICAN_MOVIES_API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;

    return localNetworkDevApiBaseUrl;
  }

  static const requestTimeout = Duration(seconds: 20);
}
