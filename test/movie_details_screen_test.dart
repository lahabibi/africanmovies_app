import 'package:africanmovies/core/theme/app_theme.dart';
import 'package:africanmovies/features/auth/application/auth_controller.dart';
import 'package:africanmovies/features/auth/domain/auth_session.dart';
import 'package:africanmovies/features/movie_details/movie_details_screen.dart';
import 'package:africanmovies/features/movie_details/widgets/movie_purchase_button.dart';
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

    await _pumpMovieDetails(
      tester,
      movie: movie,
      movies: [movie, relatedMovie],
    );

    await tester.pump();

    expect(find.text('Watch for \$0'), findsOneWidget);
    expect(find.text('More Like This'), findsOneWidget);
  });

  testWidgets('shows Watch Free for an unclaimed free movie', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final movie = _movie(
      id: 'free-movie',
      title: 'Free Movie',
      genre: 'Drama',
      isFree: true,
      price: 0.99,
    );

    await _pumpMovieDetails(tester, movie: movie, movies: [movie]);
    await tester.pump();

    expect(find.text('Watch Free'), findsOneWidget);
    expect(find.text('Claim free access'), findsOneWidget);
  });

  testWidgets('confirms before claiming a free movie', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final movie = _movie(
      id: 'free-movie',
      title: 'Free Movie',
      genre: 'Drama',
      isFree: true,
      price: 0.99,
    );

    await _pumpMovieDetails(
      tester,
      movie: movie,
      movies: [movie],
      session: _authSession,
    );
    await tester.pump();

    await tester.tap(find.text('Watch Free'));
    await tester.pumpAndSettle();

    expect(find.text('Claim free movie?'), findsOneWidget);
    expect(find.text('Claim & Watch'), findsOneWidget);
    expect(
      find.textContaining('Free access can only be claimed once'),
      findsOneWidget,
    );
  });

  testWidgets('shows paid access after free movie claim expires', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final movie = _movie(
      id: 'free-movie',
      title: 'Free Movie',
      genre: 'Drama',
      isFree: true,
      price: 0.99,
    );

    await _pumpMovieDetails(
      tester,
      movie: movie,
      movies: [movie],
      orders: [
        HomeOrder(
          id: 'expired-order',
          movieId: movie.id,
          currentTime: 0,
          expiryDate: DateTime(2026, 1, 1),
          startWatch: true,
          paid: true,
          movie: movie,
        ),
      ],
    );
    await tester.pump();

    expect(find.text('Watch for \$0.99'), findsOneWidget);
    expect(find.text('Free access used'), findsOneWidget);
  });

  testWidgets('shows disabled Coming Soon for an unapproved paid movie', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final movie = _movie(
      id: 'paid-movie',
      title: 'Paid Movie',
      genre: 'Drama',
      price: 0.99,
    );
    final detailsMovie = _movie(
      id: movie.id,
      title: movie.title,
      genre: movie.genre,
      price: movie.price,
      purchaseAvailability: const MoviePurchaseAvailability(
        platform: 'ios',
        status: MoviePurchaseAvailabilityStatus.comingSoon,
        canPurchase: false,
        reason: 'apple_approval_pending',
      ),
    );

    await _pumpMovieDetails(
      tester,
      movie: movie,
      detailedMovie: detailsMovie,
      movies: [movie],
    );
    await tester.pump();

    expect(find.text('Coming Soon'), findsOneWidget);
    expect(find.text('Not yet available for purchase'), findsOneWidget);
    expect(
      tester
          .widget<MoviePurchaseButton>(find.byType(MoviePurchaseButton))
          .onTap,
      isNull,
    );
  });

  testWidgets('keeps active library access when the IAP is coming soon', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final movie = _movie(
      id: 'library-movie',
      title: 'Library Movie',
      genre: 'Drama',
      price: 0.99,
    );
    final detailsMovie = _movie(
      id: movie.id,
      title: movie.title,
      genre: movie.genre,
      price: movie.price,
      purchaseAvailability: const MoviePurchaseAvailability(
        platform: 'ios',
        status: MoviePurchaseAvailabilityStatus.comingSoon,
        canPurchase: false,
      ),
    );

    await _pumpMovieDetails(
      tester,
      movie: movie,
      detailedMovie: detailsMovie,
      movies: [movie],
      orders: [
        HomeOrder(
          id: 'active-order',
          movieId: movie.id,
          currentTime: 0,
          expiryDate: DateTime(2030, 1, 1),
          startWatch: true,
          paid: true,
          movie: movie,
        ),
      ],
    );
    await tester.pump();

    expect(find.text('Watch Now'), findsOneWidget);
    expect(find.text('In your library'), findsOneWidget);
  });

  testWidgets('keeps unclaimed free access when its IAP is unavailable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final movie = _movie(
      id: 'free-movie',
      title: 'Free Movie',
      genre: 'Drama',
      isFree: true,
      price: 0.99,
      purchaseAvailability: const MoviePurchaseAvailability(
        platform: 'ios',
        status: MoviePurchaseAvailabilityStatus.unavailable,
        canPurchase: false,
      ),
    );

    await _pumpMovieDetails(tester, movie: movie, movies: [movie]);
    await tester.pump();

    expect(find.text('Watch Free'), findsOneWidget);
    expect(find.text('Claim free access'), findsOneWidget);
  });
}

Future<void> _pumpMovieDetails(
  WidgetTester tester, {
  required Movie movie,
  Movie? detailedMovie,
  required List<Movie> movies,
  List<HomeOrder> orders = const [],
  AuthSession? session,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (session != null)
          authControllerProvider.overrideWith(
            () => _TestAuthController(session),
          ),
        homeDataProvider.overrideWith(
          (_) async =>
              HomeData(movies: movies, genres: const [], orders: orders),
        ),
        movieDetailsProvider.overrideWith(
          (_, _) async => detailedMovie ?? movie,
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
}

const _authSession = AuthSession(
  token: 'token',
  user: AuthUser(id: 'user-1', email: 'user@test.com', username: 'User'),
);

class _TestAuthController extends AuthController {
  final AuthSession? session;

  _TestAuthController(this.session);

  @override
  Future<AuthSession?> build() async => session;
}

Movie _movie({
  required String id,
  required String title,
  required String genre,
  String description = 'A test movie description.',
  bool isFree = false,
  double price = 0,
  MoviePurchaseAvailability purchaseAvailability =
      const MoviePurchaseAvailability(
        platform: 'ios',
        status: MoviePurchaseAvailabilityStatus.available,
        canPurchase: true,
      ),
}) {
  return Movie(
    id: id,
    purchaseAvailability: purchaseAvailability,
    title: title,
    genre: genre,
    rating: '16',
    isBanner: false,
    isFree: isFree,
    viewersLimit: 0,
    price: price,
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
