import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdentityStore {
  static const _deviceIdKey = 'device.id';

  Future<String> readOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existingId = prefs.getString(_deviceIdKey);
    if (existingId != null && existingId.isNotEmpty) return existingId;

    final deviceId = _generateDeviceId();
    await prefs.setString(_deviceIdKey, deviceId);

    return deviceId;
  }

  String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }
}
