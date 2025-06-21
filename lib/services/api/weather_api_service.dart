import 'package:dio/dio.dart';
import 'package:trenix/services/api/dio_client.dart';

// Contoh model data untuk Weather
class Weather {
  final double temperature;
  final String description;
  final String iconCode;
  final String cityName;

  Weather({
    required this.temperature,
    required this.description,
    required this.iconCode,
    required this.cityName,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperature: json['main']['temp'].toDouble(),
      description: json['weather'][0]['description'],
      iconCode: json['weather'][0]['icon'],
      cityName: json['name'],
    );
  }
}

class WeatherApiService {
  // Untuk OpenWeatherMap, kita mungkin perlu instance Dio terpisah jika baseURL-nya berbeda
  // atau tambahkan parameter baseURL ke DioClient jika kamu mau fleksibel.
  // Untuk contoh ini, kita buat instance Dio baru dengan baseURL OpenWeatherMap.
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.openweathermap.org/data/2.5',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  final String _apiKey = DioClient.weatherApiKey;

  Future<Weather> getCurrentWeatherByCity(String cityName) async {
    try {
      final response = await _dio.get(
        '/weather',
        queryParameters: {
          'q': cityName,
          'appid': _apiKey,
          'units': 'metric', // Celcius
          'lang': 'id', // Bahasa Indonesia
        },
      );
      if (response.statusCode == 200) {
        return Weather.fromJson(response.data);
      } else {
        throw Exception('Failed to load weather data');
      }
    } on DioException catch (e) {
      throw Exception('Failed to load weather data: ${e.message}');
    }
  }

  Future<Weather> getCurrentWeatherByCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await _dio.get(
        '/weather',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'appid': _apiKey,
          'units': 'metric', // Celcius
          'lang': 'id', // Bahasa Indonesia
        },
      );
      if (response.statusCode == 200) {
        return Weather.fromJson(response.data);
      } else {
        throw Exception('Failed to load weather data');
      }
    } on DioException catch (e) {
      throw Exception('Failed to load weather data: ${e.message}');
    }
  }
}
