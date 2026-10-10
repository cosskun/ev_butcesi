import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/finance_provider.dart';
import '../../services/image_storage_service.dart';
import '../../services/receipt_parser_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionType initialType;

  const AddTransactionScreen({
    super.key,
    this.initialType = TransactionType.expense,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late TransactionType _type;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  late String _selectedCategoryId;
  late DateTime _selectedDate;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  String? _receiptImagePath;
  bool _isSaving = false;

  final List<double> _quickAmounts = [100, 250, 500, 1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _selectedDate = DateTime.now();
    _selectedCategoryId = _type == TransactionType.income
        ? 'maas'
        : (_type == TransactionType.cashWithdrawal ? 'nakit_cekildi' : 'market');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _type = type;
      if (_type == TransactionType.income) {
        _selectedCategoryId = 'maas';
        _paymentMethod = PaymentMethod.bankCard;
      } else if (_type == TransactionType.cashWithdrawal) {
        _selectedCategoryId = 'nakit_cekildi';
        _titleController.text = 'ATM Nakit Çekim';
        _paymentMethod = PaymentMethod.bankCard;
      } else {
        _selectedCategoryId = 'market';
        if (_titleController.text == 'ATM Nakit Çekim') {
          _titleController.clear();
        }
      }
    });
  }

  Future<void> _capturePhoto() async {
    final path = await ImageStorageService.captureReceiptPhoto();
    if (path != null) {
      setState(() => _receiptImagePath = path);
    }
  }

  Future<void> _pickGalleryPhoto() async {
    final path = await ImageStorageService.pickReceiptFromGallery();
    if (path != null) {
      setState(() => _receiptImagePath = path);
    }
  }

  void _openReceiptScannerDialog() {
    final textController = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final surfaceColor = theme.colorScheme.surface;
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.receipt_long_rounded, color: primaryColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hızlı Fiş Okuyucu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
                        Text('Fiş metninden tutar ve marketi otomatik çıkarır', style: TextStyle(fontSize: 11, color: textSecondary)),
                      ],
                    ),
                  ],
                ),
                IconButton(icon: Icon(Icons.close_rounded, color: textSecondary), onPressed: () => Navigator.of(ctx).pop()),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 5,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Fiş metnini veya e-arşiv mesajını buraya yapıştırın...\nÖrnek:\nBİM BİRLEŞİK MAĞAZALAR\nSÜT 34,50\nTOPLAM 120,50 TL\nTARİH 01.08.2026',
                hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.bolt_rounded),
                label: const Text('Ayrıştır ve Bilgileri Doldur', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () {
                  final text = textController.text.trim();
                  if (text.isEmpty) return;
                  final parsed = ReceiptParserService.parseReceiptText(text);
                  setState(() {
                    if (parsed.amount > 0) {
                      _amountController.text = parsed.amount.toStringAsFixed(2);
                    }
                    _titleController.text = parsed.title;
                    _selectedCategoryId = parsed.categoryId;
                    _selectedDate = parsed.date;
                  });
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${parsed.title} - ${parsed.amount > 0 ? Formatters.formatCurrency(parsed.amount) : ""} başarıyla aktarıldı!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    final amountText = _amountController.text.replaceAll(',', '.').trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir tutar girin.'),
          backgroundColor: AppTheme.expenseColor,
        ),
      );
      return;
    }

    String title = _titleController.text.trim();
    if (title.isEmpty) {
      if (_type == TransactionType.cashWithdrawal) {
        title = 'ATM Nakit Çekim';
      } else {
        final cat = CategoryModel.findById(_selectedCategoryId);
        title = '${cat.name} Harcaması';
      }
    }

    setState(() => _isSaving = true);

    final newTransaction = TransactionModel(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      type: _type,
      categoryId: _selectedCategoryId,
      date: _selectedDate,
      paymentMethod: _type == TransactionType.cashWithdrawal ? PaymentMethod.cash : _paymentMethod,
      imagePath: _receiptImagePath,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      sourceWalletId: 'wallet_bank',
      targetWalletId: _type == TransactionType.cashWithdrawal ? 'wallet_cash' : null,
    );

    await context.read<FinanceProvider>().addTransaction(newTransaction);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                _type == TransactionType.income
                    ? 'Gelir kaydedildi!'
                    : (_type == TransactionType.cashWithdrawal ? 'Nakit çekim kaydedildi!' : 'Gider kaydedildi!'),
              ),
            ],
          ),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _type == TransactionType.income
        ? CategoryModel.defaultIncomeCategories
        : (_type == TransactionType.cashWithdrawal
            ? [CategoryModel.findById('nakit_cekildi')]
            : CategoryModel.defaultExpenseCategories);

    return Scaffold(
      appBar: AppBar(
        title: const Text('İşlem Ekle'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segmented Type Selector (Gider | Gelir | Nakit Çekim)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(
                      title: 'Gider',
                      type: TransactionType.expense,
                      color: AppTheme.expenseColor,
                      icon: Icons.arrow_downward_rounded,
                    ),
                  ),
                  Expanded(
                    child: _buildTypeButton(
                      title: 'Gelir',
                      type: TransactionType.income,
                      color: AppTheme.incomeColor,
                      icon: Icons.arrow_upward_rounded,
                    ),
                  ),
                  Expanded(
                    child: _buildTypeButton(
                      title: 'Nakit Çekim',
                      type: TransactionType.cashWithdrawal,
                      color: AppTheme.cashColor,
                      icon: Icons.local_atm_rounded,
                    ),
                  ),
                ],
              ),
            ),

            // Quick Receipt Scan Button
            if (_type == TransactionType.expense) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  icon: Icon(Icons.receipt_long_rounded, size: 18, color: theme.colorScheme.primary),
                  label: Text(
                    'Hızlı Fiş Tara / Metin Yapıştır',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                  ),
                  onPressed: _openReceiptScannerDialog,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Amount Input
            Center(
              child: Column(
                children: [
                  Text(
                    'TUTAR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary.withOpacity(0.8),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  IntrinsicWidth(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        prefixText: '₺ ',
                        prefixStyle: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: '0',
                        hintStyle: TextStyle(color: AppTheme.textMuted),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Quick Amount Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickAmounts.map((amt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text('+${Formatters.formatCurrency(amt)}'),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppTheme.border),
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      onPressed: () {
                        final current = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
                        _amountController.text = (current + amt).toStringAsFixed(0);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Title / Description
            const Text(
              'Açıklama / Kalem',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: _type == TransactionType.expense
                    ? 'örn: 1000 TL muz alındı, Market, Fatura'
                    : (_type == TransactionType.income ? 'örn: Ağustos Maaşı, Kira Geliri' : 'örn: ATM Nakit Çekim'),
                prefixIcon: const Icon(Icons.edit_note_rounded, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 20),

            // Category Selection
            const Text(
              'Kategori',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = _selectedCategoryId == cat.id;
                return ChoiceChip(
                  avatar: Icon(
                    cat.icon,
                    size: 16,
                    color: isSelected ? Colors.white : cat.color,
                  ),
                  label: Text(cat.name),
                  selected: isSelected,
                  selectedColor: cat.color,
                  backgroundColor: cat.bgColor.withOpacity(0.5),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: isSelected ? cat.color : AppTheme.border,
                    width: 1,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategoryId = cat.id);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Payment Method
            if (_type != TransactionType.cashWithdrawal) ...[
              const Text(
                'Ödeme Yöntemi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildPaymentMethodOption(
                    method: PaymentMethod.cash,
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Nakit',
                  ),
                  const SizedBox(width: 8),
                  _buildPaymentMethodOption(
                    method: PaymentMethod.bankCard,
                    icon: Icons.credit_card_rounded,
                    label: 'Banka Kartı',
                  ),
                  const SizedBox(width: 8),
                  _buildPaymentMethodOption(
                    method: PaymentMethod.creditCard,
                    icon: Icons.payment_rounded,
                    label: 'Kredi Kartı',
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Date & Time Picker
            const Text(
              'Tarih & Saat',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_rounded, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '${Formatters.formatDate(_selectedDate)} - ${Formatters.formatTime(_selectedDate)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (pickedDate != null && mounted) {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(_selectedDate),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            _selectedDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        } else {
                          setState(() {
                            _selectedDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              _selectedDate.hour,
                              _selectedDate.minute,
                            );
                          });
                        }
                      }
                    },
                    child: const Text('Değiştir'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Receipt Photo / Attachment
            const Text(
              'Fiş / Fatura Fotoğrafı (Opsiyonel)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            if (_receiptImagePath != null) ...[
              Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(_receiptImagePath!),
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 16, color: Colors.white),
                          onPressed: () => setState(() => _receiptImagePath = null),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.camera_alt_rounded, size: 18, color: theme.colorScheme.primary),
                      label: const Text('Kamera'),
                      onPressed: _capturePhoto,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.photo_library_rounded, size: 18, color: theme.colorScheme.primary),
                      label: const Text('Galeri'),
                      onPressed: _pickGalleryPhoto,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // Note (Optional)
            const Text(
              'Ek Not',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'İşleme dair kısa not ekleyebilirsiniz...',
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveTransaction,
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'İşlemi Kaydet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required String title,
    required TransactionType type,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _type == type;
    return GestureDetector(
      onTap: () => _onTypeChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required PaymentMethod method,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _paymentMethod == method;
    final primary = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = method),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primary.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? primary : AppTheme.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? primary : AppTheme.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? primary : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
