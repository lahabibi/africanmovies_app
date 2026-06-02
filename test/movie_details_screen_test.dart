import 'package:africanmovies/core/theme/app_theme.dart';
import 'package:africanmovies/features/movie_details/movie_details_screen.dart';
import 'package:africanmovies/features/movies/application/movie_providers.dart';
import 'package:africanmovies/features/movies/domain/home_data.dart';
import 'package:africanmovies/features/movies/domain/movie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders movie details from selected movie', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final movie = _movie(
      id: 'movie-1',
      title: 'Test Movie',
      genre: 'Drama',
      description:
          'A young filmmaker returns home and uncovers the courage to tell a story the whole village has been avoiding.',
    );
    final relatedMovie = _movie(
      id: 'movie-2',
      title: 'Related Movie',
      genre: 'Drama',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeDataProvider.overrideWith(
            (_) async => HomeData(
              movies: [movie, relatedMovie],
              genres: const [],
              orders: const [],
            ),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            theme: AppTheme.darkTheme,
            home: MovieDetailsScreen(movie: movie),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Watch for \$0'), findsOneWidget);
    expect(find.text('More Like This'), findsOneWidget);
  });
}

Movie _movie({
  required String id,
  required String title,
  required String genre,
  String description = 'A test movie description.',
}) {
  return Movie(
    id: id,
    title: title,
    genre: genre,
    rating: '16',
    isBanner: false,
    isFree: false,
    viewersLimit: 0,
    price: 0,
    description: description,
    actors: const ['Actor One', 'Actor Two'],
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
