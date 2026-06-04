import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import '../../../core/storage/device_identity_store.dart';

class DeviceMetadataService {
  DeviceMetadataService({
    required DeviceIdentityStore deviceIdentityStore,
    DeviceInfoPlugin? deviceInfoPlugin,
  }) : _deviceIdentityStore = deviceIdentityStore,
       _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin();

  final DeviceIdentityStore _deviceIdentityStore;
  final DeviceInfoPlugin _deviceInfoPlugin;

  Future<Map<String, String>> verificationPayload() async {
    return {
      'deviceId': await _deviceIdentityStore.readOrCreateDeviceId(),
      ...await enrichPayload(),
    };
  }

  Future<Map<String, String>> enrichPayload() async {
    try {
      final Future<Map<String, String>> payload =
          switch (defaultTargetPlatform) {
            TargetPlatform.iOS => _iosPayload(),
            TargetPlatform.android => _androidPayload(),
            TargetPlatform.macOS => _macOsPayload(),
            TargetPlatform.windows => _windowsPayload(),
            TargetPlatform.linux => _linuxPayload(),
            TargetPlatform.fuchsia => Future.value(_fallbackPayload()),
          };

      return await payload;
    } catch (_) {
      return _fallbackPayload();
    }
  }

  Future<Map<String, String>> _iosPayload() async {
    final info = await _deviceInfoPlugin.iosInfo;
    final model = _firstNonEmpty([
      info.name,
      info.modelName,
      info.model,
      info.utsname.machine,
    ]);

    return {
      'deviceType': 'Mobile',
      'deviceName': model ?? 'iPhone',
      'platform': 'iOS',
      'os': 'iOS ${info.systemVersion}'.trim(),
      'userAgentName': 'AfricanMovies iOS',
    };
  }

  Future<Map<String, String>> _androidPayload() async {
    final info = await _deviceInfoPlugin.androidInfo;
    final maker = info.manufacturer.trim();
    final model = info.model.trim();
    final name = [
      maker,
      model,
    ].where((value) => value.isNotEmpty).join(' ').trim();

    return {
      'deviceType': 'Mobile',
      'deviceName': name.isEmpty ? 'Android Phone' : name,
      'platform': 'Android',
      'os': 'Android ${info.version.release}'.trim(),
      'userAgentName': 'AfricanMovies Android',
    };
  }

  Future<Map<String, String>> _macOsPayload() async {
    final info = await _deviceInfoPlugin.macOsInfo;

    return {
      'deviceType': 'Desktop',
      'deviceName': info.computerName.isEmpty
          ? info.modelName
          : info.computerName,
      'platform': 'macOS',
      'os': 'macOS ${info.osRelease}'.trim(),
      'userAgentName': 'AfricanMovies macOS',
    };
  }

  Future<Map<String, String>> _windowsPayload() async {
    final info = await _deviceInfoPlugin.windowsInfo;

    return {
      'deviceType': 'Desktop',
      'deviceName': info.computerName.isEmpty
          ? 'Windows PC'
          : info.computerName,
      'platform': 'Windows',
      'os': 'Windows ${info.displayVersion}'.trim(),
      'userAgentName': 'AfricanMovies Windows',
    };
  }

  Future<Map<String, String>> _linuxPayload() async {
    final info = await _deviceInfoPlugin.linuxInfo;

    return {
      'deviceType': 'Desktop',
      'deviceName': _firstNonEmpty([info.prettyName, info.name]) ?? 'Linux PC',
      'platform': 'Linux',
      'os': _firstNonEmpty([info.prettyName, info.version]) ?? 'Linux',
      'userAgentName': 'AfricanMovies Linux',
    };
  }

  Map<String, String> _fallbackPayload() {
    final platform = defaultTargetPlatform.name;

    return {
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

  String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }

    return null;
  }
}
