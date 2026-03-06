import 'package:flutter/material.dart';
import '../../data/models/receipt_item.dart';
import '../../data/services/turkish_receipt_parser.dart';

/// A bottom sheet that shows OCR results with editable fields.
/// User can correct any wrong value before confirming.
/// Returns a corrected ParsedReceipt when confirmed.
class OcrReviewSheet extends StatefulWidget {
  final ParsedReceipt result;
  final VoidCallback onConfirm;

  const OcrReviewSheet({
    required this.result,
    required this.onConfirm,
    super.key,
  });

  static Future<ParsedReceipt?> show(
    BuildContext context,
    ParsedReceipt result,
  ) {
    return showModalBottomSheet<ParsedReceipt>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OcrReviewSheet(result: result, onConfirm: () {}),
    );
  }

  @override
  State<OcrReviewSheet> createState() => _OcrReviewSheetState();
}

class _OcrReviewSheetState extends State<OcrReviewSheet> {
  late TextEditingController _merchantCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _timeCtrl;
  late List<ReceiptItem> _items;

  // Confidence indicators — show yellow warning for uncertain values
  bool _amountConfident = true;
  bool _merchantConfident = true;

  @override
  void initState() {
    super.initState();
    final r = widget.result;
    _merchantCtrl = TextEditingController(text: r.merchantName ?? '');
    _amountCtrl   = TextEditingController(
      text: r.total != null ? r.total!.toStringAsFixed(2) : '',
    );
    _dateCtrl = TextEditingController(
      text: r.date != null
          ? '${r.date!.day.toString().padLeft(2,'0')}/'
            '${r.date!.month.toString().padLeft(2,'0')}/'
            '${r.date!.year}'
          : '',
    );
    _timeCtrl = TextEditingController(
      text: r.time != null
          ? '${r.time!.hour.toString().padLeft(2,'0')}:'
            '${r.time!.minute.toString().padLeft(2,'0')}'
          : '',
    );
    _items = List.from(r.items);

    // Flag uncertain values
    _amountConfident = r.hasTotal;
    _merchantConfident = r.merchantName != null && r.merchantName!.isNotEmpty;
  }

  @override
  void dispose() {
    _merchantCtrl.dispose();
    _amountCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle + title ───────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                _receiptTypeIcon(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🔍 Fiş Tarama Sonucu',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _receiptTypeLabel(),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                // Confidence badge
                if (!_amountConfident || !_merchantConfident)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      '⚠️ Kontrol et',
                      style: TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Editable fields ──────────────────────────────────────────
            _buildField(
              label: 'Mağaza / Açıklama',
              controller: _merchantCtrl,
              icon: Icons.store_outlined,
              isWarning: !_merchantConfident,
              warningText: 'Mağaza adı okunamadı — elle girin',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildField(
                    label: 'Tutar (₺)',
                    controller: _amountCtrl,
                    icon: Icons.attach_money,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    isWarning: !_amountConfident,
                    warningText: 'Tutar doğrulanamadı',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildField(
                    label: 'Tarih',
                    controller: _dateCtrl,
                    icon: Icons.calendar_today_outlined,
                    hint: 'GG/AA/YYYY',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildField(
                    label: 'Saat',
                    controller: _timeCtrl,
                    icon: Icons.access_time_outlined,
                    hint: 'SS:DD',
                  ),
                ),
              ],
            ),

            // ── Fuel extras ───────────────────────────────────────────────
            if (widget.result.isFuel) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Text('⛽', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(
                        spacing: 16, runSpacing: 4,
                        children: [
                          if (widget.result.fuelType != null)
                            Text('${widget.result.fuelType}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          if (widget.result.fuelLiters != null)
                            Text('${widget.result.fuelLiters!.toStringAsFixed(2)} lt',
                                style: const TextStyle(fontSize: 13)),
                          if (widget.result.vehiclePlate != null)
                            Text(widget.result.vehiclePlate!,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Items list (collapsible) ───────────────────────────────────
            if (_items.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildItemsSection(),
            ],

            const SizedBox(height: 20),

            // ── Action buttons ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, null), // discard
                    child: const Text('Vazgeç'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _confirm,
                    child: const Text('✓ Kullan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isWarning = false,
    String? warningText,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isWarning && warningText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '⚠️ $warningText',
              style: const TextStyle(fontSize: 10, color: Colors.orange),
            ),
          ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isWarning
                    ? Colors.orange.withValues(alpha: 0.6)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isWarning ? Colors.orange : Theme.of(context).colorScheme.primary,
              ),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '📦 Ürünler (${_items.length})',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () => setState(() => _items.clear()),
              child: const Text('Temizle', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxHeight: 180),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(8),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const Divider(height: 8),
            itemBuilder: (_, i) {
              final item = _items[i];
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.quantity != null && item.quantity! > 1)
                     Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '${item.quantity}x',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ),
                  Text(
                    '${item.price.toStringAsFixed(2)} ₺',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 14),
                    onPressed: () => setState(() => _items.removeAt(i)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirm() {
    // Parse the edited fields back into a ParsedReceipt
    final amount = double.tryParse(
      _amountCtrl.text.replaceAll(',', '.'),
    );

    DateTime? date;
    final dateParts = _dateCtrl.text.split('/');
    if (dateParts.length == 3) {
      date = DateTime(
        int.tryParse(dateParts[2]) ?? DateTime.now().year,
        int.tryParse(dateParts[1]) ?? 1,
        int.tryParse(dateParts[0]) ?? 1,
      );
    }

    TimeOfDay? time;
    final timeParts = _timeCtrl.text.split(':');
    if (timeParts.length == 2) {
      final h = int.tryParse(timeParts[0]);
      final m = int.tryParse(timeParts[1]);
      if (h != null && m != null) time = TimeOfDay(hour: h, minute: m);
    }

    final corrected = ParsedReceipt(
      receiptType: widget.result.receiptType,
      merchantName: _merchantCtrl.text.trim().isEmpty ? null : _merchantCtrl.text.trim(),
      total: amount,
      date: date,
      time: time,
      accountHint: widget.result.accountHint,
      items: _items,
      rawText: widget.result.rawText,
      fuelLiters: widget.result.fuelLiters,
      fuelType: widget.result.fuelType,
      vehiclePlate: widget.result.vehiclePlate,
    );

    Navigator.pop(context, corrected);
  }

  Widget _receiptTypeIcon() {
    final (icon, color) = switch (widget.result.receiptType) {
      ReceiptType.fuel       => ('⛽', Colors.orange),
      ReceiptType.market     => ('🛒', Colors.green),
      ReceiptType.restaurant => ('🍽️', Colors.red),
      ReceiptType.utility    => ('⚡', Colors.blue),
      ReceiptType.unknown    => ('🧾', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(icon, style: const TextStyle(fontSize: 20)),
    );
  }

  String _receiptTypeLabel() {
    return switch (widget.result.receiptType) {
      ReceiptType.fuel       => 'Akaryakıt Fişi',
      ReceiptType.market     => 'Market Fişi',
      ReceiptType.restaurant => 'Restoran Fişi',
      ReceiptType.utility    => 'Fatura',
      ReceiptType.unknown    => 'Genel Fiş',
    };
  }
}
