import 'package:hive/hive.dart';
part 'car_expense.g.dart';

@HiveType(typeId: 4)
class CarExpense extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  double? kilometers;

  @HiveField(4)
  String? notes;

  @HiveField(5)
  String category;

  CarExpense({
    required this.title,
    required this.amount,
    required this.date,
    this.kilometers,
    this.notes,
    this.category = 'Bakım',
  });
}
