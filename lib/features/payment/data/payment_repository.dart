import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/payment_confirmation.dart';
import '../domain/payment_history.dart';
import '../domain/payment_intent.dart';
import '../domain/saved_card_charge_result.dart';
import '../domain/saved_payment_method.dart';

class PaymentRepository {
  PaymentRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<PaymentIntent> initializeMoviePurchase(String movieId) async {
    final normalizedMovieId = movieId.trim();
    if (normalizedMovieId.isEmpty) {
      throw const ApiException('Missing movie ID');
    }

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/payment/mobile/initialize',
        data: {'movieId': normalizedMovieId},
      );

      final data = response.data;
      if (data == null) {
        throw const ApiException('Missing payment initialization data');
      }

      return PaymentIntent.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<PaymentConfirmation> confirmFlutterwavePayment({
    required String txRef,
    required String transactionId,
  }) async {
    final normalizedTxRef = txRef.trim();
    final normalizedTransactionId = transactionId.trim();

    if (normalizedTxRef.isEmpty || normalizedTransactionId.isEmpty) {
      throw const ApiException('Missing payment verification details');
    }

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/payment/confirm',
        data: {
          'txRef': normalizedTxRef,
          'transactionId': normalizedTransactionId,
        },
      );

      final data = response.data;
      if (data == null) {
        throw const ApiException('Missing payment verification data');
      }

      return PaymentConfirmation.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<SavedPaymentMethod?> fetchSavedPaymentMethod() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/payment/token',
      );

      final tokenPayload = response.data?['tokenPayload'];
      if (tokenPayload == null) return null;
      if (tokenPayload is! Map) {
        throw const ApiException('Invalid saved payment method response');
      }

      return SavedPaymentMethod.fromJson(
        Map<String, dynamic>.from(tokenPayload),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<SavedPaymentMethod> savePaymentMethod({
    required String transactionId,
    bool isNewCard = true,
  }) async {
    final normalizedTransactionId = transactionId.trim();
    if (normalizedTransactionId.isEmpty) {
      throw const ApiException('Missing transaction ID');
    }

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/payment/token',
        data: {
          'transactionID': normalizedTransactionId,
          'isNewCard': isNewCard,
        },
      );

      final data = response.data;
      if (data == null) {
        throw const ApiException('Missing saved payment method data');
      }

      return SavedPaymentMethod.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> removeSavedPaymentMethod() async {
    try {
      await _apiClient.delete<Map<String, dynamic>>('/payment/token');
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<SavedCardChargeResult> chargeSavedCard(String movieId) async {
    final normalizedMovieId = movieId.trim();
    if (normalizedMovieId.isEmpty) {
      throw const ApiException('Missing movie ID');
    }

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/payment/mobile/token-charge',
        data: {'movieId': normalizedMovieId},
      );

      final data = response.data;
      if (data == null) {
        throw const ApiException('Missing saved card payment response');
      }

      return SavedCardChargeResult.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<PaymentHistoryResponse> fetchPaymentHistory({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/payment/history',
        queryParameters: {'page': page, 'limit': limit},
      );

      final data = response.data;
      if (data == null) {
        throw const ApiException('Missing payment history data');
      }

      return PaymentHistoryResponse.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
