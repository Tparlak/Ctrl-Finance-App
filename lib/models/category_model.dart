import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 1)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int iconCodePoint;

  /// 'income' or 'expense'
  @HiveField(3, defaultValue: 'expense')
  String type;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    this.type = 'expense',
  });
}
