import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/json_cache_store.dart';
import '../domain/home_data.dart';
import '../domain/movie.dart';

enum WatchlistAction { added, removed }

class MovieRepository {
  MovieRepository({
    required ApiClient apiClient,
    required JsonCacheStore cacheStore,
  }) : _apiClient = apiClient,
       _cacheStore = cacheStore;

  static const _homeDataCacheKey = 'movies.home_data.v2';
  static const _homeDataMaxAge = Duration(minutes: 10);
  static const _searchCachePrefix = 'movies.search.v1.';
  static const _searchMaxAge = Duration(minutes: 5);

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

  Future<List<Movie>> searchMovies(
    String query, {
    bool forceRefresh = false,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return const [];

    final cacheKey = _searchCacheKey(normalizedQuery);
    final cached = await _cacheStore.read(cacheKey);
    final cachedMovies = _moviesFromCache(cached);

    if (!forceRefresh &&
        cachedMovies != null &&
        cached!.isFresh(_searchMaxAge)) {
      return cachedMovies;
    }

    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/movies/data/search',
        queryParameters: {'q': normalizedQuery},
      );

      final data = response.data;
      if (data is! List) {
        throw const ApiException('Missing search results');
      }

      final movies = _moviesFromJsonList(data);
      await _cacheStore.write(
        cacheKey,
        movies.map((movie) => movie.toJson()).toList(),
      );

      return movies;
    } on DioException catch (error) {
      if (cachedMovies != null) return cachedMovies;
      throw ApiException.fromDio(error);
    }
  }

  Future<List<Movie>> fetchWatchlistMovies() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/movies/my/watchlist',
      );

      final data = response.data;
      if (data is! List) {
        throw const ApiException('Missing watchlist movies');
      }

      return _watchlistMoviesFromJsonList(data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<WatchlistAction> toggleWatchlist(String movieId) async {
    final normalizedMovieId = movieId.trim();
    if (normalizedMovieId.isEmpty) {
      throw const ApiException('Missing movie ID');
    }

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/movies/watchlist',
        data: {'movieId': normalizedMovieId},
      );

      final action = response.data?['action']?.toString().toUpperCase();

      return switch (action) {
        'ADDED' => WatchlistAction.added,
        'REMOVED' => WatchlistAction.removed,
        _ => throw const ApiException('Invalid watchlist response'),
      };
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  HomeData? _homeDataFromCache(CachedJson? cached) {
    final data = cached?.data;
    if (data is! Map) return null;

    return HomeData.fromJson(Map<String, dynamic>.from(data));
  }

  List<Movie>? _moviesFromCache(CachedJson? cached) {
    final data = cached?.data;
    if (data is! List) return null;

    return _moviesFromJsonList(data);
  }

  List<Movie> _moviesFromJsonList(List<dynamic> data) {
    return data
        .whereType<Map>()
        .map((movie) => Movie.fromJson(Map<String, dynamic>.from(movie)))
        .toList();
  }

  List<Movie> _watchlistMoviesFromJsonList(List<dynamic> data) {
    return data
        .whereType<Map>()
        .map((item) => _movieFromWatchlistItem(Map<String, dynamic>.from(item)))
        .whereType<Movie>()
        .where((movie) => movie.id.isNotEmpty)
        .toList();
  }

  Movie? _movieFromWatchlistItem(Map<String, dynamic> item) {
    final rawMovie = item['movieId'];

    if (rawMovie is Map) {
      return Movie.fromJson(Map<String, dynamic>.from(rawMovie));
    }

    if (item.containsKey('title')) {
      return Movie.fromJson(item);
    }

    return null;
  }

  String _searchCacheKey(String query) {
    return '$_searchCachePrefix${Uri.encodeComponent(query.toLowerCase())}';
  }
}
