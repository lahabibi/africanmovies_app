import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class PaymentHistoryResponse {
  final List<PaymentHistoryItem> items;
  final PaymentHistorySummary summary;
  final PaymentHistoryPagination pagination;

  const PaymentHistoryResponse({
    required this.items,
    required this.summary,
    required this.pagination,
  });

  factory PaymentHistoryResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];

    return PaymentHistoryResponse(
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) => PaymentHistoryItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      summary: PaymentHistorySummary.fromJson(_readMap(json['summary'])),
      pagination: PaymentHistoryPagination.fromJson(
        _readMap(json['pagination']),
      ),
    );
  }
}

class PaymentHistoryItem {
  final String id;
  final String type;
  final String txRef;
  final PaymentHistoryMovie? movie;
  final PaymentHistoryOrder? order;
  final PaymentHistoryPayment? payment;
  final String accessStatus;
  final DateTime? createdAt;

  const PaymentHistoryItem({
    required this.id,
    required this.type,
    required this.txRef,
    this.movie,
    this.order,
    this.payment,
    required this.accessStatus,
    this.createdAt,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    final rawMovie = json['movie'];
    final rawOrder = json['order'];
    final rawPayment = json['payment'];

    return PaymentHistoryItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      txRef: json['txRef']?.toString() ?? '',
      movie: rawMovie is Map
          ? PaymentHistoryMovie.fromJson(Map<String, dynamic>.from(rawMovie))
          : null,
      order: rawOrder is Map
          ? PaymentHistoryOrder.fromJson(Map<String, dynamic>.from(rawOrder))
          : null,
      payment: rawPayment is Map
          ? PaymentHistoryPayment.fromJson(
              Map<String, dynamic>.from(rawPayment),
            )
          : null,
      accessStatus: json['accessStatus']?.toString() ?? 'unknown',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  String get title {
    final value = movie?.title.trim() ?? '';
    return value.isEmpty ? 'Movie purchase' : value;
  }

  String get posterUrl => movie?.posterUrl ?? movie?.bannerUrl ?? '';

  String get displayAmount {
    final amount = payment?.amount;
    if (amount == null) return 'Free';

    return '\$${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}';
  }

  String get displayDate => _formatDate(createdAt);

  String get paymentStatusLabel {
    final status = payment?.status.trim();
    if (status != null && status.isNotEmpty) return status;
    if (type == 'order') return 'Order';

    return 'Unknown';
  }

  String get accessStatusLabel {
    return switch (accessStatus.toLowerCase()) {
      'active' => 'Active',
      'expired' => 'Expired',
      'pending' => 'Pending',
      'failed' => 'Failed',
      'completed' => 'Completed',
      _ => 'Unknown',
    };
  }

  Color get accessStatusColor {
    return switch (accessStatus.toLowerCase()) {
      'active' => const Color(0xFF22C55E),
      'expired' => AppColors.warning,
      'pending' => const Color(0xFFFBBF24),
      'failed' => AppColors.danger,
      'completed' => AppColors.heroButton,
      _ => AppColors.textSecondary,
    };
  }

  String get txRefLabel {
    final value = txRef.trim();
    if (value.isEmpty) return 'N/A';
    if (value.length <= 12) return value;

    return '${value.substring(0, 6)}...${value.substring(value.length - 4)}';
  }
}

class PaymentHistoryMovie {
  final String id;
  final String title;
  final String genre;
  final String rating;
  final double price;
  final double duration;
  final String releaseYear;
  final String releaseType;
  final String posterUrl;
  final String bannerUrl;

  const PaymentHistoryMovie({
    required this.id,
    required this.title,
    required this.genre,
    required this.rating,
    required this.price,
    required this.duration,
    required this.releaseYear,
    required this.releaseType,
    required this.posterUrl,
    required this.bannerUrl,
  });

  factory PaymentHistoryMovie.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryMovie(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Movie',
      genre: json['genre']?.toString() ?? '',
      rating: json['rating']?.toString() ?? '',
      price: _readDouble(json['price']),
      duration: _readDouble(json['duration']),
      releaseYear: json['releaseYear']?.toString() ?? '',
      releaseType: json['releaseType']?.toString() ?? '',
      posterUrl: json['posterUrl']?.toString() ?? '',
      bannerUrl: json['bannerUrl']?.toString() ?? '',
    );
  }
}

class PaymentHistoryOrder {
  final String id;
  final String txRef;
  final String movieId;
  final bool paid;
  final bool active;
  final bool expired;
  final double currentTime;
  final bool startWatch;
  final DateTime? orderDate;
  final DateTime? expiryDate;

