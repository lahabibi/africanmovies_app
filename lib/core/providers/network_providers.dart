import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../network/network_status.dart';

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final internetConnectionProvider = Provider<InternetConnection>((ref) {
  final connectivity = ref.watch(connectivityProvider);

  return InternetConnection.createInstance(
    checkInterval: const Duration(seconds: 5),
    triggerStream: connectivity.onConnectivityChanged,
  );
});

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) async* {
  final connectivity = ref.watch(connectivityProvider);
  final internetConnection = ref.watch(internetConnectionProvider);

  yield await _resolveNetworkStatus(connectivity, internetConnection);

  try {
    await for (final status in internetConnection.onStatusChange) {
      yield _networkStatusFromInternetStatus(status);
    }
  } catch (_) {
    yield NetworkStatus.offline;
  }
});

Future<NetworkStatus> _resolveNetworkStatus(
  Connectivity connectivity,
  InternetConnection internetConnection,
) async {
  try {
    final connectivityResults = await connectivity.checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none)) {
      return NetworkStatus.offline;
    }
  } catch (_) {
    // If the platform connectivity channel is unavailable, still try the
    // reachability check before declaring the app offline.
  }

  try {
    final hasInternetAccess = await internetConnection.hasInternetAccess;
    return hasInternetAccess ? NetworkStatus.online : NetworkStatus.offline;
  } catch (_) {
    return NetworkStatus.offline;
  }
}

NetworkStatus _networkStatusFromInternetStatus(InternetStatus status) {
  return switch (status) {
    InternetStatus.connected => NetworkStatus.online,
    InternetStatus.disconnected => NetworkStatus.offline,
  };
}
