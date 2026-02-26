import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../providers/category_provider.dart';
import '../models/category_model.dart';
import '../widgets/glass_card.dart';
import '../data/hive_boxes.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// Quick emoji icon set for categories
const _emojiOptions = [
  '🛒', '🚗', '🍕', '💊', '💡', '🏠', '✈️', '🎮', '👗', '📱',
  '💰', '🎓', '💼', '🎁', '🏥', '🚌', '⛽', '🚬', '📈', '💳',
  '🎯', '🎵', '🌟', '🏋️', '🍺', '☕', '🌿', '🐾', '🔧', '📦',
];

// Map emoji to icon codepoint via a simple list widget
const _defaultIconCode = 0xe59c; // shopping cart

class CategoryManagerScreen extends ConsumerWidget {
  const CategoryManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCats = ref.watch(categoryProvider);
    final income = allCats.where((c) => c.type == 'income').toList();
    final expense = allCats.where((c) => c.type == 'expense').toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
              child: Text(
                'KATEGORİLER',
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          _SectionHeader(label: '📈 GELİR KATEGORİLERİ'),
          _CategoryList(cats: income, ref: ref),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _AddButton(
                label: '+ Gelir Kategorisi Ekle',
                type: 'income',
              ),
            ),
          ),
          _SectionHeader(label: '💸 GİDER KATEGORİLERİ'),
          _CategoryList(cats: expense, ref: ref),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _AddButton(
                label: '+ Gider Kategorisi Ekle',
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

class _CategoryList extends StatelessWidget {
  final List<CategoryModel> cats;
  final WidgetRef ref;
  const _CategoryList({required this.cats, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (cats.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Text('Henüz kategori yok.',
              style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => Dismissible(
            key: Key(cats[i].id),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
            ),
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text('Kategoriyi Sil?',
                      style: GoogleFonts.poppins(color: AppColors.textPrimary)),
                  content: Text('"${cats[i].name}" silinecek.',
                      style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('VAZGEÇ', style: GoogleFonts.poppins(color: AppColors.textSecondary))),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
                        child: Text('SİL', style: GoogleFonts.poppins(fontWeight: FontWeight.w700))),
                  ],
                ),
              );
            },
            onDismissed: (_) {
              HiveBoxes.categories.delete(cats[i].id);
              ref.invalidate(categoryProvider);
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          IconData(cats[i].iconCodePoint, fontFamily: 'MaterialIcons'),
                          color: AppColors.gold,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(cats[i].name,
                          style: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                      onPressed: () => _showEditSheet(context, cats[i], ref),
                    ),
                  ],
                ),
              ),
            ),
          ),
          childCount: cats.length,
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, CategoryModel cat, WidgetRef ref) {
    final ctrl = TextEditingController(text: cat.name);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategorySheet(
        title: 'Kategoriyi Düzenle',
        nameCtrl: ctrl,
        initialIconCode: cat.iconCodePoint,
        onSave: (newName, iconCode) async {
          cat.name = newName;
          cat.iconCodePoint = iconCode;
          await cat.save();
          ref.invalidate(categoryProvider);
        },
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
      onPressed: () => _showAddSheet(context, ref),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.5), width: 1.5),
        backgroundColor: AppColors.gold.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(color: AppColors.gold, fontWeight: FontWeight.w600)),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategorySheet(
        title: type == 'income' ? 'Gelir Kategorisi Ekle' : 'Gider Kategorisi Ekle',
        nameCtrl: ctrl,
        initialIconCode: _defaultIconCode,
        onSave: (name, iconCode) async {
          final cat = CategoryModel(
            id: _uuid.v4(),
            name: name,
            iconCodePoint: iconCode,
            type: type,
          );
          await HiveBoxes.categories.put(cat.id, cat);
          ref.invalidate(categoryProvider);
        },
      ),
    );
  }
}

class _CategorySheet extends StatefulWidget {
  final String title;
  final TextEditingController nameCtrl;
  final int initialIconCode;
  final Future<void> Function(String name, int iconCode) onSave;

  const _CategorySheet({
    required this.title,
    required this.nameCtrl,
    required this.initialIconCode,
    required this.onSave,
  });

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  late int _selectedIconCode;

  // Material icon codes for common categories
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
    {'label': 'Sigara', 'code': 0xe6f1},
    {'label': 'Eğlence', 'code': 0xe415},
    {'label': 'Hediye', 'code': 0xe7ee},
    {'label': 'Spor', 'code': 0xe52f},
    {'label': 'Giyim', 'code': 0xe900},
    {'label': 'Teknoloji', 'code': 0xe325},
    {'label': 'Yatırım', 'code': 0xe6de},
    {'label': 'Diğer', 'code': 0xe5d3},
    {'label': 'Kilo', 'code': 0xe63e},
  ];

  @override
  void initState() {
    super.initState();
    _selectedIconCode = widget.initialIconCode;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: GoogleFonts.poppins(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: widget.nameCtrl,
              autofocus: true,
              style: GoogleFonts.poppins(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Kategori Adı',
                labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.gold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('İkon Seç', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _icons.map((item) {
                final selected = _selectedIconCode == item['code'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedIconCode = item['code'] as int),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.gold.withValues(alpha: 0.2) : AppColors.glassBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppColors.gold : AppColors.glassBorder,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Icon(
                      IconData(item['code'] as int, fontFamily: 'MaterialIcons'),
                      color: selected ? AppColors.gold : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final name = widget.nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  await widget.onSave(name, _selectedIconCode);
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
    );
  }
}
