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
    const uuid = 'uuid_placeholder'; // handled by caller with Uuid()
    final account = Account(id: uuid, name: name, currentBalance: 0.0);
    await HiveBoxes.accounts.put(account.id, account);
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
