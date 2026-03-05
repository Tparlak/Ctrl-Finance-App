import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../providers/category_provider.dart';
import '../models/category_model.dart';
import '../widgets/glass_card.dart';
import '../data/hive_boxes.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// Map emoji to icon codepoint via a simple list widget
const _defaultIconCode = 0xe59c; // shopping cart

class CategoryManagerScreen extends ConsumerWidget {
  const CategoryManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCats = ref.watch(categoryProvider);
    final topLevel = allCats.where((c) => c.parentCategory == null).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
              child: Text(
                'KATEGORİ YÖNETİMİ',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          _SectionHeader(label: '📂 TÜM KATEGORİLER'),
          _HierarchicalCategoryList(topLevel: topLevel, type: 'expense'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _AddButton(
                label: '+ Yeni Kategori Grubu',
                type: 'expense',
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.gold,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _HierarchicalCategoryList extends ConsumerWidget {
  final List<CategoryModel> topLevel;
  final String type;
  const _HierarchicalCategoryList({required this.topLevel, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (topLevel.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Text('Henüz grup yok.',
              style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13)),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) {
            final cat = topLevel[i];
            final subCats = ref.watch(subCategoriesProvider(cat.id));
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: _CategoryIcon(codePoint: cat.iconCodePoint),
                    title: Text(cat.name,
                        style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
                    subtitle: cat.monthlyLimit != null 
                        ? Text('Limit: ${NumberFormat('#,##0', 'tr_TR').format(cat.monthlyLimit)} ₺',
                            style: GoogleFonts.poppins(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w600))
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: Theme.of(context).textTheme.bodySmall?.color, size: 20),
                          onPressed: () => _showEditSheet(context, cat, ref),
                        ),
                        Icon(Icons.expand_more_rounded, color: Theme.of(context).textTheme.bodySmall?.color),
                      ],
                    ),
                    children: [
                      ...subCats.map((sub) => _SubCategoryTile(sub: sub)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(56, 4, 16, 12),
                        child: InkWell(
                          onTap: () => _showAddSubSheet(context, cat, ref),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.add_circle_outline_rounded, color: AppColors.gold, size: 18),
                                const SizedBox(width: 8),
                                Text('Alt Kategori Ekle', 
                                  style: GoogleFonts.poppins(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: topLevel.length,
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, CategoryModel cat, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategorySheet(
        title: 'Grubu Düzenle',
        existingCategory: cat,
        type: cat.type,
      ),
    ).then((_) => ref.invalidate(categoryProvider));
  }

  void _showAddSubSheet(BuildContext context, CategoryModel parent, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategorySheet(
        title: 'Alt Kategori Ekle',
        parentId: parent.id,
        type: parent.type,
      ),
    ).then((_) => ref.invalidate(categoryProvider));
  }
}

class _SubCategoryTile extends ConsumerWidget {
  final CategoryModel sub;
  const _SubCategoryTile({required this.sub});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(sub.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.red.withOpacity( 0.1),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
      ),
      onDismissed: (_) {
        HiveBoxes.categories.delete(sub.id);
        ref.invalidate(categoryProvider);
      },
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 64, right: 16),
        leading: Icon(IconData(sub.iconCodePoint, fontFamily: 'MaterialIcons'), 
          color: Theme.of(context).textTheme.bodySmall?.color, size: 18),
        title: Text(sub.name, style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 13)),
        subtitle: sub.monthlyLimit != null 
            ? Text('Limit: ${NumberFormat('#,##0', 'tr_TR').format(sub.monthlyLimit)} ₺',
                style: GoogleFonts.poppins(color: AppColors.gold, fontSize: 10))
            : null,
        trailing: IconButton(
          icon: Icon(Icons.edit_outlined, color: Theme.of(context).textTheme.bodySmall?.color, size: 16),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _CategorySheet(
                title: 'Alt Kategoriyi Düzenle',
                existingCategory: sub,
                type: sub.type,
              ),
            ).then((_) => ref.invalidate(categoryProvider));
          },
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final int codePoint;
  const _CategoryIcon({required this.codePoint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity( 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          IconData(codePoint, fontFamily: 'MaterialIcons'),
          color: AppColors.gold,
          size: 20,
        ),
      ),
    );
  }
}

