import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const ApiException(this.message, {this.statusCode, this.code});

  factory ApiException.fromDio(DioException error) {
    if (_isNetworkFailure(error)) {
      return const ApiException(
        'No internet connection. Please check your network and try again.',
      );
    }

    final response = error.response;
    final data = response?.data;

    if (data is Map<String, dynamic>) {
      final code = data['code']?.toString();
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return ApiException(
          message,
          statusCode: response?.statusCode,
          code: code,
        );
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

  bool get isAuthSessionExpired {
    return code == 'INVALID_DEVICE' ||
        code == 'TOKEN_EXPIRED' ||
        code == 'INVALID_TOKEN';
  }

  @override
  String toString() => message;
}

bool _isNetworkFailure(DioException error) {
  return switch (error.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout => true,
    _ => false,
  };
}
