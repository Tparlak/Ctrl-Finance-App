import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/car_expense.dart';

class CarExpenseNotifier extends Notifier<List<CarExpense>> {
  late Box<CarExpense> _box;

  @override
  List<CarExpense> build() => [];

  Future<void> init() async {
    _box = Hive.box<CarExpense>('car_expenses');
    state = _sorted(_box.values.toList());
  }

  List<CarExpense> _sorted(List<CarExpense> list) =>
      list..sort((a, b) => b.date.compareTo(a.date));

  double get totalSpent => state.fold(0, (s, e) => s + e.amount);

  Future<void> add(CarExpense expense) async {
    await _box.add(expense);
    state = _sorted(_box.values.toList());
  }

  Future<void> delete(CarExpense expense) async {
    await expense.delete();
    state = _sorted(_box.values.toList());
  }
}

final carExpenseProvider = NotifierProvider<CarExpenseNotifier, List<CarExpense>>(CarExpenseNotifier.new);
