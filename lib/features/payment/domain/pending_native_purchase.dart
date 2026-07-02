class PendingNativePurchase {
  final String userId;
  final String txRef;
  final String movieId;
  final String productId;
  final String platform;
  final DateTime createdAt;

  const PendingNativePurchase({
    required this.userId,
    required this.txRef,
    required this.movieId,
    required this.productId,
    required this.platform,
    required this.createdAt,
  });

  factory PendingNativePurchase.fromJson(Map<String, dynamic> json) {
    return PendingNativePurchase(
      userId: json['userId']?.toString() ?? '',
      txRef: json['txRef']?.toString() ?? '',
      movieId: json['movieId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
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
    };
  }
}
