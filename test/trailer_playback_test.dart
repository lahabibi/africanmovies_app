import 'package:africanmovies/features/player/domain/trailer_playback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses an authorized playback URL returned by the backend', () {
    final playback = TrailerPlayback.fromJson({
      'title': 'Tima Bata',
      'poster': 'https://example.com/poster.jpg',
      'playbackUrl': 'https://example.com/signed-trailer.m3u8',
      'playbackToken': 'fallback-token',
    });

    expect(playback.title, 'Tima Bata');
    expect(playback.playbackUrl, 'https://example.com/signed-trailer.m3u8');
    expect(playback.canPlay, isTrue);
  });

  test('builds the signed Cloudflare URL from the playback token', () {
    final playback = TrailerPlayback.fromJson({
      'playbackToken': 'signed-playback-token',
    });

    expect(
      playback.playbackUrl,
      'https://videodelivery.net/signed-playback-token/manifest/video.m3u8',
    );
    expect(playback.canPlay, isTrue);
  });
}
