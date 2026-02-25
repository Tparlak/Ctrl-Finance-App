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

  Account({
    required this.id,
    required this.name,
    required this.currentBalance,
  });
}
