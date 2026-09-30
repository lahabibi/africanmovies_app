const appleRefundConsentVersion = 'v1';

class AppleRefundConsent {
  final String transactionId;
  final bool consented;
  final DateTime? consentedAt;
  final DateTime? withdrawnAt;
  final DateTime? updatedAt;
  final String? consentVersion;
  final String requiredConsentVersion;

  const AppleRefundConsent({
    required this.transactionId,
    required this.consented,
    this.consentedAt,
    this.withdrawnAt,
    this.updatedAt,
    this.consentVersion,
    required this.requiredConsentVersion,
  });

  factory AppleRefundConsent.fromJson(Map<String, dynamic> json) {
    return AppleRefundConsent(
      transactionId: json['transactionId']?.toString() ?? '',
      consented: json['consented'] == true,
      consentedAt: _readDate(json['consentedAt']),
      withdrawnAt: _readDate(json['withdrawnAt']),
      updatedAt: _readDate(json['updatedAt']),
      consentVersion: _readOptionalString(json['consentVersion']),
      requiredConsentVersion: json['requiredConsentVersion']?.toString() ?? '',
    );
  }

  bool get hasCurrentConsent {
    return consented &&
        requiredConsentVersion.isNotEmpty &&
        consentVersion == requiredConsentVersion;
  }
}

DateTime? _readDate(Object? value) {
  return DateTime.tryParse(value?.toString() ?? '');
}

String? _readOptionalString(Object? value) {
  final normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}
