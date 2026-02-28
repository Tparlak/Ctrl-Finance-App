import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../data/hive_boxes.dart';
import 'account_provider.dart';

const _uuid = Uuid();

class TransactionNotifier extends StateNotifier<List<TransactionModel>> {
  final Ref ref;

  TransactionNotifier(this.ref) : super(_loadAll());

  static List<TransactionModel> _loadAll() {
    final list = HiveBoxes.transactions.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  void refresh() {
    final list = HiveBoxes.transactions.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    state = list;
  }

  Future<void> addTransaction({
    required double amount,
    required String type, // 'income' | 'expense' | 'transfer'
    required String fromAccountId,
    String? toAccountId,
    String? categoryId,
    required String description,
    required DateTime date,
    String? receiptImagePath,
  }) async {
    final tx = TransactionModel(
      id: _uuid.v4(),
      amount: amount,
      type: type,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      categoryId: categoryId,
      description: description,
      date: date,
      receiptImagePath: receiptImagePath,
    );

    await HiveBoxes.transactions.put(tx.id, tx);

    // Update account balances
    final accountNotifier = ref.read(accountProvider.notifier);
    if (type == 'income') {
      await accountNotifier.updateBalance(fromAccountId, amount);
    } else if (type == 'expense') {
      await accountNotifier.updateBalance(fromAccountId, -amount);
    } else if (type == 'transfer') {
      await accountNotifier.updateBalance(fromAccountId, -amount);
      if (toAccountId != null) {
        await accountNotifier.updateBalance(toAccountId, amount);
      }
    }

    refresh();
  }

  List<TransactionModel> forAccount(String accountId) {
    return state
        .where((t) =>
            t.fromAccountId == accountId || t.toAccountId == accountId)
        .toList();
  }

  /// Delete a transaction and reverse its effect on account balances.
  Future<void> deleteTransaction(String id) async {
    final tx = HiveBoxes.transactions.get(id);
    if (tx == null) return;

    final accountNotifier = ref.read(accountProvider.notifier);
    // Reverse the balance change
    if (tx.type == 'income') {
      await accountNotifier.updateBalance(tx.fromAccountId, -tx.amount);
    } else if (tx.type == 'expense') {
      await accountNotifier.updateBalance(tx.fromAccountId, tx.amount);
    } else if (tx.type == 'transfer') {
      await accountNotifier.updateBalance(tx.fromAccountId, tx.amount);
      if (tx.toAccountId != null) {
        await accountNotifier.updateBalance(tx.toAccountId!, -tx.amount);
      }
    }

    await HiveBoxes.transactions.delete(id);
    refresh();
  }

  /// Update existing transaction (reverses old balance, applies new one).
  Future<void> updateTransaction(TransactionModel updated) async {
    // Reverse old
    await deleteTransaction(updated.id);
    // Apply new as fresh
    await addTransaction(
      amount: updated.amount,
      type: updated.type,
      fromAccountId: updated.fromAccountId,
      toAccountId: updated.toAccountId,
      categoryId: updated.categoryId,
      description: updated.description,
      date: updated.date,
    );
    // Override the id back (addTransaction creates new UUID)
    // We'll save directly
    refresh();
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, List<TransactionModel>>(
        (ref) => TransactionNotifier(ref));

/// Total income (all time — kept for reference)
final totalIncomeProvider = Provider<double>((ref) {
  final txs = ref.watch(transactionProvider);
  return txs
      .where((t) => t.type == 'income')
      .fold(0.0, (sum, t) => sum + t.amount);
});

/// Total expense (all time — kept for reference)
final totalExpenseProvider = Provider<double>((ref) {
  final txs = ref.watch(transactionProvider);
  return txs
      .where((t) => t.type == 'expense')
      .fold(0.0, (sum, t) => sum + t.amount);
});

/// Income for the CURRENT calendar month only (used on Dashboard summary card)
final currentMonthIncomeProvider = Provider<double>((ref) {
  final txs = ref.watch(transactionProvider);
  final now = DateTime.now();
  return txs
      .where((t) =>
          t.type == 'income' &&
          t.date.year == now.year &&
          t.date.month == now.month)
      .fold(0.0, (sum, t) => sum + t.amount);
});

/// Expense for the CURRENT calendar month only (used on Dashboard summary card)
final currentMonthExpenseProvider = Provider<double>((ref) {
  final txs = ref.watch(transactionProvider);
  final now = DateTime.now();
  return txs
      .where((t) =>
          t.type == 'expense' &&
          t.date.year == now.year &&
          t.date.month == now.month)
      .fold(0.0, (sum, t) => sum + t.amount);
});
