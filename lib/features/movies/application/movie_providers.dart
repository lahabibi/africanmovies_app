import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/movie_repository.dart';
import '../domain/home_data.dart';

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
