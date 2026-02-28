import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import 'transaction_provider.dart';
import 'category_provider.dart';

class CategoryTotal {
  final String categoryName;
  final String categoryId;
  final double total;
  final double percentage;
  
  const CategoryTotal({
    required this.categoryName,
    required this.categoryId,
    required this.total,
    required this.percentage,
  });
}

class AnalyticsNotifier extends StateNotifier<List<CategoryTotal>> {
  final Ref ref;

  AnalyticsNotifier(this.ref) : super([]) {
    // Whenever transactions or categories change, recalculate
    ref.listen(transactionProvider, (_, __) => _calculate());
    ref.listen(expenseCategoryProvider, (_, __) => _calculate());
    _calculate();
  }

  void _calculate() {
    final transactions = ref.read(transactionProvider);
    final categories = ref.read(expenseCategoryProvider);
    
    final now = DateTime.now();
    final monthly = transactions.where((t) =>
      t.type == 'expense' &&
      t.date.year == now.year &&
      t.date.month == now.month
    ).toList();

    final grouped = <String, double>{};
    for (final t in monthly) {
      if (t.categoryId != null) {
        grouped[t.categoryId!] = (grouped[t.categoryId!] ?? 0) + t.amount;
      }
    }

    final total = grouped.values.fold(0.0, (a, b) => a + b);
    if (total == 0) {
      state = [];
      return;
    }

    final result = grouped.entries.map((e) {
      final cat = categories.where((c) => c.id == e.key).firstOrNull;
      return CategoryTotal(
        categoryId: e.key,
        categoryName: cat?.name ?? 'Diğer',
        total: e.value,
        percentage: (e.value / total) * 100,
      );
    }).toList()..sort((a, b) => b.total.compareTo(a.total));

    state = result;
  }
}

final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, List<CategoryTotal>>((ref) {
  return AnalyticsNotifier(ref);
});
