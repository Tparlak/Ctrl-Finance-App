import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../data/hive_boxes.dart';

final categoryProvider = Provider<List<CategoryModel>>((ref) {
  return HiveBoxes.categories.values.toList();
});
