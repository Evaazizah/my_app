// lib/screens/finance_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart'; // Import ini
import 'package:http/http.dart' as http; // Import ini
import 'dart:io'; // Untuk File

// --- Model Data untuk Transaksi Keuangan (Tidak Berubah) ---
enum TransactionType { income, expense }

class FinancialTransaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String? description;

  FinancialTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    this.description,
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
    };
  }
}

// --- Halaman Utama Finance ---
class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  List<FinancialTransaction> _transactions = [];
  final Uuid _uuid = Uuid();
  final ImagePicker _picker = ImagePicker();

  // GANTI DENGAN API KEY GOOGLE CLOUD VISION API KAMU!!!
  // Cara paling aman adalah menyimpannya di file .env atau build config,
  // tapi untuk contoh cepat, kita taruh di sini. PASTIKAN UNTUK MEMBATASI API KEY DI GOOGLE CLOUD.
  final String _googleVisionApiKey =
      'YOUR_GOOGLE_CLOUD_VISION_API_KEY'; // <--- GANTI INI!

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

  // --- Fungsi untuk Scan Nota ---
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
        print('Error during OCR: $e');
      }
    }
  }

  Future<String?> _performOcr(File imageFile) async {
    if (_googleVisionApiKey == 'YOUR_GOOGLE_CLOUD_VISION_API_KEY') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Peringatan: API Key Google Vision belum diset!'),
        ),
      );
      return null;
    }

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse(
        'https://vision.googleapis.com/v1/images:annotate?key=$_googleVisionApiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'TEXT_DETECTION'},
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['responses'] != null && data['responses'].isNotEmpty) {
        return data['responses'][0]['fullTextAnnotation']['text'];
      }
    } else {
      print(
        'Google Vision API Error: ${response.statusCode} - ${response.body}',
      );
    }
    return null;
  }

  // --- Parsing Teks OCR & Menampilkan Dialog Konfirmasi ---
  void _processOcrText(String ocrText) {
    // Ini adalah bagian PALING KRITIS dan SULIT.
    // Parsing teks dari struk itu sangat bervariasi formatnya.
    // Contoh sederhana: cari "Total" atau "Jumlah" dan angka setelahnya.
    // Untuk kasus nyata, Anda perlu regex atau ML model yang lebih canggih.

    String titleGuess = 'Pembelian dari Nota';
    double? amountGuess;
    TransactionType typeGuess =
        TransactionType.expense; // Nota biasanya pengeluaran

    // Logika parsing sederhana (bisa sangat bervariasi tergantung format nota)
    RegExp totalRegex = RegExp(
      r'TOTAL\s*Rp?\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)',
      caseSensitive: false,
    );
    RegExp totalRegex2 = RegExp(
      r'Jumlah\s*Rp?\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)',
      caseSensitive: false,
    );
    RegExp itemRegex = RegExp(
      r'(\d+)\s+x\s+(.+?)\s+Rp?\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)',
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

    // Coba ambil beberapa item sebagai judul
    List<String> itemsFound = [];
    for (var line in ocrText.split('\n')) {
      if (itemsFound.length < 3 &&
          line.length > 5 &&
          !line.contains('Rp') &&
          !line.contains('Total')) {
        itemsFound.add(line.trim());
      }
    }
    if (itemsFound.isNotEmpty) {
      titleGuess = 'Nota: ${itemsFound.join(', ')}';
      if (titleGuess.length > 50)
        titleGuess = titleGuess.substring(0, 47) + '...';
    }

    // Tampilkan dialog konfirmasi kepada pengguna
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController _titleController = TextEditingController(
          text: titleGuess,
        );
        final TextEditingController _amountController = TextEditingController(
          text: amountGuess?.toStringAsFixed(2) ?? '',
        );
        final TextEditingController _descriptionController =
            TextEditingController(text: 'Scan dari nota:\n$ocrText');
        TransactionType _selectedType = typeGuess;
        DateTime _selectedDate = DateTime.now();

        return AlertDialog(
          title: Text(
            'Konfirmasi Transaksi dari Nota',
            style: GoogleFonts.poppins(),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Nama Transaksi',
                        labelStyle: GoogleFonts.poppins(),
                      ),
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Tidak boleh kosong' : null,
                    ),
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Jumlah (Rp)',
                        labelStyle: GoogleFonts.poppins(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            double.tryParse(value) == null) {
                          return 'Masukkan angka valid';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi',
                        labelStyle: GoogleFonts.poppins(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<TransactionType>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        labelText: 'Jenis Transaksi',
                        labelStyle: GoogleFonts.poppins(),
                      ),
                      items:
                          TransactionType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                type == TransactionType.income
                                    ? 'Pemasukan'
                                    : 'Pengeluaran',
                                style: GoogleFonts.poppins(),
                              ),
                            );
                          }).toList(),
                      onChanged: (type) {
                        if (type != null) {
                          setState(() {
                            _selectedType = type;
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: Text(
                        'Tanggal: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: GoogleFonts.poppins(),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null && picked != _selectedDate) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Teks Asli dari Nota:',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      constraints: BoxConstraints(maxHeight: 150),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          ocrText,
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () {
                // Validasi lagi input sebelum menambahkan
                if (_titleController.text.isNotEmpty &&
                    double.tryParse(_amountController.text) != null) {
                  final newTransaction = FinancialTransaction(
                    id: _uuid.v4(),
                    title: _titleController.text,
                    amount: double.parse(_amountController.text),
                    type: _selectedType,
                    date: _selectedDate,
                    description: _descriptionController.text,
                  );
                  _addTransaction(newTransaction);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Judul atau jumlah tidak valid.')),
                  );
                }
              },
              child: Text('Simpan', style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
  }

  // --- Dialog untuk Menambahkan Transaksi Baru (tidak berubah banyak, hanya penyesuaian sedikit) ---
  void _showAddTransactionDialog() {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _amountController = TextEditingController();
    final TextEditingController _descriptionController =
        TextEditingController();
    TransactionType _selectedType = TransactionType.expense; // Default expense
    DateTime _selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tambah Transaksi Baru', style: GoogleFonts.poppins()),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Nama Transaksi',
                          labelStyle: GoogleFonts.poppins(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama transaksi tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Jumlah (Rp)',
                          labelStyle: GoogleFonts.poppins(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Jumlah tidak boleh kosong';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Masukkan angka yang valid';
                          }
                          if (double.parse(value) <= 0) {
                            return 'Jumlah harus lebih dari 0';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi (Opsional)',
                          labelStyle: GoogleFonts.poppins(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<TransactionType>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Jenis Transaksi',
                          labelStyle: GoogleFonts.poppins(),
                        ),
                        items:
                            TransactionType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type == TransactionType.income
                                      ? 'Pemasukan'
                                      : 'Pengeluaran',
                                  style: GoogleFonts.poppins(),
                                ),
                              );
                            }).toList(),
                        onChanged: (type) {
                          if (type != null) {
                            setState(() {
                              _selectedType = type;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        title: Text(
                          'Tanggal: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: GoogleFonts.poppins(),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null && picked != _selectedDate) {
                            setState(() {
                              _selectedDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final newTransaction = FinancialTransaction(
                    id: _uuid.v4(),
                    title: _titleController.text,
                    amount: double.parse(_amountController.text),
                    type: _selectedType,
                    date: _selectedDate,
                    description:
                        _descriptionController.text.isNotEmpty
                            ? _descriptionController.text
                            : null,
                  );
                  _addTransaction(newTransaction);
                  Navigator.pop(context);
                }
              },
              child: Text('Tambah', style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
  }

  // --- UI Utama Halaman Finance (Ditambah tombol Scan Nota) ---
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
        title: Text(
          'Finance & Keuangan',
          style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt), // Icon untuk scan nota
            onPressed: _scanReceipt, // Panggil fungsi scan nota
            tooltip: 'Scan Nota',
          ),
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
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Pemasukan:',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                        Text(
                          'Rp ${totalIncome.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Pengeluaran:',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                        Text(
                          'Rp ${totalExpense.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, thickness: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Saldo Bersih:',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rp ${balance.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                balance >= 0
                                    ? Colors.blueAccent
                                    : Colors.orange,
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
                    ? Center(
                      child: Text(
                        'Belum ada transaksi. Tambahkan satu atau scan nota!',
                        style: GoogleFonts.poppins(),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ListTile(
                            leading: Icon(
                              transaction.type == TransactionType.income
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color:
                                  transaction.type == TransactionType.income
                                      ? Colors.green
                                      : Colors.red,
                            ),
                            title: Text(
                              transaction.title,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  transaction.description ?? 'Tanpa deskripsi',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Rp ${transaction.amount.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        transaction.type ==
                                                TransactionType.income
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.grey,
                                  ),
                                  onPressed:
                                      () => _deleteTransaction(transaction.id),
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