class _AddButton extends ConsumerWidget {
  final String label;
  final String type;
  const _AddButton({required this.label, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _CategorySheet(
            title: label,
            type: type,
          ),
        ).then((_) => ref.invalidate(categoryProvider));
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: AppColors.gold.withOpacity( 0.4), width: 1.5),
        backgroundColor: AppColors.gold.withOpacity( 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(color: AppColors.gold, fontWeight: FontWeight.w600)),
    );
  }
}

class _CategorySheet extends StatefulWidget {
  final String title;
  final CategoryModel? existingCategory;
  final String? parentId;
  final String type;

  const _CategorySheet({
    required this.title,
    this.existingCategory,
    this.parentId,
    required this.type,
  });

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _limitCtrl;
  late int _selectedIconCode;
  String? _selectedParentId;

  final List<Map<String, dynamic>> _icons = [
    {'label': 'Market', 'code': 0xe59c},
    {'label': 'Yemek', 'code': 0xe57a},
    {'label': 'Yakıt', 'code': 0xe3a9},
    {'label': 'Fatura', 'code': 0xe70e},
    {'label': 'Sağlık', 'code': 0xe3f0},
    {'label': 'Ulaşım', 'code': 0xe530},
    {'label': 'Maaş', 'code': 0xe8f9},
    {'label': 'Kira', 'code': 0xe88f},
    {'label': 'Eğitim', 'code': 0xe80c},
    {'label': 'Eğlence', 'code': 0xe415},
    {'label': 'Hediye', 'code': 0xe7ee},
    {'label': 'Spor', 'code': 0xe52f},
    {'label': 'Yatırım', 'code': 0xe6de},
    {'label': 'Diğer', 'code': 0xe5d3},
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existingCategory?.name);
    _limitCtrl = TextEditingController(
      text: widget.existingCategory?.monthlyLimit?.toString() ?? '',
    );
    _selectedIconCode = widget.existingCategory?.iconCodePoint ?? _defaultIconCode;
    _selectedParentId = widget.existingCategory?.parentCategory ?? widget.parentId;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final allCats = ref.watch(categoryProvider);
      final potentialParents = allCats
          .where((c) => c.type == widget.type && c.parentCategory == null && c.id != widget.existingCategory?.id)
          .toList();

      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gold.withOpacity( 0.3)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: GoogleFonts.poppins(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameCtrl,
                  autofocus: widget.existingCategory == null,
                  style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                  decoration: _inputDecoration('Kategori Adı', context),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedParentId,
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                  decoration: _inputDecoration('Üst Kategori (Opsiyonel)', context),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Yok (Ana Grup)')),
                    ...potentialParents.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                  ],
                  onChanged: (val) => setState(() => _selectedParentId = val),
                ),
                const SizedBox(height: 16),
                if (widget.type == 'expense')
                  TextField(
                    controller: _limitCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                    decoration: _inputDecoration('Aylık Bütçe Limiti (₺)', context),
                  ),
                const SizedBox(height: 16),
                Text('İkon Seç', style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _icons.map((item) {
                    final selected = _selectedIconCode == item['code'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIconCode = item['code'] as int),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.gold.withOpacity( 0.2) : Theme.of(context).inputDecorationTheme.fillColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? AppColors.gold : (Theme.of(context).dividerTheme.color ?? Colors.transparent),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Icon(
                          IconData(item['code'] as int, fontFamily: 'MaterialIcons'),
                          color: selected ? AppColors.gold : Theme.of(context).textTheme.bodySmall?.color,
                          size: 20,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = _nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      
                      final limit = double.tryParse(_limitCtrl.text.replaceAll(',', '.'));
                      
                      if (widget.existingCategory != null) {
                        widget.existingCategory!.name = name;
                        widget.existingCategory!.iconCodePoint = _selectedIconCode;
                        widget.existingCategory!.parentCategory = _selectedParentId;
                        widget.existingCategory!.monthlyLimit = limit;
                        await widget.existingCategory!.save();
                      } else {
                        final cat = CategoryModel(
                          id: _uuid.v4(),
                          name: name,
                          iconCodePoint: _selectedIconCode,
                          type: widget.type,
                          parentCategory: _selectedParentId,
                          monthlyLimit: limit,
                        );
                        await HiveBoxes.categories.put(cat.id, cat);
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('KAYDET', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  InputDecoration _inputDecoration(String label, BuildContext context) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gold),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}

