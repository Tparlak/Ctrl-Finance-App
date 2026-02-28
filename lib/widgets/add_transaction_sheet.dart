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

void showAddTransactionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AddTransactionSheet(),
  );
}

class AddTransactionSheet extends ConsumerStatefulWidget {
  final dynamic existingTransaction; // TransactionModel? - kept as dynamic to avoid circular dep
  const AddTransactionSheet({super.key, this.existingTransaction});

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
  String? _fromAccountId;
  String? _toAccountId;
  String? _selectedCategoryId;

  String? _receiptImagePath;
  final _ocrService = OcrService();
  bool _isScanning = false;

  // 0=income, 1=expense, 2=transfer
  int get _tab => _tabController.index;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTransaction;
    int initialTab = 1; // default expense
    if (existing != null) {
      // Pre-fill for edit mode
      _amountController.text = existing.amount.toString();
      _descController.text = existing.description;
      _selectedDate = existing.date;
      _fromAccountId = existing.fromAccountId;
      _toAccountId = existing.toAccountId;
      _selectedCategoryId = existing.categoryId;
      if (existing.type == 'income') initialTab = 0;
      else if (existing.type == 'expense') initialTab = 1;
      else initialTab = 2;
    }
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialTab);
    _tabController.addListener(() => setState(() {
      _selectedCategoryId = null;
    }));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _descController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (photo == null) return;

    setState(() => _isScanning = true);
    try {
      final result = await _ocrService.scanReceipt(photo.path);
      setState(() {
        _receiptImagePath = photo.path;
        if (result.amount != null) _amountController.text = result.amount!.toStringAsFixed(2).replaceAll('.', ',');
        if (result.description != null && _descController.text.isEmpty) {
          _descController.text = result.description!;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fiş okunamadı: $e')),
        );
      }
    } finally {
      setState(() => _isScanning = false);
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

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir tutar giriniz.')),
      );
      return;
    }
    if (_fromAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hesap seçiniz.')),
      );
      return;
    }
    if (_tab == 2 && _toAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hedef hesap seçiniz.')),
      );
      return;
    }

    await ref.read(transactionProvider.notifier).addTransaction(
          amount: amount,
          type: _txType,
          fromAccountId: _fromAccountId!,
          toAccountId: _toAccountId,
          categoryId: _selectedCategoryId,
          description: _descController.text.trim(),
          date: _selectedDate,
          receiptImagePath: _receiptImagePath,
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountProvider);
    // Show income or expense categories based on active tab
    final categories = _tab == 0
        ? ref.watch(incomeCategoryProvider)
        : ref.watch(expenseCategoryProvider);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      color: Colors.transparent,
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => GlassCard(
          borderRadius: 24,
          blurSigma: 20,
          backgroundColor: const Color(0xE6121214),
          padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomPadding),
          child: ListView(
            controller: scrollCtrl,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'İŞLEM EKLE',
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
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
                  color: AppColors.glassBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: _actionColor.withValues(alpha: 0.2),
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
              // Date picker
              GestureDetector(
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.glassBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppColors.gold, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd MMMM yyyy', 'tr_TR')
                            .format(_selectedDate),
                        style: GoogleFonts.poppins(
                            color: AppColors.textPrimary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
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
              if (_tab != 2) ...[
                const SizedBox(height: 12),
                // Category Selector
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppColors.background,
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
                      color: AppColors.glassBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.category_outlined, color: _actionColor, size: 18),
                            const SizedBox(width: 12),
                            Text(
                              _selectedCategoryId == null 
                                ? 'Kategori Seç' 
                                : categories.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => categories.first).name,
                              style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 14),
                            ),
                          ],
                        ),
                        Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Description
              TextField(
                controller: _descController,
                style: GoogleFonts.poppins(color: AppColors.textPrimary),
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.poppins(
                        color: _actionColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'TUTAR',
                        labelStyle: GoogleFonts.poppins(
                            color: AppColors.textSecondary, fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _actionColor, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: _actionColor.withValues(alpha: 0.4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _actionColor, width: 2),
                        ),
                        filled: true,
                        fillColor: _actionColor.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.glassBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: IconButton(
                      icon: _isScanning 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))
                        : const Icon(Icons.document_scanner_outlined, color: AppColors.gold),
                      tooltip: 'Fiş Tara',
                      onPressed: _isScanning ? null : _scanReceipt,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Action button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _actionColor,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _actionLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
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
                      ? AppColors.gold.withValues(alpha: 0.15)
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
