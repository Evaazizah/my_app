import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? userLocation;
  String? catFact;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _getLocation();
    await _getCatFact();
  }

  Future<void> _getLocation() async {
    await Geolocator.requestPermission();
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      userLocation = LatLng(pos.latitude, pos.longitude);
    });
  }

  Future<void> _getCatFact() async {
    final res = await http.get(Uri.parse('https://catfact.ninja/fact'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        catFact = data['fact'];
      });
    } else {
      setState(() {
        catFact = 'Gagal mengambil fakta kucing.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peta & Fakta Kucing')),
      body: userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      // ignore: deprecated_member_use
                      center: userLocation,
                      // ignore: deprecated_member_use
                      zoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.catmap_app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 60,
                            height: 60,
                            point: userLocation!,
                            child: const Icon(Icons.location_pin,
                                color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.black87,
                  width: double.infinity,
                  child: Text(
                    catFact ?? 'Mengambil fakta kucing...',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
    );
  }
}