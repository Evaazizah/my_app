import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import '../services/geofence_service.dart';
import '../services/alarm_audio_service.dart';

class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  final geofence = GeofenceService(
    geofenceLat: -6.200000,
    geofenceLng: 106.816666,
  );

  final AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  void _startMonitoring() async {
    while (mounted) {
      bool outside = await geofence.isOutsideGeofence();
      if (outside && !isPlaying) {
        _playCustomAlarm();
      } else if (!outside && isPlaying) {
        _stopAlarm();
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  void _playCustomAlarm() async {
    final path = await AlarmAudioService.getAudioPath();
    if (path != null && path.isNotEmpty) {
      try {
        await audioPlayer.open(
          Audio.file(path),
          loopMode: LoopMode.single,
          showNotification: true,
        );
        setState(() => isPlaying = true);
      } catch (e) {
        debugPrint("❌ Gagal memainkan audio: $e");
      }
    }
  }

  void _stopAlarm() async {
    await audioPlayer.stop();
    setState(() => isPlaying = false);
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Track & Alert")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, size: 64, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              isPlaying
                  ? "🚨 Anda keluar dari zona aman!"
                  : "✅ Anda masih di dalam zona aman",
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

