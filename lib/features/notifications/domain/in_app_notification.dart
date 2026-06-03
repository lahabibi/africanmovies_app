import '../../movies/domain/movie.dart';

enum InAppNotificationType {
  newRelease,
  purchaseSuccess,
  rentalExpiry;

  String get value {
    return switch (this) {
      InAppNotificationType.newRelease => 'newRelease',
      InAppNotificationType.purchaseSuccess => 'purchaseSuccess',
      InAppNotificationType.rentalExpiry => 'rentalExpiry',
    };
  }

  static InAppNotificationType fromValue(String? value) {
    return switch (value) {
      'purchaseSuccess' => InAppNotificationType.purchaseSuccess,
      'rentalExpiry' => InAppNotificationType.rentalExpiry,
      _ => InAppNotificationType.newRelease,
    };
  }
}

class InAppNotification {
  final String id;
  final InAppNotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? movieId;
  final String? movieTitle;
  final String? posterUrl;

  const InAppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.readAt,
    this.movieId,
    this.movieTitle,
    this.posterUrl,
  });

  factory InAppNotification.newRelease(Movie movie) {
    return InAppNotification(
      id: 'new-release-${movie.id}',
      type: InAppNotificationType.newRelease,
      title: 'New release: ${movie.title}',
      message: 'Now available to watch on AfricanMovies.',
      createdAt: DateTime.now(),
      movieId: movie.id,
      movieTitle: movie.title,
      posterUrl: movie.displayPosterUrl,
    );
  }

  factory InAppNotification.purchaseSuccess(Movie movie) {
    return InAppNotification(
      id: 'purchase-${movie.id}-${DateTime.now().millisecondsSinceEpoch}',
      type: InAppNotificationType.purchaseSuccess,
      title: 'Purchase successful',
      message: '${movie.title} is ready in your library.',
      createdAt: DateTime.now(),
      movieId: movie.id,
      movieTitle: movie.title,
      posterUrl: movie.displayPosterUrl,
    );
  }

  factory InAppNotification.rentalExpiry({
    required Movie movie,
    required DateTime expiresAt,
  }) {
    return InAppNotification(
      id: 'rental-expiry-${movie.id}-${expiresAt.millisecondsSinceEpoch}',
      type: InAppNotificationType.rentalExpiry,
      title: 'Rental ending soon',
      message: '${movie.title} expires ${_dateLabel(expiresAt)}.',
      createdAt: DateTime.now(),
      movieId: movie.id,
      movieTitle: movie.title,
      posterUrl: movie.displayPosterUrl,
    );
  }

  factory InAppNotification.fromJson(Map<String, dynamic> json) {
    return InAppNotification(
      id: json['id']?.toString() ?? '',
      type: InAppNotificationType.fromValue(json['type']?.toString()),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      readAt: DateTime.tryParse(json['readAt']?.toString() ?? ''),
      movieId: json['movieId']?.toString(),
      movieTitle: json['movieTitle']?.toString(),
      posterUrl: json['posterUrl']?.toString(),
    );
  }

  bool get isRead => readAt != null;

  bool get isUnread => !isRead;

  InAppNotification markRead(DateTime readAt) {
    if (isRead) return this;

    return copyWith(readAt: readAt);
  }

  InAppNotification copyWith({
    String? id,
    InAppNotificationType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    DateTime? readAt,
    String? movieId,
    String? movieTitle,
    String? posterUrl,
  }) {
    return InAppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      movieId: movieId ?? this.movieId,
      movieTitle: movieTitle ?? this.movieTitle,
      posterUrl: posterUrl ?? this.posterUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'movieId': movieId,
      'movieTitle': movieTitle,
      'posterUrl': posterUrl,
    };
  }

  static String _dateLabel(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '${date.day}/${date.month}/${date.year} at $hour:$minute';
  }
}
