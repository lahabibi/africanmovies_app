import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/movie_playback.dart';

class PlayerRepository {
  PlayerRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<MoviePlayback> requestMoviePlayback(String movieId) async {
    final normalizedMovieId = movieId.trim();
    if (normalizedMovieId.isEmpty) {
      throw const ApiException('Missing movie ID');
    }

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/orders/mobile/watch/access/$normalizedMovieId',
      );

      final data = response.data;
      if (data == null) {
        throw const ApiException('Missing playback data');
      }

      final playback = MoviePlayback.fromJson(data);
      if (!playback.canPlay) {
        throw ApiException(
          playback.message.isNotEmpty
              ? playback.message
              : 'Playback unavailable',
        );
      }

      return playback;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> savePlaybackProgress({
    required String orderId,
    required Duration position,
  }) async {
    final normalizedOrderId = orderId.trim();
    if (normalizedOrderId.isEmpty) return;

    try {
      await _apiClient.post<Map<String, dynamic>>(
        '/orders/currentTime',
        data: {'_id': normalizedOrderId, 'currentTime': position.inSeconds},
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
