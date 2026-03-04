import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/account.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/fixed_expense.dart';
import '../models/car_expense.dart';
import '../models/note_model.dart';
import '../models/reminder_model.dart';
import 'models/receipt_item.dart';

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
    Hive.registerAdapter(CarExpenseAdapter());
    Hive.registerAdapter(NoteModelAdapter());
    Hive.registerAdapter(ReminderModelAdapter());
    Hive.registerAdapter(ReceiptItemAdapter());

    await Hive.openBox<Account>(_accountsBoxName);
    await Hive.openBox<CategoryModel>(_categoriesBoxName);
    await Hive.openBox<TransactionModel>(_transactionsBoxName);
    await Hive.openBox<FixedExpense>(_fixedExpensesBoxName);
    await Hive.openBox<CarExpense>('car_expenses');
    await Hive.openBox<NoteModel>('notes');
    await Hive.openBox<ReminderModel>('reminders');
    await Hive.openBox(_settingsBoxName);

    await _seedIfEmpty();
  }

  static Future<void> _seedIfEmpty() async {
    const uuid = Uuid();
    
    // Version 5 Seed & Migration Check
    final bool isSeededV5 = settings.get('isSeededV5', defaultValue: false) as bool;
    if (isSeededV5) return;

    // 1. Map old categories to new ones for migration
    final Map<String, String> migrationMapping = {
      'Elektrik': 'ELEKTRİK',
      'Su': 'SU',
      'Doğalgaz': 'ISINMA',
      'İnternet': 'İNTERNET',
      'Telefon': 'TELEFON',
      'Aidat': 'AİDAT',
      'Akaryakıt': 'YAKIT',
      'Otobüs/Metro': 'OTOBÜS ULAŞIM',
      'Taksi': 'OTOBÜS ULAŞIM',
      'Uçak': 'SEYAHAT',
      'Araç Bakım': 'ARAÇ GİDER',
      'Gıda': 'EV MUTFAK',
      'Temizlik': 'EV MUTFAK',
      'Kişisel Bakım': 'KİŞİSEL BAKIM',
      'Manav': 'EV MUTFAK',
      'Mobilya': 'EV & TADİLAT',
      'Elektronik': 'EV & TADİLAT',
      'Tadilat': 'EV & TADİLAT',
      'Kıyafet': 'GİYİM',
      'Ayakkabı': 'GİYİM',
      'Aksesuar': 'GİYİM',
      'İlaç': 'SAĞLIK / SİGORTA',
      'Hastane': 'SAĞLIK / SİGORTA',
      'Sinema/Tiyatro': 'EĞLENCE',
      'Abonelikler': 'EĞLENCE',
      'Maaş': 'MAAŞ',
      'Ek Gelir': 'SATIŞ',
      'Kira Geliri': 'SATIŞ',
      'Nakit İade': 'SATIŞ',
      'Yatırım Getirisi': 'SATIŞ',
      'Bayram/Harçlık': 'SATIŞ',
      'Borç Ödemesi Alındı': 'SATIŞ',
      'Diğer Gelir': 'SATIŞ',
    };

    // 2. Define New Seed Data (IDs are fixed for seed consistency)
    final List<CategoryModel> newSeeds = [
      // ── GIDA ──────────────────────────────────────────────
      CategoryModel(id: 'cat_gida', name: 'GIDA', iconCodePoint: 0xea61, parentCategory: null, type: 'expense'),
      CategoryModel(id: 'cat_dis_harcama', name: 'DIŞ HARCAMA', iconCodePoint: 0xe552, parentCategory: 'cat_gida', type: 'expense'),
      CategoryModel(id: 'cat_ev_mutfak', name: 'EV MUTFAK', iconCodePoint: 0xe944, parentCategory: 'cat_gida', type: 'expense'),
      // ── SİGARA ────────────────────────────────────────────
      CategoryModel(id: 'cat_sigara', name: 'SİGARA', iconCodePoint: 0xeb28, parentCategory: null, type: 'expense'),
      // ── ULAŞIM GİDERİ ─────────────────────────────────────
      CategoryModel(id: 'cat_ulasim', name: 'ULAŞIM GİDERİ', iconCodePoint: 0xeb12, parentCategory: null, type: 'expense'),
      CategoryModel(id: 'cat_arac_gider', name: 'ARAÇ GİDER', iconCodePoint: 0xe869, parentCategory: 'cat_ulasim', type: 'expense'),
      CategoryModel(id: 'cat_otobus', name: 'OTOBÜS ULAŞIM', iconCodePoint: 0xe530, parentCategory: 'cat_ulasim', type: 'expense'),
      CategoryModel(id: 'cat_yakit', name: 'YAKIT', iconCodePoint: 0xe531, parentCategory: 'cat_ulasim', type: 'expense'),
      // ── FATURA ────────────────────────────────────────────
      CategoryModel(id: 'cat_fatura', name: 'FATURA', iconCodePoint: 0xef6e, parentCategory: null, type: 'expense'),
      CategoryModel(id: 'cat_elektrik', name: 'ELEKTRİK', iconCodePoint: 0xea0b, parentCategory: 'cat_fatura', type: 'expense'),
      CategoryModel(id: 'cat_isinma', name: 'ISINMA', iconCodePoint: 0xf05a, parentCategory: 'cat_fatura', type: 'expense'),
      CategoryModel(id: 'cat_internet', name: 'İNTERNET', iconCodePoint: 0xe894, parentCategory: 'cat_fatura', type: 'expense'),
      CategoryModel(id: 'cat_su', name: 'SU', iconCodePoint: 0xe798, parentCategory: 'cat_fatura', type: 'expense'),
      CategoryModel(id: 'cat_telefon', name: 'TELEFON', iconCodePoint: 0xe32c, parentCategory: 'cat_fatura', type: 'expense'),
      CategoryModel(id: 'cat_tv', name: 'TV', iconCodePoint: 0xe333, parentCategory: 'cat_fatura', type: 'expense'),
      // ── STANDALONE EXPENSE ────────────────────────────────
      CategoryModel(id: 'cat_aidat', name: 'AİDAT', iconCodePoint: 0xe8b0, parentCategory: null, type: 'expense'),
      CategoryModel(id: 'cat_bagis', name: 'BAĞIŞ', iconCodePoint: 0xea70, parentCategory: null, type: 'expense'),
      CategoryModel(id: 'cat_cocuk', name: 'ÇOCUK', iconCodePoint: 0xeb0f, parentCategory: null, type: 'expense'),
      CategoryModel(id: 'cat_egitim', name: 'EĞİTİM / KİTAP', iconCodePoint: 0xe80c, parentCategory: null, type: 'expense'),
      CategoryModel(id: 'cat_eglence', name: 'EĞLENCE', iconCodePoint: 0xea4f, parentCategory: null, type: 'expense'),
      CategoryModel(id: 'cat_ev_tadiat', name: 'EV & TADİLAT', iconCodePoint: 0xf10e, parentCategory: null, type: 'expense'),
      CategoryModel(id: 'cat_evcil_hayvan', name: 'EVCİL HAYVAN', iconCodePoint: 0xe91d, parentCategory: null, type: 'expense'),
      CategoryModel(id: 'cat_giyim', name: 'GİYİM', iconCodePoint: 0xf17e, parentCategory: null, type: 'expense'),
      CategoryModel(id: 'cat_kira', name: 'KİRA', iconCodePoint: 0xe88a, parentCategory: null, type: 'expense'),
      CategoryModel(id: 'cat_kisisel_bakim', name: 'KİŞİSEL BAKIM', iconCodePoint: 0xeb2c, parentCategory: null, type: 'expense'),
      CategoryModel(id: 'cat_kredi_karti', name: 'KREDİ KARTI', iconCodePoint: 0xe870, parentCategory: null, type: 'expense'),
      CategoryModel(id: 'cat_saglik', name: 'SAĞLIK / SİGORTA', iconCodePoint: 0xf0c7, parentCategory: null, type: 'expense'),
      CategoryModel(id: 'cat_seyahat', name: 'SEYAHAT', iconCodePoint: 0xe539, parentCategory: null, type: 'expense'),
      CategoryModel(id: 'cat_market', name: 'YEMEK / MARKET', iconCodePoint: 0xe8cc, parentCategory: null, type: 'expense'),
      // ── INCOME ────────────────────────────────────────────
      CategoryModel(id: 'cat_maas', name: 'MAAŞ', iconCodePoint: 0xe84f, parentCategory: null, type: 'income'),
      CategoryModel(id: 'cat_satis', name: 'SATIŞ', iconCodePoint: 0xf051, parentCategory: null, type: 'income'),
    ];

    // 3. Migration Action
    if (categories.isNotEmpty) {
      // a. Capture old ID -> Name mapping
      final Map<String, String> oldIdToName = {
        for (var c in categories.values) c.id: c.name,
      };

      // b. Insert New Categories
      for (final cat in newSeeds) {
        await categories.put(cat.id, cat);
      }

      // c. Update Transactions
      for (final tx in transactions.values) {
        final oldName = oldIdToName[tx.categoryId];
        if (oldName != null) {
          final newName = migrationMapping[oldName];
          if (newName != null) {
            final newCatId = newSeeds.firstWhere((s) => s.name == newName).id;
            tx.categoryId = newCatId;
            await tx.save();
          }
        }
      }

      // d. Clear old categories (Keep only the new ones)
      final newIds = newSeeds.map((s) => s.id).toSet();
      final keysToDelete = categories.keys.where((k) => !newIds.contains(k)).toList();
      await categories.deleteAll(keysToDelete);
    } else {
      // Just seed if empty
      for (final cat in newSeeds) {
        await categories.put(cat.id, cat);
      }
    }

    // 4. Accounts Initial Seed (If first time ever)
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
    }

    await settings.put('isSeededV5', true);
  }
}
