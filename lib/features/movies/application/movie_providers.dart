import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/movie_repository.dart';
import '../domain/home_data.dart';
import '../domain/movie.dart';

final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  return MovieRepository(
    apiClient: ref.watch(apiClientProvider),
    cacheStore: ref.watch(jsonCacheStoreProvider),
  );
});

final homeDataProvider = FutureProvider<HomeData>((ref) async {
  ref.watch(authControllerProvider);

  return ref.watch(movieRepositoryProvider).fetchHomeData();
});

final movieSearchProvider = FutureProvider.autoDispose
    .family<List<Movie>, String>((ref, query) async {
      final normalizedQuery = query.trim();
      if (normalizedQuery.isEmpty) return const [];

      return ref.watch(movieRepositoryProvider).searchMovies(normalizedQuery);
    });
