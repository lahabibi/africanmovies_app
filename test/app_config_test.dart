import 'package:africanmovies/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release builds use the production API by default', () {
    expect(
      AppConfig.resolveApiBaseUrl(isRelease: true),
      AppConfig.productionApiBaseUrl,
    );
  });

  test('debug builds use the local development API by default', () {
    expect(
      AppConfig.resolveApiBaseUrl(isRelease: false),
      AppConfig.localNetworkDevApiBaseUrl,
    );
  });

  test('compile-time API override takes precedence in every build mode', () {
    const override = 'https://staging-api.africanmovies.com/api';

    expect(
      AppConfig.resolveApiBaseUrl(isRelease: true, override: override),
      override,
    );
    expect(
      AppConfig.resolveApiBaseUrl(isRelease: false, override: override),
      override,
    );
  });
}
