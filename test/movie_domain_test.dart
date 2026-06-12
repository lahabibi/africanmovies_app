import 'package:africanmovies/features/movies/domain/movie.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses movie sku and store product metadata', () {
    final movie = Movie.fromJson({
      '_id': 'movie-1',
      'movieSku': 'tima_bata_2026',
      'storeProducts': {
        'ios': {
          'productId': 'com.africanmovies.movie.tima_bata_2026.rental',
          'productType': 'consumable',
          'registrationStatus': 'registered',
          'lastSyncedAt': '2026-06-12T10:00:00.000Z',
        },
        'android': {
          'productId': 'am_tima_bata_2026_rental',
          'productType': 'consumable',
          'registrationStatus': 'sync_failed',
          'errorMessage': 'Product already exists',
        },
      },
      'title': 'Tima Bata',
      'genre': 'Drama',
      'price': 0.99,
      'moviePictureURL': 'https://example.com/poster.jpg',
      'movieBannerPictureURL': 'https://example.com/banner.jpg',
      'movieTrailerURL': 'https://example.com/trailer.m3u8',
      'uploadedBy': 'admin',
    });

    expect(movie.movieSku, 'tima_bata_2026');
    expect(
      movie.storeProducts.iosProductId,
      'com.africanmovies.movie.tima_bata_2026.rental',
    );
    expect(movie.storeProducts.ios?.productType, 'consumable');
    expect(
      movie.storeProducts.ios?.registrationStatus,
      StoreProductRegistrationStatus.registered,
    );
    expect(movie.storeProducts.androidProductId, 'am_tima_bata_2026_rental');
    expect(
      movie.storeProducts.android?.registrationStatus,
      StoreProductRegistrationStatus.syncFailed,
    );
    expect(movie.storeProducts.android?.errorMessage, 'Product already exists');
    expect(movie.storeProducts.hasAnyProductId, isTrue);
  });

  test('ignores blank native product ids', () {
    final movie = Movie.fromJson({
      '_id': 'movie-1',
      'movieSku': '',
      'storeProducts': {
        'ios': {'productId': ' '},
      },
      'title': 'Tima Bata',
      'genre': 'Drama',
      'moviePictureURL': 'https://example.com/poster.jpg',
      'movieTrailerURL': 'https://example.com/trailer.m3u8',
      'uploadedBy': 'admin',
    });

    expect(movie.movieSku, isNull);
    expect(movie.storeProducts.iosProductId, isNull);
    expect(movie.storeProducts.androidProductId, isNull);
    expect(movie.storeProducts.hasAnyProductId, isFalse);
  });
}
