import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/fixed_expense.dart';
import '../data/hive_boxes.dart';
import 'account_provider.dart';
import '../data/services/notification_service.dart';

const _uuid = Uuid();

String _monthYearKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';

class FixedExpenseNotifier extends StateNotifier<List<FixedExpense>> {
  final Ref ref;

  FixedExpenseNotifier(this.ref) : super([]) {
    _autoCloneForCurrentMonth();
    _refresh();
  }

  void _refresh() {
    final now = DateTime.now();
    final key = _monthYearKey(now);
    state = HiveBoxes.fixedExpenses.values
        .where((e) => e.monthYear == key)
        .toList();
  }

  /// For every unique title in the box, ensure there is an entry for the
  /// current month. If not, create a clone (unpaid) from the last available month.
  Future<void> _autoCloneForCurrentMonth() async {
    final now = DateTime.now();
    final currentKey = _monthYearKey(now);
    final all = HiveBoxes.fixedExpenses.values.toList();

    // Group by title
    final Map<String, List<FixedExpense>> byTitle = {};
    for (final e in all) {
      byTitle.putIfAbsent(e.title, () => []).add(e);
    }

    for (final entry in byTitle.entries) {
      final hasCurrentMonth =
          entry.value.any((e) => e.monthYear == currentKey);
      if (!hasCurrentMonth && entry.value.isNotEmpty) {
        // Clone from the most recent one
        entry.value.sort((a, b) => b.monthYear.compareTo(a.monthYear));
        final source = entry.value.first;
        
        if (!source.isRecurring) continue;
        if (source.recurringType == 'INSTALLMENT' && source.currentInstallment >= source.totalInstallments) continue;

        final clone = FixedExpense(
          id: _uuid.v4(),
          title: source.title,
          amount: source.amount,
          billArrivalDate: DateTime(now.year, now.month, source.billArrivalDate.day),
          dueDate: DateTime(now.year, now.month, source.dueDate.day),
          paymentDate: null,
          isPaid: false,
          accountId: null,
          monthYear: currentKey,
          isRecurring: source.isRecurring,
          recurringType: source.recurringType,
          totalInstallments: source.totalInstallments,
          currentInstallment: source.recurringType == 'INSTALLMENT' ? source.currentInstallment + 1 : 1,
        );
        await HiveBoxes.fixedExpenses.put(clone.id, clone);
      }
    }
  }

  Future<void> addExpense({
    required String title,
    required double amount,
    required DateTime billArrivalDate,
    required DateTime dueDate,
    bool isRecurring = false,
    String recurringType = 'MONTHLY',
    int totalInstallments = 1,
  }) async {
    final now = DateTime.now();
    final expense = FixedExpense(
      id: _uuid.v4(),
      title: title,
      amount: amount,
      billArrivalDate: billArrivalDate,
      dueDate: dueDate,
      paymentDate: null,
      isPaid: false,
      accountId: null,
      monthYear: _monthYearKey(now),
      isRecurring: isRecurring,
      recurringType: recurringType,
      totalInstallments: totalInstallments,
      currentInstallment: 1,
    );
    await HiveBoxes.fixedExpenses.put(expense.id, expense);
    _refresh();
  }

  Future<void> markAsPaid(String expenseId, String accountId) async {
    final expense = HiveBoxes.fixedExpenses.get(expenseId);
    if (expense == null) return;
    expense.isPaid = true;
    expense.paymentDate = DateTime.now();
    expense.accountId = accountId;
    await expense.save();

    // Deduct from account
    await ref.read(accountProvider.notifier).updateBalance(accountId, -expense.amount);
    _refresh();
  }

  Future<void> checkUpcomingPayments() async {
    final now = DateTime.now();
    final notified = <int>{};

    for (final expense in state.where((e) => !e.isPaid)) {
      final dueDate = DateTime(now.year, now.month, expense.dueDate.day);
      final diff = dueDate.difference(DateTime(now.year, now.month, now.day)).inDays;

      if ((diff == 1 || diff == 2 || diff == 0) && !notified.contains(expense.id.hashCode)) {
        notified.add(expense.id.hashCode);
        await NotificationService.showUpcomingPaymentNotification(
          id: expense.id.hashCode,
          billName: expense.title,
          amount: expense.amount,
          currency: '₺',
          daysUntilDue: diff,
        );
      }
    }
  }

  int get upcomingExpenseCount {
    final now = DateTime.now();
    return state.where((e) {
      if (e.isPaid) return false;
      final dueDate = DateTime(now.year, now.month, e.dueDate.day);
      final diff = dueDate.difference(DateTime(now.year, now.month, now.day)).inDays;
      return diff >= 0 && diff <= 2;
    }).length;
  }
}

final fixedExpenseProvider =
    StateNotifierProvider<FixedExpenseNotifier, List<FixedExpense>>(
        (ref) => FixedExpenseNotifier(ref));
