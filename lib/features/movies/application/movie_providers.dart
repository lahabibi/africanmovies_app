import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_session.dart';
import '../../notifications/application/notification_providers.dart';
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
  final session = await ref.watch(authControllerProvider.future);
  final cacheOwnerKey = _homeDataCacheOwnerKey(session);

  final homeData = await ref
      .watch(movieRepositoryProvider)
      .fetchHomeData(
        cacheOwnerKey: cacheOwnerKey,
        forceRefresh: session != null,
      );
  await ref
      .read(notificationsControllerProvider.notifier)
      .syncNewReleases(homeData.latestUploadedMovies);

  return homeData;
});

Future<HomeData> forceRefreshHomeData(WidgetRef ref) async {
  final session = await ref.read(authControllerProvider.future);
  final cacheOwnerKey = _homeDataCacheOwnerKey(session);

  await ref
      .read(movieRepositoryProvider)
      .fetchHomeData(forceRefresh: true, cacheOwnerKey: cacheOwnerKey);
  ref.invalidate(homeDataProvider);

  return ref.read(homeDataProvider.future);
}

String _homeDataCacheOwnerKey(AuthSession? session) {
  if (session == null) return 'guest';

  final userId = session.user.id.trim();
  if (userId.isNotEmpty) return 'user.${Uri.encodeComponent(userId)}';

  final email = session.user.email.trim().toLowerCase();
  if (email.isNotEmpty) return 'user.${Uri.encodeComponent(email)}';

  return 'user.unknown';
}

final movieSearchProvider = FutureProvider.autoDispose
    .family<List<Movie>, String>((ref, query) async {
      final normalizedQuery = query.trim();
      if (normalizedQuery.isEmpty) return const [];

      return ref.watch(movieRepositoryProvider).searchMovies(normalizedQuery);
    });
