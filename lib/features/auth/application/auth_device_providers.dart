import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../domain/auth_device_session.dart';

final authDevicesProvider = FutureProvider.autoDispose<List<AuthDeviceSession>>(
  (ref) async {
    final repository = ref.watch(authRepositoryProvider);
    try {
      await repository.enrichCurrentDevice();
    } catch (_) {
      // Device enrichment should not block showing active sessions.
    }

    return repository.fetchDevices();
  },
);
