import 'package:africanmovies/features/movies/domain/home_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves continue watching orders from string movie ids', () {
    final data = HomeData.fromJson({
      'movies': [
        {
          '_id': 'movie-1',
          'title': 'Resume Me',
          'genre': 'Drama',
          'duration': 75,
          'moviePictureURL': 'https://example.com/poster.jpg',
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
      ],
    });

    expect(data.orders, hasLength(2));
    expect(data.orders.first.movie?.title, 'Resume Me');
    expect(data.continueWatchingOrders, hasLength(1));
    expect(data.continueWatchingMovies.single.id, 'movie-1');
    expect(data.continueWatchingOrders.single.progress, greaterThan(0));
    expect(data.purchasedMovieCount, 1);
  });
}
