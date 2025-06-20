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
        (e) => e.toString() == 'TransactionType.' + (json['type'] as String),
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
  final Uuid _uuid = Uuid();
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
        _transactions =
            decodedList
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

  void _addTransaction(FinancialTransaction transaction) {
    setState(() {
      _transactions.add(transaction);
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      _saveTransactions();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaksi ${transaction.title} ditambahkan!')),
    );
  }

  void _deleteTransaction(String id) {
    setState(() {
      _transactions.removeWhere((t) => t.id == id);
      _saveTransactions();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Transaksi dihapus!')));
  }

  Future<void> _scanReceipt() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Memproses gambar nota...')));
      try {
        final String? detectedText = await _performOcr(File(image.path));
        if (detectedText != null) {
          _processOcrText(detectedText);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mendeteksi teks dari nota.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saat memproses OCR: $e')));
      }
    }
  }

  Future<String?> _performOcr(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
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
      String amountStr = match
          .group(1)!
          .replaceAll('.', '')
          .replaceAll(',', '.');
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
      if (titleGuess.length > 50)
        titleGuess = titleGuess.substring(0, 47) + '...';
    }

    final TextEditingController _titleController = TextEditingController(
      text: titleGuess,
    );
    final TextEditingController _amountController = TextEditingController(
      text: amountGuess?.toStringAsFixed(2) ?? '',
    );
    final TextEditingController _descriptionController = TextEditingController(
      text: 'Scan dari nota:\n$ocrText',
    );
    TransactionType _selectedType = typeGuess;
    DateTime _selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Transaksi dari Nota'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: 'Nama Transaksi'),
                    ),
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(labelText: 'Jumlah (Rp)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(labelText: 'Deskripsi'),
                      maxLines: 4,
                    ),
                    DropdownButtonFormField<TransactionType>(
                      value: _selectedType,
                      decoration: InputDecoration(labelText: 'Jenis Transaksi'),
                      items:
                          TransactionType.values
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type == TransactionType.income
                                        ? 'Pemasukan'
                                        : 'Pengeluaran',
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (type) {
                        if (type != null) setState(() => _selectedType = type);
                      },
                    ),
                    ListTile(
                      title: Text(
                        'Tanggal: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null)
                          setState(() => _selectedDate = picked);
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
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty &&
                    double.tryParse(_amountController.text) != null) {
                  final newTransaction = FinancialTransaction(
                    id: _uuid.v4(),
                    title: _titleController.text,
                    amount: double.parse(_amountController.text),
                    type: _selectedType,
                    date: _selectedDate,
                    description: _descriptionController.text,
                    source: 'ocr',
                  );
                  _addTransaction(newTransaction);
                  Navigator.pop(context);
                }
              },
              child: Text('Simpan'),
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

  void _showAddTransactionDialog() {
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _amountController = TextEditingController();
    final TextEditingController _descriptionController =
        TextEditingController();
    TransactionType _selectedType = TransactionType.expense;
    DateTime _selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tambah Transaksi Manual'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Nama Transaksi'),
                ),
                TextField(
                  controller: _amountController,
                  decoration: InputDecoration(labelText: 'Jumlah (Rp)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Deskripsi'),
                ),
                DropdownButton<TransactionType>(
                  value: _selectedType,
                  items:
                      TransactionType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                type == TransactionType.income
                                    ? 'Pemasukan'
                                    : 'Pengeluaran',
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _selectedType = value!),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: Text(
                    'Tanggal: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty &&
                    double.tryParse(_amountController.text) != null) {
                  final newTransaction = FinancialTransaction(
                    id: _uuid.v4(),
                    title: _titleController.text,
                    amount: double.parse(_amountController.text),
                    type: _selectedType,
                    date: _selectedDate,
                    description: _descriptionController.text,
                    source: 'manual',
                  );
                  _addTransaction(newTransaction);
                  Navigator.pop(context);
                }
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
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
        title: Text('Finance & Keuangan'),
        actions: [
          IconButton(icon: Icon(Icons.camera_alt), onPressed: _scanReceipt),
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
                    Text(
                      'Ringkasan Keuangan',
                      style: GoogleFonts.poppins(fontSize: 20),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Pemasukan:'),
                        Text(
                          'Rp ${totalIncome.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Pengeluaran:'),
                        Text(
                          'Rp ${totalExpense.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total dari Scan Nota:'),
                        Text(
                          'Rp ${_getTotalFromOCR().toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.purple),
                        ),
                      ],
                    ),
                    Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Saldo Bersih:',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                        Text(
                          'Rp ${balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: balance >= 0 ? Colors.blue : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child:
                _transactions.isEmpty
                    ? Center(child: Text('Belum ada transaksi'))
                    : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final t = _transactions[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 12.0),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ListTile(
                            leading: Icon(
                              t.type == TransactionType.income
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color:
                                  t.type == TransactionType.income
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
                                  icon: Icon(Icons.delete),
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
        child: Icon(Icons.add),
      ),
    );
  }
}
