import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../data/hive_boxes.dart';

/// All categories
final categoryProvider = Provider<List<CategoryModel>>((ref) {
  return HiveBoxes.categories.values.toList();
});

/// Only expense categories
final expenseCategoryProvider = Provider<List<CategoryModel>>((ref) {
  return HiveBoxes.categories.values
      .where((c) => c.type == 'expense')
      .toList();
});

/// Only income categories
final incomeCategoryProvider = Provider<List<CategoryModel>>((ref) {
  return HiveBoxes.categories.values
      .where((c) => c.type == 'income')
      .toList();
});
