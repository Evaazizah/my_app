import 'package:trenix/services/api/finance_api_service.dart';

class FinanceRepository {
  final FinanceApiService _apiService;

  FinanceRepository({required FinanceApiService apiService})
    : _apiService = apiService;

  Future<List<Transaction>> getRecentTransactions() async {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, now.day);
    return _apiService.getTransactions(startDate: lastMonth);
  }

  Future<double> getAvailableBalance() => _apiService.getCurrentBalance();

  Future<void> addTransaction({
    required String type,
    required double amount,
    required String category,
    required String description,
  }) async {
    final transaction = Transaction(
      id: '', // Server will generate ID
      type: type,
      amount: amount,
      category: category,
      date: DateTime.now(),
      description: description,
    );

    await _apiService.createTransaction(transaction);
  }
}
