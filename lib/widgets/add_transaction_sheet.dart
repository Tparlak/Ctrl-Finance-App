import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/glass_card.dart';
import 'package:image_picker/image_picker.dart';
import '../data/services/ocr_service.dart';
import '../widgets/category_picker.dart';
import '../data/models/receipt_item.dart';
import '../presentation/widgets/ocr_review_sheet.dart';
import '../widgets/bounce_tap.dart';

void showAddTransactionSheet(BuildContext context, {int initialTab = 1}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddTransactionSheet(initialTab: initialTab),
  );
}

class AddTransactionSheet extends ConsumerStatefulWidget {
  final dynamic existingTransaction;
  final int initialTab; // 0=income, 1=expense, 2=transfer
  const AddTransactionSheet({super.key, this.existingTransaction, this.initialTab = 1});

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _fromAccountId;
  String? _toAccountId;
  String? _selectedCategoryId;

  String? _receiptImagePath;
  bool _isScanning = false;

  // 0=income, 1=expense, 2=transfer
  int get _tab => _tabController.index;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTransaction;
    if (existing != null) {
      // Pre-fill for edit mode
      _amountController.text = existing.amount.toString();
      _descController.text = existing.description;
      _selectedDate = existing.date;
      _fromAccountId = existing.fromAccountId;
      _toAccountId = existing.toAccountId;
      _selectedCategoryId = existing.categoryId;
      _receiptItems = existing.receiptItems ?? [];
      _receiptImagePath = existing.receiptImagePath;
    }
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _tabController.addListener(() => setState(() {
      _selectedCategoryId = null;
    }));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _descController.dispose();
    OcrService.dispose();
    super.dispose();
  }

  List<ReceiptItem> _receiptItems = [];

  Future<void> _showScanOptions() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(2))),
            Text('Fiş Ekle', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '💡 İpucu: Fişi düz bir zemine koyun ve yazıları net çıkacak şekilde çekin.',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange.shade300, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Text('📸', style: TextStyle(fontSize: 24)),
              title: Text('Kameradan Çek', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Text('🖼️', style: TextStyle(fontSize: 24)),
              title: Text('Galeriden Seç', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null) return;
    final photo = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (photo == null) return;

    setState(() => _isScanning = true);
    try {
      final parsed = await OcrService.scanReceipt(photo.path);

      // Store the raw text for debug view before we do any early returns
      // (Handled internally by OcrService._lastRawText)

      // ── Auto-select category ───────────────────────────────────────────────
      String? autoCategoryId;
      final categories = _tab == 0
          ? ref.read(incomeCategoryProvider)
          : ref.read(expenseCategoryProvider);
          
      if (parsed.isFuel) {
        final match = categories.where((c) => c.name.toUpperCase().contains('YAKIT')).firstOrNull;
        if (match != null) autoCategoryId = match.id;
      } else if (parsed.isMarket) {
        final match = categories.where((c) => c.name.toUpperCase().contains('MARKET')).firstOrNull;
        if (match != null) autoCategoryId = match.id;
      }

      // ── Auto-select account ────────────────────────────────────────────────
      String? autoAccountId;
      if (parsed.accountHint != null) {
        final accounts = ref.read(accountProvider);
        final match = accounts.where((a) =>
          a.name.toUpperCase().contains(parsed.accountHint!.toUpperCase())).firstOrNull;
        if (match != null) autoAccountId = match.id;
      }

      if (mounted) setState(() => _isScanning = false);

      // ── Show Review Sheet before populating ──────────────────────────────
      if (!mounted) return;
      final corrected = await OcrReviewSheet.show(context, parsed);
      
      // User cancelled the review sheet
      if (corrected == null) return;

      // ── Single transaction fill (using corrected data) ─────────────────────
      setState(() {
        _receiptImagePath = photo.path;
        _receiptItems = corrected.items;
        
        if (corrected.total != null) {
          _amountController.text = corrected.total!.toStringAsFixed(2).replaceAll('.', ',');
        }
        
        if (_descController.text.isEmpty && corrected.merchantName != null) {
           _descController.text = corrected.merchantName!;
        }
        
        if (corrected.date != null) _selectedDate = corrected.date!;
        
        if (corrected.time != null) {
          _selectedTime = TimeOfDay(hour: corrected.time!.hour, minute: corrected.time!.minute);
        }
        
        if (autoCategoryId != null) _selectedCategoryId = autoCategoryId;
        if (autoAccountId != null) _fromAccountId = autoAccountId;
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fiş okunamadı: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  /// Adds each receipt item as a separate expense transaction.
  Future<void> _addMultipleItemsAsTransactions({
    required List<ReceiptItem> items,
    required DateTime date,
    required TimeOfDay time,
    String? accountId,
    String? categoryId,
    String? receiptImagePath,
  }) async {
    final fullDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final notifier = ref.read(transactionProvider.notifier);
    for (final item in items) {
      await notifier.addTransaction(
        amount: item.price,
        type: 'expense',
        fromAccountId: accountId ?? _fromAccountId ?? '',
        categoryId: categoryId,
        description: '${item.name} - ${item.price.toStringAsFixed(2)} ₺',
        date: fullDateTime,
        receiptImagePath: receiptImagePath,
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${items.length} ürün ayrı işlem olarak eklendi!', style: GoogleFonts.poppins()),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submit() async {
  try {
    final amountText = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText);
    
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir tutar giriniz.')),
      );
      return;
    }
    
    if (_fromAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir hesap seçiniz.')),
      );
      return;
    }
    
    if (_tab == 2 && _toAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen hedef hesap seçiniz.')),
      );
      return;
    }

    final fullDateTime = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _selectedTime.hour, _selectedTime.minute,
    );

    await ref.read(transactionProvider.notifier).addTransaction(
          amount: amount,
          type: _txType,
          fromAccountId: _fromAccountId!,
          toAccountId: _toAccountId,
          categoryId: _selectedCategoryId,
          description: _descController.text.trim(),
          date: fullDateTime,
          receiptImagePath: _receiptImagePath,
          receiptItems: _receiptItems.isNotEmpty ? _receiptItems : null,
        );

    if (mounted) Navigator.of(context).pop();
  } catch (e) {
    debugPrint('Submit Error: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

  String get _actionLabel {
    switch (_tab) {
      case 0:
        return '+ GELİR EKLE';
      case 1:
        return '- GİDER EKLE';
      default:
        return '⇄ TRANSFER YAP';
    }
  }

  Color get _actionColor {
    switch (_tab) {
      case 0:
        return AppColors.green;
      case 1:
        return AppColors.red;
      default:
        return AppColors.blue;
    }
  }

  String get _txType {
    switch (_tab) {
      case 0:
        return 'income';
      case 1:
        return 'expense';
      default:
        return 'transfer';
    }
  }

  Widget _buildTabContent() {
    final accounts = ref.watch(accountProvider);
    final categories = _tab == 0
        ? ref.watch(incomeCategoryProvider)
        : ref.watch(expenseCategoryProvider);

    return Column(
      key: ValueKey(_tab),
      children: [
        if (_tab != 2) ...[
          const SizedBox(height: 12),
          // Category Selector
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => CategoryPicker(
                  type: _txType,
                  onSelected: (cat) {
                    setState(() => _selectedCategoryId = cat.id);
                  },
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.category_outlined, color: _actionColor, size: 18),
                      const SizedBox(width: 12),
                      Builder(
                        builder: (context) {
                          if (_selectedCategoryId == null) return Text('Kategori Seç', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 14));
                          
                          final cat = categories.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => categories.first);
                          if (cat.parentCategory != null) {
                            final parent = categories.firstWhere((c) => c.id == cat.parentCategory, orElse: () => cat);
                            return Text(
                              '${parent.name} > ${cat.name}',
                              style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w500),
                            );
                          }
                          return Text(cat.name, style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 14));
                        },
                      ),
                    ],
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 20),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        // From Account
        _AccountSelector(
          label: _tab == 2 ? 'Kaynak Hesap' : 'Hesap',
          accounts: accounts,
          selectedId: _fromAccountId,
          excludeId: _toAccountId,
          onChanged: (id) => setState(() => _fromAccountId = id),
        ),
        if (_tab == 2) ...[
          const SizedBox(height: 12),
          _AccountSelector(
            label: 'Hedef Hesap',
            accounts: accounts,
            selectedId: _toAccountId,
            excludeId: _fromAccountId,
            onChanged: (id) => setState(() => _toAccountId = id),
          ),
        ],
        const SizedBox(height: 12),
        // Description
        TextField(
          controller: _descController,
          style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
          decoration: const InputDecoration(
            labelText: 'Açıklama (opsiyonel)',
            prefixIcon:
                Icon(Icons.notes_outlined, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 20),
        // Amount
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.poppins(
                  color: _actionColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'TUTAR (₺)',
                  labelStyle: GoogleFonts.poppins(
                      color: AppColors.textSecondary, fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _actionColor, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: _actionColor.withOpacity( 0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _actionColor, width: 2),
                  ),
                  filled: true,
                  fillColor: _actionColor.withOpacity( 0.05),
                ),
              ),
            ),
            const SizedBox(width: 8),
              Container(
                height: 72,
                decoration: BoxDecoration(
                  color: Theme.of(context).inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                ),
                child: IconButton(
                  icon: _isScanning 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))
                    : const Icon(Icons.document_scanner_outlined, color: AppColors.gold),
                  tooltip: 'Fiş Tara',
                  onPressed: _isScanning ? null : _showScanOptions,
                ),
              ),
            ],
          ),
          if (_receiptItems.isNotEmpty || _receiptImagePath != null)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: true,
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                iconColor: AppColors.gold,
                collapsedIconColor: AppColors.gold,
                title: Row(
                  children: [
                    Text(
                      _receiptItems.length == 1 && _descController.text.contains(RegExp(r'Motorin|Benzin|Otogaz|LPG|Yakıt', caseSensitive: false))
                        ? '⛽ Akaryakıt Detayı'
                        : '🧾 Fiş İçeriği (${_receiptItems.length})',
                      style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    if (_receiptImagePath != null)
                      TextButton.icon(
                        icon: const Icon(Icons.document_scanner_outlined, size: 14, color: AppColors.gold),
                        label: const Text('Yeniden Tara', style: TextStyle(fontSize: 11, color: AppColors.gold)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: _isScanning ? null : _showScanOptions,
                      ),
                  ],
                ),
                children: [
                   if (_receiptItems.isNotEmpty)
                     ..._receiptItems.map((item) => ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        title: Text(item.name, style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 12)),
                        trailing: Text(
                          '${item.price.toStringAsFixed(2)} ₺',
                          style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      )).toList(),
                   if (_receiptItems.isEmpty && _receiptImagePath != null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: Text('Taranan fişte ürün bulunamadı.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                     ),
                ],
              ),
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 100 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => GlassCard(
          borderRadius: 24,
          blurSigma: 20,
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xE6121214) 
              : Colors.white.withOpacity(0.9),
          padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomPadding),
          child: ListView(
            controller: scrollCtrl,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'İŞLEM EKLE',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Tab bar
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: _actionColor.withOpacity( 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: _actionColor,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'GELİR'),
                    Tab(text: 'GİDER'),
                    Tab(text: 'TRANSFER'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Date + Time row
              Row(
                children: [
                  // Date picker
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.gold,
                                surface: Color(0xFF1A1B22),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).inputDecorationTheme.fillColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                color: AppColors.gold, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd MMM yyyy', 'tr_TR').format(_selectedDate),
                              style: GoogleFonts.poppins(
                                  color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Time picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                        builder: (ctx, child) => MediaQuery(
                          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        ),
                      );
                      if (picked != null) setState(() => _selectedTime = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.glassBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              color: AppColors.gold, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _selectedTime.format(context),
                            style: GoogleFonts.poppins(
                                color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Animated Tab Content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
                        .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic)),
                    child: child,
                  ),
                ),
                child: _buildTabContent(),
              ),

              const SizedBox(height: 24),
              // Action button
              BounceTap(
                onTap: _submit,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _actionColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _actionColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _actionLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

class _AccountSelector extends StatelessWidget {
  final String label;
  final List accounts;
  final String? selectedId;
  final String? excludeId;
  final ValueChanged<String?> onChanged;

  const _AccountSelector({
    required this.label,
    required this.accounts,
    this.selectedId,
    this.excludeId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filtered =
        accounts.where((a) => a.id != excludeId).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
              color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filtered.map<Widget>((a) {
            final selected = selectedId == a.id;
            return GestureDetector(
              onTap: () => onChanged(a.id as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                   color: selected
                      ? AppColors.gold.withOpacity( 0.15)
                      : AppColors.glassBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.gold : AppColors.glassBorder,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  a.name as String,
                  style: GoogleFonts.poppins(
                    color: selected ? AppColors.gold : AppColors.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

