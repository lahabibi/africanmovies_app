import 'package:africanmovies/core/theme/app_theme.dart';
import 'package:africanmovies/features/auth/application/auth_controller.dart';
import 'package:africanmovies/features/auth/domain/auth_session.dart';
import 'package:africanmovies/features/favorite/application/favorite_controller.dart';
import 'package:africanmovies/features/favorite/favorite_screen.dart';
import 'package:africanmovies/features/movies/data/movie_repository.dart';
import 'package:africanmovies/features/movies/domain/movie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders favorite movies from provider', (tester) async {
    await _pumpFavorites(
      tester,
      movies: [_movie(id: 'movie-1', title: 'Favorite Movie')],
    );

    expect(find.text('Favorite Movies'), findsOneWidget);
    expect(find.text('1 Title'), findsOneWidget);
    expect(find.text('Favorite Movie'), findsOneWidget);
    expect(find.text('Drama'), findsOneWidget);
    expect(find.text('1h 15 min  •  2026'), findsOneWidget);
  });

  testWidgets('shows empty favorites state', (tester) async {
    var browseTapped = false;

    await _pumpFavorites(
      tester,
      movies: const [],
      onBrowseMovies: () => browseTapped = true,
    );

    expect(find.text('0 Titles'), findsOneWidget);
    expect(find.text('No favorite movies yet'), findsOneWidget);

    await tester.tap(find.text('Browse Movies'));
    await tester.pump();

    expect(browseTapped, isTrue);
  });
}

Future<void> _pumpFavorites(
  WidgetTester tester, {
  required List<Movie> movies,
  VoidCallback? onBrowseMovies,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _TestAuthController(
            const AuthSession(
              token: 'test-token',
              user: AuthUser(
                id: 'user-1',
                email: 'user@test.com',
                username: 'User',
              ),
            ),
          ),
        ),
        favoriteControllerProvider.overrideWith(
          () => _TestFavoriteController(movies),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          theme: AppTheme.darkTheme,
          home: FavoriteScreen(onBrowseMovies: onBrowseMovies),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
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
    price: 0.99,
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

class _TestAuthController extends AuthController {
  final AuthSession? session;

  _TestAuthController(this.session);

  @override
  Future<AuthSession?> build() async => session;
}

class _TestFavoriteController extends FavoriteController {
  final List<Movie> movies;

  _TestFavoriteController(this.movies);

  @override
  Future<List<Movie>> build() async => movies;

  @override
  Future<FavoriteAction> toggle(Movie movie) async {
    final currentMovies = state.asData?.value ?? movies;
    final isSaved = currentMovies.any((item) => item.id == movie.id);

    if (isSaved) {
      state = AsyncData(
        currentMovies.where((item) => item.id != movie.id).toList(),
      );
      return FavoriteAction.removed;
    }

    state = AsyncData([movie, ...currentMovies]);
    return FavoriteAction.added;
  }
}
