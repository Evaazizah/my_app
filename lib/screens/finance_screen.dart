import 'package:flutter/material.dart';
import 'package:trenix/services/api/finance_repository.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final _repo = FinanceRepository();
  late Future<List<dynamic>> _financeData;

  @override
  void initState() {
    super.initState();
    _financeData = _repo.getFinanceItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Finance')),
      body: FutureBuilder<List<dynamic>>(
        future: _financeData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada data keuangan.'));
          }

          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item['title'] ?? 'Tanpa Judul'),
                subtitle: Text(item['amount'].toString()),
              );
            },
          );
        },
      ),
    );
  }
}
