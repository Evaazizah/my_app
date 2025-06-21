import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();

  late final Dio dio;
  final Logger _logger = Logger();
  static const String weatherApiKey = 'YOUR_API_KEY_HERE';

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.trenix.my.id',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add Interceptors
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.i('Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.i('Response: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          _logger.e('Error: ${e.message}');
          return handler.next(e);
        },
      ),
    );
  }

  factory DioClient() => _instance;

  void setAuthToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }
}
