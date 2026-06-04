class AuthDeviceSession {
  final String id;
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final String platform;
  final String os;
  final String? userAgentName;
  final String? ip;
  final String? city;
  final String? country;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;
  final bool isCurrent;

  const AuthDeviceSession({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.platform,
    required this.os,
    this.userAgentName,
    this.ip,
    this.city,
    this.country,
    this.createdAt,
    this.lastActiveAt,
    this.isCurrent = false,
  });

  factory AuthDeviceSession.fromJson(Map<String, dynamic> json) {
    return AuthDeviceSession(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      deviceId: json['deviceId']?.toString() ?? '',
      deviceName: json['deviceName']?.toString() ?? '',
      deviceType: json['deviceType']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      os: json['os']?.toString() ?? '',
      userAgentName: json['userAgentName']?.toString(),
      ip: json['ip']?.toString(),
      city: json['city']?.toString(),
      country: json['country']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      lastActiveAt: _parseDate(json['lastActiveAt']),
      isCurrent: json['isCurrent'] == true,
    );
  }

  String get displayName {
    final normalized = _clean(deviceName);
    if (normalized != null &&
        normalized.toLowerCase() != 'unknown device' &&
        normalized.toLowerCase() != 'africanmovies app') {
      return normalized;
    }

    final platformLabel = _clean(platform);
    final typeLabel = _clean(deviceType);
    if (platformLabel != null && typeLabel != null) {
      return '$platformLabel $typeLabel';
    }

    return platformLabel ?? typeLabel ?? 'Unknown device';
  }

  String get locationLabel {
    final validCity = _clean(city);
    final validCountry = _clean(country);
    if (validCity != null && validCountry != null) {
      return '$validCity, $validCountry';
    }

    return validCity ?? validCountry ?? _clean(ip) ?? 'Unknown location';
  }

  String get osLabel {
    return _clean(os) ?? _clean(platform) ?? 'Unknown OS';
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    if (trimmed.toLowerCase() == 'unknown') return null;

    return trimmed;
  }
}
