import 'package:flutter/material.dart';
import '../services/api/weather_api_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final weatherService = WeatherApiService();

  Map<String, dynamic>? weatherData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWeather(); // Panggil saat pertama tampil
  }

  Future<void> fetchWeather() async {
    setState(() {
      isLoading = true;
    });

    // Lokasi Jakarta: -6.2 (latitude), 106.8 (longitude)
    final result = await weatherService.fetchWeather(-6.2, 106.8);

    setState(() {
      weatherData = result?['current_weather'];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuaca Sekarang'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : weatherData == null
              ? const Center(child: Text('Gagal memuat data cuaca.'))
              : Center( // Ini membungkus semua agar di tengah
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Biar content di tengah
                      children: [
                        const Icon(Icons.cloud, size: 100, color: Colors.blue),
                        const SizedBox(height: 20),
                        Text(
                          'Suhu: ${weatherData!['temperature']}°C',
                          style: const TextStyle(fontSize: 26),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Kecepatan Angin: ${weatherData!['windspeed']} km/h',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Waktu: ${weatherData!['time']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: fetchWeather,
                          child: const Text('Refresh Cuaca'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
