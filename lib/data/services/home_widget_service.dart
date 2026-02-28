import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../models/transaction_model.dart';
import '../data/hive_boxes.dart';

class HomeWidgetService {
  static const String _groupId = 'com.vip.vip_finance'; // same as namespace
  static const String _androidWidgetName = 'CtrlWidgetProvider';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_groupId);
  }

  static Future<void> syncWidgetData() async {
    try {
      // 1. Calculate Balance Map
      final iterAccounts = HiveBoxes.accounts.values;
      final balances = <String, double>{};
      for (final a in iterAccounts) {
        final c = a.currency;
        balances[c] = (balances[c] ?? 0) + a.balance;
      }
      
      String balanceStr = '₺0,00';
      if (balances.isNotEmpty) {
        if (balances.length == 1) {
          balanceStr = '${NumberFormat('#,##0.00', 'tr_TR').format(balances.values.first)} ${balances.keys.first}';
        } else {
          balanceStr = balances.entries.map((e) => '${NumberFormat('#,##0.00', 'tr_TR').format(e.value)} ${e.key}').join(' | ');
        }
      }

      // 2. Calculate Total Income & Expense (All-Time or Current Month)
      // Let's use All-Time since Dashboard summary uses all-time.
      final txList = HiveBoxes.transactions.values;
      double income = 0;
      double expense = 0;
      
      for (final tx in txList) {
        if (tx.type == 'income') income += tx.amount;
        if (tx.type == 'expense') expense += tx.amount;
      }

      final incStr = 'Gelir: ${NumberFormat('#,##0.00', 'tr_TR').format(income)} ₺';
      final expStr = 'Gider: ${NumberFormat('#,##0.00', 'tr_TR').format(expense)} ₺';

      // 3. Save to Widget Preferences
      await HomeWidget.saveWidgetData('balance', balanceStr);
      await HomeWidget.saveWidgetData('income', incStr);
      await HomeWidget.saveWidgetData('expense', expStr);

      // 4. Update the Widget
      await HomeWidget.updateWidget(androidName: _androidWidgetName);
    } catch (e) {
      // Ignore errors if widget synchronization fails (e.g., unsupported platform)
    }
  }
}
