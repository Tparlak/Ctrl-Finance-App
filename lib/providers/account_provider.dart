import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../data/hive_boxes.dart';

class AccountNotifier extends StateNotifier<List<Account>> {
  AccountNotifier() : super(_loadAll());

  static List<Account> _loadAll() =>
      HiveBoxes.accounts.values.toList();

  void refresh() {
    state = HiveBoxes.accounts.values.toList();
  }

  Future<void> updateBalance(String accountId, double delta) async {
    final box = HiveBoxes.accounts;
    final account = box.get(accountId);
    if (account == null) return;
    account.currentBalance += delta;
    await account.save();
    refresh();
  }

  Future<void> addAccount(String name) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final account = Account(id: id, name: name, currentBalance: 0.0);
    await HiveBoxes.accounts.put(account.id, account);
    refresh();
  }

  Future<void> deleteAccount(String accountId) async {
    await HiveBoxes.accounts.delete(accountId);
    refresh();
  }

  Future<void> renameAccount(String accountId, String newName) async {
    final account = HiveBoxes.accounts.get(accountId);
    if (account == null) return;
    account.name = newName;
    await account.save();
    refresh();
  }
}

final accountProvider =
    StateNotifierProvider<AccountNotifier, List<Account>>(
        (_) => AccountNotifier());

/// Computed: sum of all account balances
final totalBalanceProvider = Provider<double>((ref) {
  final accounts = ref.watch(accountProvider);
  return accounts.fold(0.0, (sum, a) => sum + a.currentBalance);
});
