import 'package:africanmovies/features/movies/domain/home_data.dart';
import 'package:africanmovies/features/movies/domain/movie.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('completed playback is excluded from continue watching', () {
    final movie = _movie(duration: 75);
    final data = HomeData(
      movies: [movie],
      genres: const [],
      orders: [
        HomeOrder(
          id: 'order-1',
          movieId: movie.id,
          currentTime: 4500,
          expiryDate: DateTime.now().add(const Duration(days: 7)),
          completedAt: DateTime.now(),
          startWatch: true,
          paid: true,
          playbackCompleted: true,
          movie: movie,
        ),
      ],
    );

    expect(data.continueWatchingOrders, isEmpty);
  });

  test('restarted completed playback returns to continue watching', () {
    final movie = _movie(duration: 75);
    final data = HomeData(
      movies: [movie],
      genres: const [],
      orders: [
        HomeOrder(
          id: 'order-1',
          movieId: movie.id,
          currentTime: 32,
          expiryDate: DateTime.now().add(const Duration(days: 7)),
          startWatch: true,
          paid: true,
          movie: movie,
        ),
      ],
    );

    expect(data.continueWatchingOrders, hasLength(1));
    expect(data.continueWatchingOrders.single.movieId, movie.id);
  });

  test('parses backend playback completion fields', () {
    final movie = _movie(duration: 75);
    final order = HomeOrder.fromJson(
      {
        '_id': 'order-1',
        'movieId': movie.id,
        'currentTime': 4498,
        'expiryDate': DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String(),
        'completedAt': '2026-07-09T20:05:00.000Z',
        'startWatch': true,
        'paid': true,
        'playbackCompleted': true,
      },
      moviesById: {movie.id: movie},
    );

    expect(order.playbackCompleted, isTrue);
    expect(order.completedAt, isNotNull);
    expect(order.isInProgress, isFalse);
  });
}

Movie _movie({required double duration}) {
  return Movie(
    id: 'movie-1',
    title: 'Tima Bata',
    genre: 'Drama',
    isBanner: false,
    isFree: false,
    viewersLimit: 1,
    price: 0.99,
    description: 'Description',
    actors: const [],
    countryName: 'Ghana',
    isoCode: 'GH',
    language: 'English',
    duration: duration,
    status: 'ready',
    releaseType: 'New Release',
    posterUrl: 'https://example.com/poster.jpg',
    bannerUrl: 'https://example.com/banner.jpg',
    trailerUrl: '',
    uploadedBy: 'admin',
  );
}
