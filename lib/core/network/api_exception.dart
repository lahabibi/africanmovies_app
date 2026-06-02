import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final data = response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return ApiException(message, statusCode: response?.statusCode);
      }
    }

    if (data is String && data.isNotEmpty) {
      return ApiException(data, statusCode: response?.statusCode);
    }

    return ApiException(
      error.message ?? 'Something went wrong. Please try again.',
      statusCode: response?.statusCode,
    );
  }

  @override
  String toString() => message;
}
