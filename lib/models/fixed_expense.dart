import 'package:hive/hive.dart';

part 'fixed_expense.g.dart';

@HiveType(typeId: 3)
class FixedExpense extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime billArrivalDate;

  @HiveField(4)
  DateTime dueDate;

  @HiveField(5)
  DateTime? paymentDate;

  @HiveField(6)
  bool isPaid;

  @HiveField(7)
  String? accountId; // account used to pay

  /// Format: 'yyyy-MM'  e.g. '2026-02'
  @HiveField(8)
  String monthYear;

  @HiveField(9, defaultValue: false)
  bool isRecurring;

  /// e.g. 'MONTHLY', 'INSTALLMENT'
  @HiveField(10, defaultValue: 'MONTHLY')
  String recurringType;

  @HiveField(11, defaultValue: 1)
  int totalInstallments;

  @HiveField(12, defaultValue: 1)
  int currentInstallment;

  FixedExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.billArrivalDate,
    required this.dueDate,
    this.paymentDate,
    required this.isPaid,
    this.accountId,
    required this.monthYear,
    this.isRecurring = false,
    this.recurringType = 'MONTHLY',
    this.totalInstallments = 1,
    this.currentInstallment = 1,
  });
}
