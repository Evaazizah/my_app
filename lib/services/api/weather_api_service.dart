import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherApiService {
  final String baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<Map<String, dynamic>?> fetchWeather(double lat, double lon) async {
    final url = Uri.parse('$baseUrl?latitude=$lat&longitude=$lon&current_weather=true');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      print('Failed to fetch weather: ${response.statusCode}');
      return null;
    }
  }
}
