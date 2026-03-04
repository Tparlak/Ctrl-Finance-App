import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../data/hive_boxes.dart';
import 'transaction_provider.dart';

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

/// Only top-level categories (no parent)
final topLevelCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  final all = ref.watch(categoryProvider);
  return all.where((c) => c.parentCategory == null).toList();
});

/// Sub-categories of a specific parent
final subCategoriesProvider = Provider.family<List<CategoryModel>, String>((ref, parentId) {
  final all = ref.watch(categoryProvider);
  return all.where((c) => c.parentCategory == parentId).toList();
});

/// Budget status for a category (Spent / Limit)
final categoryBudgetStatusProvider = Provider.family<double, String>((ref, categoryId) {
  final transactions = ref.watch(filteredTransactionsProvider);
  final allCategories = ref.watch(categoryProvider);
  
  // Find category and its children
  final childrenIds = allCategories
      .where((c) => c.parentCategory == categoryId)
      .map((c) => c.id)
      .toList();
  
  final relevantIds = [categoryId, ...childrenIds];
  
  return transactions
      .where((t) => relevantIds.contains(t.categoryId))
      .fold(0.0, (sum, t) => sum + t.amount);
});
