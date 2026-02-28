import 'package:hive/hive.dart';

part 'account.g.dart';

@HiveType(typeId: 0)
class Account extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double currentBalance;

  @HiveField(3, defaultValue: 'BANK')
  String type;

  @HiveField(4, defaultValue: true)
  bool isIncludedInTotal;

  @HiveField(5, defaultValue: 0.0)
  double creditLimit;

  @HiveField(6, defaultValue: '₺')
  String currency;

  Account({
    required this.id,
    required this.name,
    required this.currentBalance,
    this.type = 'BANK',
    this.isIncludedInTotal = true,
    this.creditLimit = 0.0,
    this.currency = '₺',
  });
}
