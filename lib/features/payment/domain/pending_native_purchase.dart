import 'payment_gateway.dart';

class PendingNativePurchase {
  final String userId;
  final String txRef;
  final String movieId;
  final String productId;
  final String platform;
  final DateTime createdAt;
  final NativePurchaseVerificationData? verificationData;

  const PendingNativePurchase({
    required this.userId,
    required this.txRef,
    required this.movieId,
    required this.productId,
    required this.platform,
    required this.createdAt,
    this.verificationData,
  });

  factory PendingNativePurchase.fromJson(Map<String, dynamic> json) {
    final rawVerificationData = json['verificationData'];

    return PendingNativePurchase(
      userId: json['userId']?.toString() ?? '',
      txRef: json['txRef']?.toString() ?? '',
      movieId: json['movieId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      verificationData: rawVerificationData is Map
          ? NativePurchaseVerificationData.fromJson(
              Map<String, dynamic>.from(rawVerificationData),
            )
          : null,
    );
  }

  PendingNativePurchase copyWith({
    String? userId,
    String? txRef,
    String? movieId,
    String? productId,
    String? platform,
    DateTime? createdAt,
    NativePurchaseVerificationData? verificationData,
  }) {
    return PendingNativePurchase(
      userId: userId ?? this.userId,
      txRef: txRef ?? this.txRef,
      movieId: movieId ?? this.movieId,
      productId: productId ?? this.productId,
      platform: platform ?? this.platform,
      createdAt: createdAt ?? this.createdAt,
      verificationData: verificationData ?? this.verificationData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'txRef': txRef,
      'movieId': movieId,
      'productId': productId,
      'platform': platform,
      'createdAt': createdAt.toIso8601String(),
      if (verificationData != null)
        'verificationData': verificationData!.toJson(),
    };
  }
}
