import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class OCRScanScreen extends StatefulWidget {
  const OCRScanScreen({super.key});

  @override
  State<OCRScanScreen> createState() => _OCRScanScreenState();
}

class _OCRScanScreenState extends State<OCRScanScreen> {
  File? _image;
  String _extractedText = '';
  bool _loading = false;
  final picker = ImagePicker();
  final Uuid _uuid = Uuid();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _extractedText = '';
        _loading = true;
      });
      await _performOCR(_image!);
    }
  }

  Future<void> _performOCR(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    if (recognizedText.text.trim().isEmpty) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teks tidak terbaca, coba foto ulang')),
      );
      return;
    }

    setState(() {
      _extractedText = recognizedText.text;
      _loading = false;
    });
  }

  Future<void> _saveAsTransaction() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> existing =
        prefs.getStringList('financial_transactions') ?? [];

    final lines = _extractedText.split('\n');
    final totalLine = lines.reversed.firstWhere(
      (line) =>
          line.toLowerCase().contains('total') ||
          RegExp(r'rp[\s\.]?\d+', caseSensitive: false).hasMatch(line),
      orElse: () => '',
    );

    final amount =
        double.tryParse(
          RegExp(
                r'\d+(\.\d+)?',
              ).firstMatch(totalLine.replaceAll('.', ''))?.group(0) ??
              '0',
        ) ??
        0;

    final newTransaction = {
      'id': _uuid.v4(),
      'title': 'Pembelian dari Nota',
      'amount': amount,
      'type': 'expense',
      'date': DateTime.now().toIso8601String(),
      'description': _extractedText,
      'source': 'ocr',
    };

    existing.add(jsonEncode(newTransaction));
    await prefs.setStringList('financial_transactions', existing);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil disimpan')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Nota')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Ambil Foto Nota'),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            if (_extractedText.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hasil Scan:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(child: Text(_extractedText)),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _saveAsTransaction,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan ke Keuangan'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
