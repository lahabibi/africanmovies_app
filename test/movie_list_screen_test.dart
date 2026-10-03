import 'package:africanmovies/core/network/api_exception.dart';
import 'package:africanmovies/core/theme/app_theme.dart';
import 'package:africanmovies/features/movie_details/movie_details_screen.dart';
import 'package:africanmovies/features/movie_list/movie_list_screen.dart';
import 'package:africanmovies/features/movies/application/movie_providers.dart';
import 'package:africanmovies/features/movies/domain/home_data.dart';
import 'package:africanmovies/features/movies/domain/movie.dart';
import 'package:africanmovies/features/player/application/player_providers.dart';
import 'package:africanmovies/features/player/data/player_repository.dart';
import 'package:africanmovies/features/player/domain/movie_playback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders row title and movies', (tester) async {
    final movies = [
      _movie(id: 'movie-1', title: 'First Movie'),
      _movie(id: 'movie-2', title: 'Second Movie'),
    ];

    await _pumpMovieList(tester, movies: movies);

    expect(find.text('New Releases'), findsOneWidget);
    expect(find.text('2 Titles'), findsOneWidget);
    expect(find.text('First Movie'), findsOneWidget);
    expect(find.text('Second Movie'), findsOneWidget);
  });

  testWidgets('shows play icon only for movies with active library access', (
    tester,
  ) async {
    final ownedMovie = _movie(id: 'owned-movie', title: 'Owned Movie');
    final unownedMovie = _movie(id: 'unowned-movie', title: 'Unowned Movie');

    await _pumpMovieList(
      tester,
      movies: [ownedMovie, unownedMovie],
      orders: [_activeOrder(ownedMovie)],
    );

    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });

  testWidgets('opens details for an unowned movie and shows its price', (
    tester,
  ) async {
    final movie = _movie(
      id: 'unowned-movie',
      title: 'Unowned Movie',
      price: 2.99,
    );

    await _pumpMovieList(tester, movies: [movie]);

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Watch Now'), findsOneWidget);
    expect(find.text('\$2.99'), findsOneWidget);

    await tester.tap(find.text('Watch Now'));
    await tester.pumpAndSettle();

    expect(find.byType(MovieDetailsScreen), findsOneWidget);
  });

  testWidgets('tapping an owned movie requests playback instead of details', (
    tester,
  ) async {
    final movie = _movie(id: 'owned-movie', title: 'Owned Movie');
    final playerRepository = _TestPlayerRepository();

    await _pumpMovieList(
      tester,
      movies: [movie],
      orders: [_activeOrder(movie)],
      playerRepository: playerRepository,
    );

    await tester.tap(find.text('Owned Movie'));
    await tester.pumpAndSettle();

    expect(playerRepository.requestedMovieIds, ['owned-movie']);
    expect(find.byType(MovieDetailsScreen), findsNothing);
  });

  testWidgets('owned movie menu hides price and requests playback', (
    tester,
  ) async {
    final movie = _movie(id: 'owned-movie', title: 'Owned Movie', price: 2.99);
    final playerRepository = _TestPlayerRepository();

    await _pumpMovieList(
      tester,
      movies: [movie],
      orders: [_activeOrder(movie)],
      playerRepository: playerRepository,
    );

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Watch Now'), findsOneWidget);
    expect(find.text('\$2.99'), findsNothing);

    await tester.tap(find.text('Watch Now'));
    await tester.pumpAndSettle();

    expect(playerRepository.requestedMovieIds, ['owned-movie']);
    expect(find.byType(MovieDetailsScreen), findsNothing);
  });
}

Future<void> _pumpMovieList(
  WidgetTester tester, {
  required List<Movie> movies,
  List<HomeOrder> orders = const [],
  PlayerRepository? playerRepository,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        homeDataProvider.overrideWith(
          (_) async =>
              HomeData(movies: movies, genres: const [], orders: orders),
        ),
        movieDetailsProvider.overrideWith((_, movieId) async {
          return movies.firstWhere((movie) => movie.id == movieId);
        }),
        if (playerRepository != null)
          playerRepositoryProvider.overrideWith((_) => playerRepository),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          theme: AppTheme.darkTheme,
          home: MovieListScreen(title: 'New Releases', movies: movies),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

HomeOrder _activeOrder(Movie movie) {
  return HomeOrder(
    id: 'order-${movie.id}',
    movieId: movie.id,
    currentTime: 0,
    expiryDate: DateTime(2030, 1, 1),
    startWatch: true,
    paid: true,
    movie: movie,
  );
}

class _TestPlayerRepository implements PlayerRepository {
  final List<String> requestedMovieIds = [];

  @override
  Future<MoviePlayback> requestMoviePlayback(String movieId) {
    requestedMovieIds.add(movieId);

    return Future<MoviePlayback>.error(
      const ApiException('Test playback unavailable.'),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Movie _movie({required String id, required String title, double price = 0.99}) {
  return Movie(
    id: id,
    title: title,
    genre: 'Drama',
    rating: '16',
    isBanner: false,
    isFree: false,
    viewersLimit: 0,
    price: price,
    description: 'A test movie description.',
    actors: const ['Actor One'],
    countryName: 'Senegal',
    isoCode: 'SN',
    language: 'Wolof',
    duration: 75,
    status: 'Published',
    releaseYear: '2026',
    releaseType: 'New Release',
    posterUrl: '',
    bannerUrl: '',
    trailerUrl: '',
    uploadedBy: 'tester',
    uploadDate: DateTime(2026, 6, 1),
  );
}
