class SavedPaymentMethod {
  final String id;
  final String email;
  final String cardType;
  final String first6Digits;
  final String last4Digits;
  final String expiry;
  final String country;
  final DateTime? tokenRefreshDate;
  final bool isNewPay;

  const SavedPaymentMethod({
    required this.id,
    required this.email,
    required this.cardType,
    required this.first6Digits,
    required this.last4Digits,
    required this.expiry,
    required this.country,
    this.tokenRefreshDate,
    required this.isNewPay,
  });

  bool get isEmpty => last4Digits.isEmpty;

  bool get needsRefresh {
    final refreshDate = tokenRefreshDate;
    if (refreshDate == null) return false;

    return !DateTime.now().isBefore(refreshDate);
  }

  String get displayCardType {
    final value = cardType.trim();
    if (value.isEmpty) return 'Card';

    return value.toUpperCase();
  }

  String get maskedNumber {
    if (last4Digits.isEmpty) return '••••  ••••  ••••';

    return '••••  ••••  ••••  $last4Digits';
  }

  factory SavedPaymentMethod.fromJson(Map<String, dynamic> json) {
    return SavedPaymentMethod(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      cardType: json['cardType']?.toString() ?? '',
      first6Digits: json['first6Digits']?.toString() ?? '',
      last4Digits: json['last4Digits']?.toString() ?? '',
      expiry: json['expiry']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      tokenRefreshDate: DateTime.tryParse(json['tokenDate']?.toString() ?? ''),
      isNewPay: json['isNewPay'] == true,
    );
  }
}
