import 'package:africanmovies/features/movies/domain/home_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves continue watching orders from string movie ids', () {
    final expiringSoonDate = DateTime.now()
        .add(const Duration(days: 2))
        .toIso8601String();

    final data = HomeData.fromJson({
      'movies': [
        {
          '_id': 'movie-1',
          'title': 'Resume Me',
          'genre': 'Drama',
          'duration': 75,
          'moviePictureURL': 'https://example.com/poster.jpg',
        },
        {
          '_id': 'movie-2',
          'title': 'Expired Movie',
          'genre': 'Drama',
          'duration': 90,
          'moviePictureURL': 'https://example.com/expired.jpg',
        },
        {
          '_id': 'movie-3',
          'title': 'Almost Expired Movie',
          'genre': 'Comedy',
          'duration': 60,
          'moviePictureURL': 'https://example.com/soon.jpg',
        },
      ],
      'genres': [],
      'orders': [
        {
          '_id': 'order-1',
          'movieId': 'movie-1',
          'currentTime': 120,
          'expiryDate': '2099-01-01T00:00:00.000Z',
          'startWatch': true,
          'paid': true,
        },
        {
          '_id': 'order-2',
          'movieId': 'movie-1',
          'currentTime': 0,
          'expiryDate': '2099-01-01T00:00:00.000Z',
          'startWatch': false,
          'paid': true,
        },
        {
          '_id': 'order-3',
          'movieId': 'movie-2',
          'currentTime': 300,
          'expiryDate': '2000-01-01T00:00:00.000Z',
          'startWatch': true,
          'paid': true,
        },
        {
          '_id': 'order-4',
          'movieId': 'movie-3',
          'currentTime': 0,
          'expiryDate': expiringSoonDate,
          'startWatch': true,
          'paid': true,
        },
      ],
    });

    expect(data.orders, hasLength(4));
    expect(data.orders.first.movie?.title, 'Resume Me');
    expect(data.continueWatchingOrders, hasLength(1));
    expect(data.continueWatchingMovies.single.id, 'movie-1');
    expect(data.continueWatchingOrders.single.progress, greaterThan(0));
    expect(data.activeLibraryOrders, hasLength(2));
    expect(data.expiringSoonOrders, hasLength(1));
    expect(data.expiringSoonOrders.single.movie?.title, 'Almost Expired Movie');
    expect(data.expiredLibraryOrders, hasLength(1));
    expect(data.expiredLibraryOrders.single.movie?.title, 'Expired Movie');
    expect(data.purchasedMovieCount, 3);
  });
}