  const PaymentHistoryOrder({
    required this.id,
    required this.txRef,
    required this.movieId,
    required this.paid,
    required this.active,
    required this.expired,
    required this.currentTime,
    required this.startWatch,
    this.orderDate,
    this.expiryDate,
  });

  factory PaymentHistoryOrder.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryOrder(
      id: json['id']?.toString() ?? '',
      txRef: json['txRef']?.toString() ?? '',
      movieId: json['movieId']?.toString() ?? '',
      paid: json['paid'] == true,
      active: json['active'] == true,
      expired: json['expired'] == true,
      currentTime: _readDouble(json['currentTime']),
      startWatch: json['startWatch'] == true,
      orderDate: DateTime.tryParse(json['orderDate']?.toString() ?? ''),
      expiryDate: DateTime.tryParse(json['expiryDate']?.toString() ?? ''),
    );
  }
}

class PaymentHistoryPayment {
  final String id;
  final String txRef;
  final double? amount;
  final String currency;
  final String status;
  final String? transactionId;
  final DateTime? createdAt;

  const PaymentHistoryPayment({
    required this.id,
    required this.txRef,
    this.amount,
    required this.currency,
    required this.status,
    this.transactionId,
    this.createdAt,
  });

  factory PaymentHistoryPayment.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryPayment(
      id: json['id']?.toString() ?? '',
      txRef: json['txRef']?.toString() ?? '',
      amount: json['amount'] == null ? null : _readDouble(json['amount']),
      currency: json['currency']?.toString() ?? 'USD',
      status: json['status']?.toString() ?? '',
      transactionId: json['transactionId']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class PaymentHistorySummary {
  final int total;
  final int completed;
  final int pending;
  final int failed;
  final int active;
  final int expired;
  final int orderOnly;

  const PaymentHistorySummary({
    required this.total,
    required this.completed,
    required this.pending,
    required this.failed,
    required this.active,
    required this.expired,
    required this.orderOnly,
  });

  factory PaymentHistorySummary.fromJson(Map<String, dynamic> json) {
    return PaymentHistorySummary(
      total: _readInt(json['total']),
      completed: _readInt(json['completed']),
      pending: _readInt(json['pending']),
      failed: _readInt(json['failed']),
      active: _readInt(json['active']),
      expired: _readInt(json['expired']),
      orderOnly: _readInt(json['orderOnly']),
    );
  }
}

class PaymentHistoryPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PaymentHistoryPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaymentHistoryPagination.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryPagination(
      page: _readInt(json['page']),
      limit: _readInt(json['limit']),
      total: _readInt(json['total']),
      totalPages: _readInt(json['totalPages']),
      hasNextPage: json['hasNextPage'] == true,
      hasPreviousPage: json['hasPreviousPage'] == true,
    );
  }
}

Map<String, dynamic> _readMap(Object? value) {
  if (value is! Map) return const {};

  return Map<String, dynamic>.from(value);
}

double _readDouble(Object? value) {
  if (value is num) return value.toDouble();

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _readInt(Object? value) {
  if (value is num) return value.toInt();

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _formatDate(DateTime? date) {
  if (date == null) return 'N/A';

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
