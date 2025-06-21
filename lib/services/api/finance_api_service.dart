import 'package:dio/dio.dart';
import 'package:trenix/services/api/dio_client.dart';

class Transaction {
  final String id;
  final String type;
  final double amount;
  final String category;
  final DateTime date;
  final String description;
  final String? referenceId;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    required this.description,
    this.referenceId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String,
      referenceId: json['referenceId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(),
    'description': description,
    if (referenceId != null) 'referenceId': referenceId,
  };
}

class FinanceApiService {
  final Dio _dio;

  FinanceApiService({Dio? dio}) : _dio = dio ?? DioClient().dio;

  Future<List<Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};

      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      if (category != null) {
        queryParams['category'] = category;
      }

      final response = await _dio.get(
        '/transactions',
        queryParameters: queryParams,
      );

      return (response.data as List)
          .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to load transactions: $e');
    }
  }

  Future<Transaction> createTransaction(Transaction transaction) async {
    try {
      final response = await _dio.post(
        '/transactions',
        data: transaction.toJson(),
      );

      return Transaction.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<double> getCurrentBalance() async {
    try {
      final response = await _dio.get('/balance/current');
      return (response.data['balance'] as num).toDouble();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<String>> getTransactionCategories() async {
    try {
      final response = await _dio.get('/categories');
      return (response.data as List).cast<String>();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      final message = data is Map ? data['message'] ?? e.message : e.message;
      return Exception('API Error: $message');
    }
    return Exception('Network Error: ${e.message}');
  }
}
