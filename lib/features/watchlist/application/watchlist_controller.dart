import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/application/auth_controller.dart';
import '../../movies/application/movie_providers.dart';
import '../../movies/data/movie_repository.dart';
import '../../movies/domain/movie.dart';

final watchlistControllerProvider =
    AsyncNotifierProvider<WatchlistController, List<Movie>>(
      WatchlistController.new,
    );

class WatchlistController extends AsyncNotifier<List<Movie>> {
  @override
  Future<List<Movie>> build() async {
    final session = await ref.watch(authControllerProvider.future);
    if (session == null) return const [];

    return ref.watch(movieRepositoryProvider).fetchWatchlistMovies();
  }

  Future<WatchlistAction> toggle(Movie movie) async {
    final session = ref.read(authControllerProvider).asData?.value;
    if (session == null) {
      throw const ApiException('Sign in to use your watchlist.');
    }

    final previousMovies = state.asData?.value ?? const <Movie>[];
    final wasSaved = _containsMovie(previousMovies, movie.id);

    state = AsyncData(
      _setMovieSaved(previousMovies, movie: movie, isSaved: !wasSaved),
    );

    try {
      final action = await ref
          .read(movieRepositoryProvider)
          .toggleWatchlist(movie.id);
      final currentMovies = state.asData?.value ?? previousMovies;

      state = AsyncData(
        _setMovieSaved(
          currentMovies,
          movie: movie,
          isSaved: action == WatchlistAction.added,
        ),
      );

      return action;
    } catch (error, stackTrace) {
      state = AsyncData(previousMovies);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  bool contains(String movieId) {
    return _containsMovie(state.asData?.value ?? const <Movie>[], movieId);
  }

  bool _containsMovie(List<Movie> movies, String movieId) {
    return movies.any((movie) => movie.id == movieId);
  }

  List<Movie> _setMovieSaved(
    List<Movie> movies, {
    required Movie movie,
    required bool isSaved,
  }) {
    if (!isSaved) {
      return movies.where((item) => item.id != movie.id).toList();
    }

    if (_containsMovie(movies, movie.id)) return movies;

    return [movie, ...movies];
  }
}
