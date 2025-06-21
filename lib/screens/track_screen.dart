import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import '../services/location_service.dart';

class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  late GoogleMapController mapController;
  final LocationService _locationService = LocationService();
  final Completer<GoogleMapController> _controller = Completer();
  final AssetsAudioPlayer _audioPlayer = AssetsAudioPlayer();
  LatLng _currentLatLng = const LatLng(
    -6.200000,
    106.816666,
  ); // default Jakarta
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLoading = true);
    Position? position = await _locationService.getCurrentLocation();
    if (position != null) {
      _currentLatLng = LatLng(position.latitude, position.longitude);
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLng(_currentLatLng));
    }
    setState(() => _isLoading = false);
  }

  void _triggerAlarm() {
    _audioPlayer.open(
      Audio("assets/sounds/alarm.mp3"),
      loopMode: LoopMode.single,
      showNotification: true,
    );
  }

  void _stopAlarm() {
    _audioPlayer.stop();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Track & Alert"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLocation,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentLatLng,
                      zoom: 16,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('currentLocation'),
                        position: _currentLatLng,
                        infoWindow: const InfoWindow(title: 'Lokasi Saya'),
                      ),
                    },
                    onMapCreated:
                        (controller) => _controller.complete(controller),
                    myLocationEnabled: true,
                  ),
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.sos),
                          label: const Text("Trigger Alarm"),
                          onPressed: _triggerAlarm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.stop_circle),
                          label: const Text("Stop Alarm"),
                          onPressed: _stopAlarm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
