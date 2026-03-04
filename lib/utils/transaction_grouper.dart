import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

class TransactionGrouper {
  static Map<String, List<TransactionModel>> groupByDate(List<TransactionModel> transactions) {
    final map = <String, List<TransactionModel>>{};
    // Sort transactions by date descending (newest first) before grouping if not already sorted
    final sortedList = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    for (final t in sortedList) {
      final key = _formatDateKey(t.date);
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  static String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(txDay).inDays;

    if (diff == 0) return 'BUGÜN';
    if (diff == 1) return 'DÜN';
    
    // e.g., "2 MART Pazartesi"
    return DateFormat("d MMMM EEEE", "tr_TR").format(date).toUpperCase();
  }
}
