import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category_model.dart';
import '../providers/category_provider.dart';

class CategoryPicker extends ConsumerStatefulWidget {
  final String type; // 'income' or 'expense'
  final Function(CategoryModel) onSelected;

  const CategoryPicker({
    required this.type,
    required this.onSelected,
    super.key,
  });

  @override
  ConsumerState<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends ConsumerState<CategoryPicker> {
  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    List<CategoryModel> categories = [];
    if (widget.type == 'income') {
      categories = ref.watch(incomeCategoryProvider);
    } else {
      categories = ref.watch(expenseCategoryProvider);
    }

    // Goup by parentCategory
    final topLevel = categories.where((c) => c.parentCategory == null).toList();
    final grouped = <String, List<CategoryModel>>{};
    
    for (var parent in topLevel) {
      grouped[parent.name] = categories.where((c) => c.parentCategory == parent.name).toList();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: topLevel.length,
      itemBuilder: (context, index) {
        final parent = topLevel[index];
        final children = grouped[parent.name] ?? [];

        if (children.isEmpty) {
          return ListTile(
            leading: Icon(
              IconData(parent.iconCodePoint, fontFamily: 'MaterialIcons'),
              color: _parseColor(parent.color),
            ),
            title: Text(parent.name, style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface)),
            onTap: () {
              Navigator.pop(context); // close sheet
              widget.onSelected(parent);
            },
          );
        }

        return ExpansionTile(
          shape: const Border(),
          leading: Icon(
            IconData(parent.iconCodePoint, fontFamily: 'MaterialIcons'),
            color: _parseColor(parent.color),
          ),
          title: Text(parent.name, style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface)),
          children: children.map((child) {
            return ListTile(
              contentPadding: const EdgeInsets.only(left: 56.0),
              leading: Icon(
                IconData(child.iconCodePoint, fontFamily: 'MaterialIcons'),
                color: Colors.grey,
                size: 20,
              ),
              title: Text(child.name, style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context); // close sheet
                widget.onSelected(child);
              },
            );
          }).toList(),
        );
      },
    );
  }
}
