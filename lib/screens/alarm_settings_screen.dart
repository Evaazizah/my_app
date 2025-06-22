import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/alarm_audio_service.dart';
import 'package:permission_handler/permission_handler.dart';

class AlarmSettingsScreen extends StatefulWidget {
  const AlarmSettingsScreen({super.key});

  @override
  State<AlarmSettingsScreen> createState() => _AlarmSettingsScreenState();
}


class _AlarmSettingsScreenState extends State<AlarmSettingsScreen> {
  String? selectedPath;

  @override
  void initState() {
    super.initState();
    _loadAudioPath();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    if (await Permission.audio.isDenied) {
      await Permission.audio.request();
    }
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      selectedPath = result.files.single.path!;
      await AlarmAudioService.saveAudioPath(selectedPath!);
      setState(() {});
    }
  }

  Future<void> _clearAudio() async {
    await AlarmAudioService.clearAudioPath();
    setState(() => selectedPath = null);
  }

  Future<void> _loadAudioPath() async {
    selectedPath = await AlarmAudioService.getAudioPath();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pengaturan Alarm")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _pickAudio,
              child: Text("Pilih Suara Alarm Sendiri"),
            ),
            SizedBox(height: 16),
            if (selectedPath != null) ...[
              Text("✔️ File terpilih:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(selectedPath!),
              ElevatedButton(
                onPressed: _clearAudio,
                child: Text("Hapus Pengaturan Alarm"),
              ),
            ]
          ],
        ),
      ),
    );
  }
}