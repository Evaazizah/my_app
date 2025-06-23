import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  Future<Directory> _getDownloadDirectory() async {
    final dir = await getExternalStorageDirectory();
    if (dir != null) {
      final downloadPath = Directory('${dir.path.split('Android')[0]}Download');
      if (!await downloadPath.exists()) await downloadPath.create(recursive: true);
      return downloadPath;
    }
    return Directory.systemTemp;
  }

  Future<void> exportTugasToPdf(BuildContext context) async {
    List<String> tugas = [
      "Belajar Flutter",
      "Mengerjakan UAS",
      "Baca Buku",
      "Submit Tugas"
    ];

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Daftar Tugas', style: const pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 20),
            ...tugas.map((t) => pw.Bullet(text: t)),
          ],
        ),
      ),
    );

    final status = await Permission.storage.request();
    if (status.isGranted) {
      final dir = await _getDownloadDirectory();
      final file = File("${dir.path}/tugas_export.pdf");
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tugas berhasil di-export ke ${file.path}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akses penyimpanan ditolak.')),
      );
    }
  }

  Future<void> exportKeuanganToCsv(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final String? transaksiJson = prefs.getString('financial_transactions');

    if (transaksiJson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data keuangan untuk diekspor.')),
      );
      return;
    }

    final List<dynamic> transaksiList = jsonDecode(transaksiJson);
    final List<List<String>> csvData = [
      ['ID', 'Judul', 'Jumlah', 'Tipe', 'Tanggal', 'Deskripsi', 'Sumber']
    ];

    for (var item in transaksiList) {
      csvData.add([
        item['id'] ?? '',
        item['title'] ?? '',
        item['amount'].toString(),
        item['type'] ?? '',
        item['date'] ?? '',
        item['description'] ?? '',
        item['source'] ?? '',
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    final status = await Permission.storage.request();

    if (status.isGranted) {
      final dir = await _getDownloadDirectory();
      final file = File('${dir.path}/keuangan_export.csv');
      await file.writeAsString(csvString);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data keuangan berhasil diekspor ke ${file.path}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akses penyimpanan ditolak.')),
      );
    }
  }

  Future<void> exportCuacaDanLokasi(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final weatherData = prefs.getString('cuaca_data');
    final locationData = prefs.getString('lokasi_data');

    if (weatherData == null && locationData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data cuaca atau lokasi.')),
      );
      return;
    }

    final output = StringBuffer();
    output.writeln('--- Data Cuaca ---\n${weatherData ?? 'Tidak ada'}\n');
    output.writeln('--- Data Lokasi ---\n${locationData ?? 'Tidak ada'}\n');

    final status = await Permission.storage.request();
    if (status.isGranted) {
      final dir = await _getDownloadDirectory();
      final file = File('${dir.path}/cuaca_lokasi.txt');
      await file.writeAsString(output.toString());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data cuaca & lokasi diekspor ke ${file.path}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akses penyimpanan ditolak.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pilih data yang ingin diekspor:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => exportTugasToPdf(context),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Export Tugas (PDF)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => exportKeuanganToCsv(context),
              icon: const Icon(Icons.attach_money),
              label: const Text('Export Keuangan (CSV)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => exportCuacaDanLokasi(context),
              icon: const Icon(Icons.cloud_download),
              label: const Text('Export Cuaca & Lokasi'),
            ),
          ],
        ),
      ),
    );
  }
}
