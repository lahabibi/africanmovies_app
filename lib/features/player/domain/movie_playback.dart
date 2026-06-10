class MoviePlayback {
  final bool allowed;
  final bool requiresPayment;
  final String movieId;
  final String orderId;
  final String title;
  final String posterUrl;
  final double startTime;
  final double duration;
  final String playbackUrl;
  final int expiresIn;
  final String message;

  const MoviePlayback({
    required this.allowed,
    required this.requiresPayment,
    required this.movieId,
    required this.orderId,
    required this.title,
    required this.posterUrl,
    required this.startTime,
    required this.duration,
    required this.playbackUrl,
    required this.expiresIn,
    required this.message,
  });

  Duration get startPosition {
    if (startTime <= 0) return Duration.zero;

    return Duration(seconds: startTime.round());
  }

  Duration? get expectedDuration {
    if (duration <= 0) return null;

    return Duration(seconds: (duration * 60).round());
  }

  bool get canPlay => allowed && playbackUrl.trim().isNotEmpty;

  factory MoviePlayback.fromJson(Map<String, dynamic> json) {
    return MoviePlayback(
      allowed: json['allowed'] == true,
      requiresPayment: json['requiresPayment'] == true,
      movieId: json['movieId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Movie',
      posterUrl: json['poster']?.toString() ?? '',
      startTime: double.tryParse(json['startTime']?.toString() ?? '') ?? 0,
      duration: double.tryParse(json['duration']?.toString() ?? '') ?? 0,
      playbackUrl: json['playbackUrl']?.toString() ?? '',
      expiresIn: int.tryParse(json['expiresIn']?.toString() ?? '') ?? 0,
      message: json['message']?.toString() ?? '',
    );
  }
}
