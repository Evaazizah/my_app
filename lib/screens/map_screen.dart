import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? userLocation;

  List provinces = [];
  List regencies = [];

  String? selectedProvinceId;
  String? selectedRegency;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _fetchProvinces();
  }

  Future<void> _initLocation() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      userLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _fetchProvinces() async {
    final res = await http.get(Uri.parse('https://emsifa.github.io/api-wilayah-indonesia/api/provinces.json'));
    if (res.statusCode == 200) {
      setState(() {
        provinces = jsonDecode(res.body);
      });
    }
  }

  Future<void> _fetchRegencies(String provinceId) async {
    final res = await http.get(Uri.parse('https://emsifa.github.io/api-wilayah-indonesia/api/regencies/$provinceId.json'));
    if (res.statusCode == 200) {
      setState(() {
        regencies = jsonDecode(res.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Peta + Wilayah Indonesia")),
      body: Column(
        children: [
          // Dropdown Provinsi
          Padding(
            padding: const EdgeInsets.all(10),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Pilih Provinsi"),
              items: provinces.map<DropdownMenuItem<String>>((prov) {
                return DropdownMenuItem(
                  value: prov['id'],
                  child: Text(prov['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedProvinceId = value;
                  selectedRegency = null;
                  regencies = [];
                });
                if (value != null) _fetchRegencies(value);
              },
            ),
          ),

          // Dropdown Kabupaten
          if (regencies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Pilih Kabupaten"),
                items: regencies.map<DropdownMenuItem<String>>((kab) {
                  return DropdownMenuItem(
                    value: kab['name'],
                    child: Text(kab['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRegency = value;
                  });
                },
              ),
            ),

          const SizedBox(height: 10),

          // Peta
          Expanded(
            child: userLocation == null
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                    options: MapOptions(
                      initialCenter: userLocation!,
                      initialZoom: 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.trenix',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: userLocation!,
                            width: 60,
                            height: 60,
                            child: const Icon(Icons.location_pin, size: 40, color: Colors.red),
                          )
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
