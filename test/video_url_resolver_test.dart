import 'package:africanmovies/features/player/video_url_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const videoUid = '896461fec96fd41ac99a843e25b21ff5';

  test('converts Cloudflare iframe URLs to HLS manifest URLs', () {
    expect(
      resolvePlayableVideoUrl('https://iframe.videodelivery.net/$videoUid'),
      'https://videodelivery.net/$videoUid/manifest/video.m3u8',
    );
  });

  test('preserves Cloudflare signed query parameters', () {
    expect(
      resolvePlayableVideoUrl(
        'https://iframe.videodelivery.net/$videoUid?token=test-token',
      ),
      'https://videodelivery.net/$videoUid/manifest/video.m3u8?token=test-token',
    );
  });

  test('converts bare Cloudflare video ids to HLS manifest URLs', () {
    expect(
      resolvePlayableVideoUrl(videoUid),
      'https://videodelivery.net/$videoUid/manifest/video.m3u8',
    );
  });

  test('keeps direct media URLs unchanged', () {
    const manifestUrl =
        'https://videodelivery.net/$videoUid/manifest/video.m3u8';

    expect(resolvePlayableVideoUrl(manifestUrl), manifestUrl);
  });
}
