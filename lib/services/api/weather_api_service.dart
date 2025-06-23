import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherApiService {
  final String baseUrl = 'https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4={kode_wilayah_tingkat_iv}';

  Future<Map<String, dynamic>?> fetchWeather(double lat, double lon) async {
    final url = Uri.parse('$baseUrl?latitude=$lat&longitude=$lon&current_weather=true');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      // ignore: avoid_print
      print('Failed to fetch weather: ${response.statusCode}');
      return null;
    }
  }
}
