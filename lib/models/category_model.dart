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

  /// Optional parent category ID for nested structures
  @HiveField(4)
  String? parentCategory;

  /// Optional hex color code (e.g. '#FF6584')
  @HiveField(5)
  String? color;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    this.type = 'expense',
    this.parentCategory,
    this.color,
  });
}
