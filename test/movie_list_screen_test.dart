import 'package:africanmovies/core/theme/app_theme.dart';
import 'package:africanmovies/features/movie_details/movie_details_screen.dart';
import 'package:africanmovies/features/movie_list/movie_list_screen.dart';
import 'package:africanmovies/features/movies/application/movie_providers.dart';
import 'package:africanmovies/features/movies/domain/home_data.dart';
import 'package:africanmovies/features/movies/domain/movie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders row title and movies', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          theme: AppTheme.darkTheme,
          home: MovieListScreen(
            title: 'New Releases',
            movies: [
              _movie(id: 'movie-1', title: 'First Movie'),
              _movie(id: 'movie-2', title: 'Second Movie'),
            ],
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('New Releases'), findsOneWidget);
    expect(find.text('2 Titles'), findsOneWidget);
    expect(find.text('First Movie'), findsOneWidget);
    expect(find.text('Second Movie'), findsOneWidget);
  });

  testWidgets('opens movie details from card context menu action', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final movies = [
      _movie(id: 'movie-1', title: 'First Movie'),
      _movie(id: 'movie-2', title: 'Second Movie'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeDataProvider.overrideWith(
            (_) async =>
                HomeData(movies: movies, genres: const [], orders: const []),
          ),
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

    await tester.pump();
    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Watch Now'));
    await tester.pumpAndSettle();

    expect(find.byType(MovieDetailsScreen), findsOneWidget);
  });
}

Movie _movie({required String id, required String title}) {
  return Movie(
    id: id,
    title: title,
    genre: 'Drama',
    rating: '16',
    isBanner: false,
    isFree: false,
    viewersLimit: 0,
    price: 0,
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
