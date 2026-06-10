import 'package:africanmovies/features/player/domain/movie_playback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses movie playback resume position and duration', () {
    final playback = MoviePlayback.fromJson({
      'allowed': true,
      'requiresPayment': false,
      'movieId': 'movie-1',
      'orderId': 'order-1',
      'title': 'Tima Bata',
      'poster': 'https://example.com/poster.jpg',
      'startTime': 62,
      'duration': 75,
      'playbackUrl': 'https://example.com/video.mpd',
      'expiresIn': 3600,
      'message': '',
    });

    expect(playback.canPlay, isTrue);
    expect(playback.startPosition, const Duration(seconds: 62));
    expect(playback.expectedDuration, const Duration(minutes: 75));
  });

  test('handles missing resume and duration values safely', () {
    final playback = MoviePlayback.fromJson({
      'allowed': true,
      'playbackUrl': 'https://example.com/video.mpd',
      'startTime': 0,
      'duration': 0,
    });

    expect(playback.startPosition, Duration.zero);
    expect(playback.expectedDuration, isNull);
  });
}
