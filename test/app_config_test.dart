import 'package:africanmovies/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release builds use the production API by default', () {
    expect(
      AppConfig.resolveApiBaseUrl(isRelease: true),
      AppConfig.productionApiBaseUrl,
    );
  });

  test('debug builds use the production API unless explicitly overridden', () {
    expect(
      AppConfig.resolveApiBaseUrl(isRelease: false),
      AppConfig.productionApiBaseUrl,
    );
  });

  test('release builds ignore compile-time API overrides', () {
    const override = 'https://api-preview.africanmovies.com/api';

    expect(
      AppConfig.resolveApiBaseUrl(isRelease: true, override: override),
      AppConfig.productionApiBaseUrl,
    );
  });

  test('debug builds accept compile-time HTTPS API overrides', () {
    const override = 'https://api-preview.africanmovies.com/api';

    expect(
      AppConfig.resolveApiBaseUrl(isRelease: false, override: override),
      override,
    );
  });

  test('debug builds accept compile-time local API overrides', () {
    const override = 'http://192.0.2.10:3200/api';

    expect(
      AppConfig.resolveApiBaseUrl(isRelease: false, override: override),
      override,
    );
  });
}
