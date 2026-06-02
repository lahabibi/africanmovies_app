class AppConfig {
  AppConfig._();

  static const defaultDevApiBaseUrl = 'http://localhost:3200/api';

  static const apiBaseUrl = String.fromEnvironment(
    'AFRICAN_MOVIES_API_BASE_URL',
    defaultValue: defaultDevApiBaseUrl,
  );

  static const requestTimeout = Duration(seconds: 20);
}
