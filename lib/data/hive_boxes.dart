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
    final bool isSeeded = settings.get('isSeeded', defaultValue: false) as bool;
    if (isSeeded) return;

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
        {'name': 'Fatura', 'icon': Icons.receipt_long.codePoint, 'color': '#FF6584', 'parent': null},
        {'name': 'Elektrik', 'icon': Icons.bolt.codePoint, 'color': null, 'parent': 'Fatura'},
        {'name': 'Su', 'icon': Icons.water_drop.codePoint, 'color': null, 'parent': 'Fatura'},
        {'name': 'Doğalgaz', 'icon': Icons.local_fire_department.codePoint, 'color': null, 'parent': 'Fatura'},
        {'name': 'İnternet', 'icon': Icons.wifi.codePoint, 'color': null, 'parent': 'Fatura'},
        {'name': 'Telefon', 'icon': Icons.phone_android.codePoint, 'color': null, 'parent': 'Fatura'},

        {'name': 'Ulaşım', 'icon': Icons.directions_car.codePoint, 'color': '#43E97B', 'parent': null},
        {'name': 'Akaryakıt', 'icon': Icons.local_gas_station.codePoint, 'color': null, 'parent': 'Ulaşım'},
        {'name': 'Otobüs/Metro', 'icon': Icons.directions_bus.codePoint, 'color': null, 'parent': 'Ulaşım'},
        {'name': 'Taksi', 'icon': Icons.local_taxi.codePoint, 'color': null, 'parent': 'Ulaşım'},

        {'name': 'Market', 'icon': Icons.shopping_cart.codePoint, 'color': '#FA8231', 'parent': null},
        {'name': 'Gıda', 'icon': Icons.restaurant.codePoint, 'color': null, 'parent': 'Market'},
        {'name': 'Temizlik', 'icon': Icons.cleaning_services.codePoint, 'color': null, 'parent': 'Market'},
        {'name': 'Kişisel Bakım', 'icon': Icons.face.codePoint, 'color': null, 'parent': 'Market'},
      ];
      for (final s in expenseSeeds) {
        final cat = CategoryModel(
          id: uuid.v4(),
          name: s['name'] as String,
          iconCodePoint: s['icon'] as int,
          type: 'expense',
          color: s['color'] as String?,
          parentCategory: s['parent'] as String?,
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
    
    await settings.put('isSeeded', true);
  }
}
