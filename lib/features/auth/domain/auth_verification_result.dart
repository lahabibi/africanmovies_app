import 'auth_session.dart';

class AuthVerificationResult {
  final AuthSession session;
  final DeviceLimitNotice? deviceLimitNotice;

  const AuthVerificationResult({required this.session, this.deviceLimitNotice});

  factory AuthVerificationResult.fromJson(Map<String, dynamic> json) {
    return AuthVerificationResult(
      session: AuthSession.fromJson(json),
      deviceLimitNotice: DeviceLimitNotice.tryParse(json['deviceLimit']),
    );
  }
}

class DeviceLimitNotice {
  final String message;
  final String? revokedDevice;

  const DeviceLimitNotice({required this.message, this.revokedDevice});

  static DeviceLimitNotice? tryParse(Object? value) {
    if (value is! Map || value['reached'] != true) {
      return null;
    }

    final message = value['message']?.toString().trim();
    final revokedDevice = value['revokedDevice']?.toString().trim();

    return DeviceLimitNotice(
      message: message == null || message.isEmpty
          ? 'Device limit reached. We signed out your oldest inactive device.'
          : message,
      revokedDevice: revokedDevice == null || revokedDevice.isEmpty
          ? null
          : revokedDevice,
    );
  }
}
