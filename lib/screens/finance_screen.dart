import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';

enum TransactionType { income, expense }

class FinancialTransaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String? description;
  final String? source;

  FinancialTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    this.description,
    this.source,
  });

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    return FinancialTransaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: json['amount'] as double,
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${json['type'] as String}',
      ),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String?,
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'date': date.toIso8601String(),
      'description': description,
      'source': source,
    };
  }
}

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  List<FinancialTransaction> _transactions = [];
  final Uuid _uuid = const Uuid();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? transactionsJson = prefs.getString('financial_transactions');
    if (transactionsJson != null) {
      final List<dynamic> decodedList = json.decode(transactionsJson);
      setState(() {
        _transactions = decodedList
            .map((json) => FinancialTransaction.fromJson(json))
            .toList();
      });
    }
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = json.encode(
      _transactions.map((t) => t.toJson()).toList(),
    );
    await prefs.setString('financial_transactions', encodedList);
  }

  Future<void> _saveSaldoKeuangan() async {
    final prefs = await SharedPreferences.getInstance();
    final double totalIncome = _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
    final double totalExpense = _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
    final double balance = totalIncome - totalExpense;
    await prefs.setInt('saldo_keuangan', balance.toInt());
  }

  void _addTransaction(FinancialTransaction transaction) {
    setState(() {
      _transactions.add(transaction);
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      _saveTransactions();
      _saveSaldoKeuangan(); // Tambahan penting
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaksi ${transaction.title} ditambahkan!')),
    );
  }

  void _deleteTransaction(String id) {
    setState(() {
      _transactions.removeWhere((t) => t.id == id);
      _saveTransactions();
      _saveSaldoKeuangan(); // Tambahan penting
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Transaksi dihapus!')));
  }

  // --- Fungsi scan nota dengan OCR (tidak berubah)
  Future<void> _scanReceipt() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memproses gambar nota...')),
      );
      try {
        final String? detectedText = await _performOcr(File(image.path));
        if (detectedText != null) {
          _processOcrText(detectedText);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mendeteksi teks dari nota.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saat memproses OCR: $e')),
        );
      }
    }
  }

  Future<String?> _performOcr(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    // ignore: deprecated_member_use
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      await textRecognizer.close();
      return recognizedText.text;
    } catch (e) {
      return null;
    }
  }

  void _processOcrText(String ocrText) {
    String titleGuess = 'Pembelian dari Nota';
    double? amountGuess;
    TransactionType typeGuess = TransactionType.expense;
    RegExp totalRegex = RegExp(
      r'TOTAL\s*Rp?\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)',
      caseSensitive: false,
    );
    RegExp totalRegex2 = RegExp(
      r'Jumlah\s*Rp?\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)',
      caseSensitive: false,
    );

    Match? match =
        totalRegex.firstMatch(ocrText) ?? totalRegex2.firstMatch(ocrText);
    if (match != null) {
      String amountStr =
          match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
      amountGuess = double.tryParse(amountStr);
    }

    List<String> itemsFound = [];
    for (var line in ocrText.split('\n')) {
      if (itemsFound.length < 3 &&
          line.length > 5 &&
          !line.contains('Rp') &&
          !line.toLowerCase().contains('total')) {
        itemsFound.add(line.trim());
      }
    }
    if (itemsFound.isNotEmpty) {
      titleGuess = 'Nota: ${itemsFound.join(', ')}';
      if (titleGuess.length > 50) {
        titleGuess = '${titleGuess.substring(0, 47)}...';
      }
    }

    final TextEditingController titleController =
        TextEditingController(text: titleGuess);
    final TextEditingController amountController =
        TextEditingController(text: amountGuess?.toStringAsFixed(2) ?? '');
    final TextEditingController descriptionController =
        TextEditingController(text: 'Scan dari nota:\n$ocrText');
    TransactionType selectedType = typeGuess;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Transaksi dari Nota'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Nama Transaksi'),
                    ),
                    TextFormField(
                      controller: amountController,
                      decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Deskripsi'),
                      maxLines: 4,
                    ),
                    DropdownButtonFormField<TransactionType>(
                      value: selectedType,
                      decoration:
                          const InputDecoration(labelText: 'Jenis Transaksi'),
                      items: TransactionType.values
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type == TransactionType.income
                                    ? 'Pemasukan'
                                    : 'Pengeluaran'),
                              ))
                          .toList(),
                      onChanged: (type) {
                        if (type != null) setState(() => selectedType = type);
                      },
                    ),
                    ListTile(
                      title: Text(
                          'Tanggal: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    double.tryParse(amountController.text) != null) {
                  final newTransaction = FinancialTransaction(
                    id: _uuid.v4(),
                    title: titleController.text,
                    amount: double.parse(amountController.text),
                    type: selectedType,
                    date: selectedDate,
                    description: descriptionController.text,
                    source: 'ocr',
                  );
                  _addTransaction(newTransaction);
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showAddTransactionDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descriptionController =
        TextEditingController();
    TransactionType selectedType = TransactionType.expense;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Transaksi Manual'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Nama Transaksi'),
                ),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                ),
                DropdownButton<TransactionType>(
                  value: selectedType,
                  items: TransactionType.values
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type == TransactionType.income
                                ? 'Pemasukan'
                                : 'Pengeluaran'),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => selectedType = value!),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                  child: Text(
                    'Tanggal: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    double.tryParse(amountController.text) != null) {
                  final newTransaction = FinancialTransaction(
                    id: _uuid.v4(),
                    title: titleController.text,
                    amount: double.parse(amountController.text),
                    type: selectedType,
                    date: selectedDate,
                    description: descriptionController.text,
                    source: 'manual',
                  );
                  _addTransaction(newTransaction);
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  double _getTotalFromOCR() {
    return _transactions
        .where((t) => t.source == 'ocr' && t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  @override
  Widget build(BuildContext context) {
    final double totalIncome = _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
    final double totalExpense = _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
    final double balance = totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance & Keuangan'),
        actions: [
          IconButton(icon: const Icon(Icons.camera_alt), onPressed: _scanReceipt),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ringkasan Keuangan',
                        style: GoogleFonts.poppins(fontSize: 20)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pemasukan:'),
                        Text('Rp ${totalIncome.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pengeluaran:'),
                        Text('Rp ${totalExpense.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total dari Scan Nota:'),
                        Text('Rp ${_getTotalFromOCR().toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.purple)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Saldo Bersih:',
                            style: GoogleFonts.poppins(fontSize: 16)),
                        Text('Rp ${balance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: balance >= 0 ? Colors.blue : Colors.orange,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _transactions.isEmpty
                ? const Center(child: Text('Belum ada transaksi'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final t = _transactions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ListTile(
                          leading: Icon(
                            t.type == TransactionType.income
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: t.type == TransactionType.income
                                ? Colors.green
                                : Colors.red,
                          ),
                          title: Text(t.title),
                          subtitle: Text(
                            '${t.description ?? ''}\n${t.date.day}/${t.date.month}/${t.date.year}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Rp ${t.amount.toStringAsFixed(2)}'),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteTransaction(t.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
