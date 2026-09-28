import 'package:africanmovies/core/network/api_client.dart';
import 'package:africanmovies/core/storage/device_identity_store.dart';
import 'package:africanmovies/core/storage/json_cache_store.dart';
import 'package:africanmovies/core/storage/secure_token_store.dart';
import 'package:africanmovies/features/movies/data/movie_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final testCase in const [
    (target: TargetPlatform.iOS, queryValue: 'ios'),
    (target: TargetPlatform.android, queryValue: 'android'),
  ]) {
    test(
      'fetchMovieDetails sends the ${testCase.queryValue} platform',
      () async {
        debugDefaultTargetPlatformOverride = testCase.target;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
        final apiClient = ApiClient(
          tokenStore: _FakeSecureTokenStore(),
          deviceIdentityStore: DeviceIdentityStore(),
          dio: dio,
        );
        late RequestOptions capturedRequest;

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              capturedRequest = options;
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'movie': {
                      '_id': 'movie-1',
                      'title': 'Test Movie',
                      'purchaseAvailability': {
                        'platform': testCase.queryValue,
                        'status': 'available',
                        'canPurchase': true,
                        'reason': null,
                      },
                    },
                  },
                ),
              );
            },
          ),
        );

        final repository = MovieRepository(
          apiClient: apiClient,
          cacheStore: JsonCacheStore(),
        );
        final movie = await repository.fetchMovieDetails(' movie-1 ');

        expect(capturedRequest.path, '/movies/movie-details/movie-1');
        expect(
          capturedRequest.queryParameters['platform'],
          testCase.queryValue,
        );
        expect(movie.id, 'movie-1');
        expect(movie.purchaseAvailability?.isPurchasable, isTrue);
      },
    );
  }
}

class _FakeSecureTokenStore extends SecureTokenStore {
  @override
  Future<String?> readAccessToken() async => null;
}
