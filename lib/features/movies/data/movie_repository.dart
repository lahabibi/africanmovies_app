import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/json_cache_store.dart';
import '../domain/home_data.dart';

class MovieRepository {
  MovieRepository({
    required ApiClient apiClient,
    required JsonCacheStore cacheStore,
  }) : _apiClient = apiClient,
       _cacheStore = cacheStore;

  static const _homeDataCacheKey = 'movies.home_data';
  static const _homeDataMaxAge = Duration(minutes: 10);

  final ApiClient _apiClient;
  final JsonCacheStore _cacheStore;

  Future<HomeData> fetchHomeData({bool forceRefresh = false}) async {
    final cached = await _cacheStore.read(_homeDataCacheKey);
    final cachedData = _homeDataFromCache(cached);

    if (!forceRefresh &&
        cachedData != null &&
        cached!.isFresh(_homeDataMaxAge)) {
      return cachedData;
    }

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/movies/home/data',
      );

      final data = response.data;
      if (data == null) {
        throw const ApiException('Missing movie home data');
      }

      final homeData = HomeData.fromJson(data);
      await _cacheStore.write(_homeDataCacheKey, homeData.toJson());

      return homeData;
    } on DioException catch (error) {
      if (cachedData != null) return cachedData;
      throw ApiException.fromDio(error);
    }
  }

  HomeData? _homeDataFromCache(CachedJson? cached) {
    final data = cached?.data;
    if (data is! Map) return null;

    return HomeData.fromJson(Map<String, dynamic>.from(data));
  }
}
