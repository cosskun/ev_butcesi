import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/finance_provider.dart';
import '../../services/statement_parser_service.dart';

enum ImportFilterMode { all, newOnly, duplicateOnly }

class StatementImportScreen extends StatefulWidget {
  const StatementImportScreen({super.key});

  @override
  State<StatementImportScreen> createState() => _StatementImportScreenState();
}

class _StatementImportScreenState extends State<StatementImportScreen> {
  final TextEditingController _textController = TextEditingController();
  StatementParseResult? _parseResult;
  bool _isAnalyzing = false;
  bool _isImporting = false;
  double _analysisProgress = 0.0;
  String _analysisStatus = '';
  int _displayLimit = 50;
  ImportFilterMode _filterMode = ImportFilterMode.all;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickStatementFile() async {
    final existing = context.read<FinanceProvider>().transactions;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'csv', 'txt', 'xlsx'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _isAnalyzing = true;
          _analysisProgress = 0.05;
          _analysisStatus = 'Dosya hazırlanıyor...';
        });

        final pickedFile = result.files.first;

        void updateProgress(double progress, String status) {
          if (mounted) {
            setState(() {
              _analysisProgress = progress;
              _analysisStatus = status;
            });
          }
        }

        StatementParseResult parseRes;
        if (pickedFile.path != null) {
          final file = File(pickedFile.path!);
          parseRes = await StatementParserService.parseFile(
            file,
            existingTransactions: existing,
            onProgress: updateProgress,
          );
        } else if (pickedFile.bytes != null) {
          final bytes = pickedFile.bytes!;
          parseRes = await StatementParserService.parseBytes(
            bytes,
            pickedFile.name,
            existingTransactions: existing,
            onProgress: updateProgress,
          );
        } else {
          throw Exception('Dosya içeriği okunamadı.');
        }

        if (mounted) {
          setState(() {
            _parseResult = parseRes;
            _displayLimit = 50;
            if (parseRes.rawExtractedText != null && parseRes.rawExtractedText!.length < 1000) {
              _textController.text = parseRes.rawExtractedText!;
            } else {
              _textController.text = '[PDF Belgesi: ${pickedFile.name} - ${parseRes.totalCount} işlem başarıyla yüklendi]';
            }
            _filterMode = parseRes.duplicateCount > 0 ? ImportFilterMode.newOnly : ImportFilterMode.all;
            _isAnalyzing = false;
          });

          if (parseRes.detectedFormat != null && parseRes.detectedFormat!.startsWith('Hata')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(parseRes.detectedFormat!), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya okunurken hata oluştu: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _parsePastedText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen ekstre metni girin veya dosya seçin.')),
      );
      return;
    }

    final existing = context.read<FinanceProvider>().transactions;
    setState(() {
      _isAnalyzing = true;
      _analysisProgress = 0.3;
      _analysisStatus = 'Metin ayrıştırılıyor...';
    });
    await Future.delayed(const Duration(milliseconds: 30));

    setState(() {
      _analysisProgress = 0.7;
      _analysisStatus = 'İşlemler ve kategoriler taranıyor...';
    });
    await Future.delayed(const Duration(milliseconds: 30));

    final parseRes = StatementParserService.parseText(
      text,
      existingTransactions: existing,
    );

    setState(() {
      _analysisProgress = 1.0;
      _analysisStatus = 'Tamamlandı!';
      _parseResult = parseRes;
      _displayLimit = 50;
      _filterMode = parseRes.duplicateCount > 0 ? ImportFilterMode.newOnly : ImportFilterMode.all;
      _isAnalyzing = false;
    });
  }

  Future<void> _importSelected() async {
    if (_parseResult == null) return;
    final selectedTxs = _parseResult!.selectedNewTransactions;

    if (selectedTxs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kaydedilecek yeni bir işlem seçilmedi.')),
      );
      return;
    }

    setState(() => _isImporting = true);

    try {
      final finance = context.read<FinanceProvider>();
      await finance.importTransactions(selectedTxs);

      if (_parseResult?.officialClosingBalance != null) {
        await finance.setOfficialWalletBalance('wallet_bank', _parseResult!.officialClosingBalance!);
      }
      if (_parseResult?.officialPeriodDebt != null) {
        await finance.setOfficialWalletBalance('wallet_credit', _parseResult!.officialPeriodDebt!);
      }
      if (_parseResult?.officialDueDate != null) {
        await finance.setCreditCardDueDate(
          _parseResult!.officialDueDate,
          minPayment: _parseResult?.officialMinPayment,
        );
      }

      if (mounted) {
        setState(() => _isImporting = false);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text('${selectedTxs.length} yeni işlem başarıyla bütçenize aktarıldı!'),
              ],
            ),
            backgroundColor: AppTheme.incomeColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt sırasında hata oluştu: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _toggleSelectAll(bool selectAll, List<ParsedStatementItem> visibleItems) {
    setState(() {
      for (final item in visibleItems) {
        if (!item.isDuplicate) {
          item.isSelected = selectAll;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final parseRes = _parseResult;
    final selectedNewCount = parseRes?.selectedNewTransactions.length ?? 0;

    List<ParsedStatementItem> visibleItems = [];
    if (parseRes != null) {
      if (_filterMode == ImportFilterMode.newOnly) {
        visibleItems = parseRes.items.where((i) => !i.isDuplicate).toList();
      } else if (_filterMode == ImportFilterMode.duplicateOnly) {
        visibleItems = parseRes.items.where((i) => i.isDuplicate).toList();
      } else {
        visibleItems = parseRes.items;
      }
    }

    final displayedItems = visibleItems.take(_displayLimit).toList();

    final allVisibleSelected = visibleItems.where((i) => !i.isDuplicate).isNotEmpty &&
        visibleItems.where((i) => !i.isDuplicate).every((i) => i.isSelected);

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Banka Ekstresi Aktar'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Description Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_awesome_rounded, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'PDF, CSV veya ekstre metninizi yükleyin. Sistem harcamaları, maaşı, taksitleri ve mükerrer kayıtları otomatik ayıklar.',
                      style: TextStyle(fontSize: 12, height: 1.35, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // File Pick Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.upload_file_rounded, size: 20),
                    label: const Text('PDF / CSV Seç', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    onPressed: _isAnalyzing ? null : _pickStatementFile,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.flash_on_rounded, size: 20),
                    label: const Text('Metni Analiz Et', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    onPressed: _isAnalyzing ? null : _parsePastedText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Text Input Box
            TextField(
              controller: _textController,
              maxLines: 4,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: 'veya banka hareketlerinizi buraya yapıştırıp "Metni Analiz Et"e basın...',
                hintStyle: const TextStyle(fontSize: 12),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_isAnalyzing) ...[
              _buildProgressCard(),
            ] else if (parseRes != null) ...[
              if (parseRes.officialClosingBalance != null || parseRes.officialPeriodDebt != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.incomeBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.incomeColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: AppTheme.incomeColor, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          parseRes.officialClosingBalance != null
                              ? 'Resmî Bakiye Tespit Edildi: ${Formatters.formatCurrency(parseRes.officialClosingBalance!)}\nBanka cüzdanınız otomatik olarak bu tutarla eşitlenecektir.'
                              : 'Resmî Kart Borcu: ${Formatters.formatCurrency(parseRes.officialPeriodDebt!)}${parseRes.officialDueDate != null ? '\nSon Ödeme Tarihi: ${DateFormat("d MMMM yyyy", "tr_TR").format(parseRes.officialDueDate!)}' : ''}${parseRes.officialMinPayment != null ? ' (Asgari: ${Formatters.formatCurrency(parseRes.officialMinPayment!)})' : ''}\nKart ödeme takviminiz otomatik kurulacaktır.',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.incomeColor, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Results Header & 3-Tab Filter
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    // Summary counts row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.incomeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${parseRes.newCount} Yeni',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.incomeColor),
                            ),
                          ],
                        ),
                        if (parseRes.duplicateCount > 0)
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${parseRes.duplicateCount} Mükerrer (Atlandı)',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.orange),
                              ),
                            ],
                          ),
                        Text(
                          'Toplam: ${parseRes.totalCount}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: AppTheme.divider),

                    // 3-Way Filter Segmented Control
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildFilterTab(
                              title: 'Tümü (${parseRes.totalCount})',
                              isSelected: _filterMode == ImportFilterMode.all,
                              onTap: () => setState(() => _filterMode = ImportFilterMode.all),
                            ),
                          ),
                          Expanded(
                            child: _buildFilterTab(
                              title: 'Yeni (${parseRes.newCount})',
                              isSelected: _filterMode == ImportFilterMode.newOnly,
                              onTap: () => setState(() => _filterMode = ImportFilterMode.newOnly),
                            ),
                          ),
                          Expanded(
                            child: _buildFilterTab(
                              title: 'Mükerrer (${parseRes.duplicateCount})',
                              isSelected: _filterMode == ImportFilterMode.duplicateOnly,
                              onTap: () => setState(() => _filterMode = ImportFilterMode.duplicateOnly),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Select All / Deselect All Row
              if (visibleItems.isNotEmpty && _filterMode != ImportFilterMode.duplicateOnly)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${visibleItems.length} işlem gösteriliyor',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(
                          allVisibleSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
                          size: 16,
                          color: primaryColor,
                        ),
                        label: Text(
                          allVisibleSelected ? 'Seçimi Kaldır' : 'Tümünü Seç',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primaryColor),
                        ),
                        onPressed: () => _toggleSelectAll(!allVisibleSelected, visibleItems),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),

              if (visibleItems.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.filter_list_off_rounded, color: primaryColor, size: 36),
                        const SizedBox(height: 10),
                        Text(
                          _filterMode == ImportFilterMode.duplicateOnly
                              ? 'Bu belgede mükerrer kayıt bulunmuyor.'
                              : 'Gösterilecek işlem bulunamadı.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Safe, Responsive Items List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedItems.length,
                  itemBuilder: (context, index) {
                    final item = displayedItems[index];
                    final tx = item.transaction;
                    final cat = CategoryModel.findById(tx.categoryId);
                    final isIncome = tx.type == TransactionType.income;
                    final isCash = tx.type == TransactionType.cashWithdrawal;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: item.isDuplicate ? const Color(0xFFFFFBEA) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: item.isDuplicate ? Colors.amber.withValues(alpha: 0.6) : AppTheme.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Selection Checkbox
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: Checkbox(
                              value: item.isSelected && !item.isDuplicate,
                              activeColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: item.isDuplicate
                                  ? null
                                  : (val) {
                                      setState(() {
                                        item.isSelected = val ?? false;
                                      });
                                    },
                            ),
                          ),
                          const SizedBox(width: 4),

                          // Category Icon
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isCash ? AppTheme.cashBg : (isIncome ? AppTheme.incomeBg : cat.bgColor),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isCash ? Icons.local_atm_rounded : cat.icon,
                              size: 17,
                              color: isCash ? AppTheme.cashColor : (isIncome ? AppTheme.incomeColor : cat.color),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Title and Subtitle Info (Fully Ellipsized & Responsive)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tx.title,
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${Formatters.formatShortDate(tx.date)} • ${cat.name}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Amount and Status Badge Column (Never Overflows)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${isIncome ? '+' : (isCash ? '🏧 ' : '-')}${Formatters.formatCurrency(tx.amount)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isIncome
                                      ? AppTheme.incomeColor
                                      : (isCash ? AppTheme.cashColor : AppTheme.expenseColor),
                                ),
                              ),
                              if (item.isDuplicate) ...[
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Text(
                                    'Mükerrer',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (visibleItems.length > _displayLimit) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.expand_more_rounded, size: 18),
                          label: Text(
                            '+50 Daha (${visibleItems.length - _displayLimit} kaldı)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () {
                            setState(() {
                              _displayLimit += 50;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        child: Text(
                          'Tümü (${visibleItems.length})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          setState(() {
                            _displayLimit = visibleItems.length;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ],
              const SizedBox(height: 20),

              // Batch Import Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.verified_user_rounded),
                  label: _isImporting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('$selectedNewCount Yeni İşlemi Güvenle Kaydet', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  onPressed: (_isImporting || selectedNewCount == 0) ? null : _importSelected,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final percent = (_analysisProgress * 100).clamp(0, 100).toInt();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular Progress with percentage
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: _analysisProgress > 0 ? _analysisProgress : null,
                  strokeWidth: 6,
                  backgroundColor: primaryColor.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Dynamic Status title
          Text(
            _analysisStatus.isNotEmpty ? _analysisStatus : 'Ekstre Taranıyor...',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Lütfen bekleyin, işlemler ve taksitler taranıyor...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          // Linear animated Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _analysisProgress > 0 ? _analysisProgress : null,
              minHeight: 8,
              backgroundColor: primaryColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
          const SizedBox(height: 16),

          // Helpful feature badges
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 14, color: primaryColor),
                    const SizedBox(width: 4),
                    const Text(
                      'Taksit & Mükerrer Kontrolü',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.category_rounded, size: 14, color: AppTheme.incomeColor),
                    SizedBox(width: 4),
                    Text(
                      'Akıllı Kategori',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            maxLines: 1,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? primaryColor : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
