import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/account.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/fixed_expense.dart';

const String _accountsBoxName = 'accounts';
const String _categoriesBoxName = 'categories';
const String _transactionsBoxName = 'transactions';
const String _fixedExpensesBoxName = 'fixed_expenses';
const String _settingsBoxName = 'settings';

class HiveBoxes {
  static Box<Account> get accounts => Hive.box<Account>(_accountsBoxName);
  static Box<CategoryModel> get categories =>
      Hive.box<CategoryModel>(_categoriesBoxName);
  static Box<TransactionModel> get transactions =>
      Hive.box<TransactionModel>(_transactionsBoxName);
  static Box<FixedExpense> get fixedExpenses =>
      Hive.box<FixedExpense>(_fixedExpensesBoxName);
  static Box get settings => Hive.box(_settingsBoxName);

  /// Call once at app startup AFTER Hive.initFlutter()
  static Future<void> openAll() async {
    Hive.registerAdapter(AccountAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(TransactionModelAdapter());
    Hive.registerAdapter(FixedExpenseAdapter());

    await Hive.openBox<Account>(_accountsBoxName);
    await Hive.openBox<CategoryModel>(_categoriesBoxName);
    await Hive.openBox<TransactionModel>(_transactionsBoxName);
    await Hive.openBox<FixedExpense>(_fixedExpensesBoxName);
    await Hive.openBox(_settingsBoxName);

    await _seedIfEmpty();
  }

  static Future<void> _seedIfEmpty() async {
    const uuid = Uuid();

    // Seed accounts
    if (accounts.isEmpty) {
      final initialAccounts = ['Kuveyt Türk', 'Akbank 1', 'Enpara', 'Vakıfbank', 'Nakit Kasa'];
      for (final name in initialAccounts) {
        final account = Account(
          id: uuid.v4(),
          name: name,
          currentBalance: 0.0,
        );
        await accounts.put(account.id, account);
      }
    } else {
      // Migrate existing old abbreviation names to full names
      final migrationMap = {
        'kvyt': 'Kuveyt Türk',
        'ak1': 'Akbank 1',
        'ENP': 'Enpara',
        'VK': 'Vakıfbank',
        'CSH': 'Nakit Kasa',
      };
      
      for (final account in accounts.values) {
        if (migrationMap.containsKey(account.name)) {
          account.name = migrationMap[account.name]!;
          await account.save();
        }
      }
    }

    // Migrate existing categories: ensure type field is set
    for (final cat in categories.values) {
      if (cat.type != 'income' && cat.type != 'expense') {
        cat.type = 'expense';
        await cat.save();
      }
    }

    // Seed expense categories
    final hasExpenseCats =
        categories.values.any((c) => c.type == 'expense');
    if (!hasExpenseCats) {
      final expenseSeeds = [
        {'name': 'Market',  'icon': Icons.shopping_cart.codePoint},
        {'name': 'Sigara',  'icon': Icons.smoking_rooms.codePoint},
        {'name': 'Yakıt',   'icon': Icons.local_gas_station.codePoint},
        {'name': 'Fatura',  'icon': Icons.receipt_long.codePoint},
        {'name': 'Yemek',   'icon': Icons.restaurant.codePoint},
        {'name': 'Sağlık',  'icon': Icons.local_hospital.codePoint},
        {'name': 'Ulaşım',  'icon': Icons.directions_bus.codePoint},
        {'name': 'Diğer',   'icon': Icons.more_horiz.codePoint},
      ];
      for (final s in expenseSeeds) {
        final cat = CategoryModel(
          id: uuid.v4(),
          name: s['name'] as String,
          iconCodePoint: s['icon'] as int,
          type: 'expense',
        );
        await categories.put(cat.id, cat);
      }
    }

    // Seed income categories
    final hasIncomeCats =
        categories.values.any((c) => c.type == 'income');
    if (!hasIncomeCats) {
      final incomeSeeds = [
        {'name': 'Maaş',        'icon': Icons.work.codePoint},
        {'name': 'Yol Parası',  'icon': Icons.directions_bus.codePoint},
        {'name': 'Bayram',      'icon': Icons.celebration.codePoint},
        {'name': 'Kampanya',    'icon': Icons.redeem.codePoint},
        {'name': 'Ekleme',      'icon': Icons.add_circle_outline.codePoint},
      ];
      for (final s in incomeSeeds) {
        final cat = CategoryModel(
          id: uuid.v4(),
          name: s['name'] as String,
          iconCodePoint: s['icon'] as int,
          type: 'income',
        );
        await categories.put(cat.id, cat);
      }
    }
  }
}
