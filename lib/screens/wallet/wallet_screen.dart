import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/transaction_model.dart';
import '../../models/wallet_model.dart';
import '../../providers/finance_provider.dart';
import '../../providers/investment_provider.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/backup_restore_dialog.dart';
import '../add_transaction/add_transaction_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  void _confirmResetAllData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.expenseColor, size: 28),
              SizedBox(width: 10),
              Text('Verileri Sıfırla'),
            ],
          ),
          content: const Text(
            'Uygulamadaki tüm işlemler, yatırımlar ve cüzdan bakiyeleri sıfırlanacak ve uygulama yeni yüklenmiş gibi tertemiz bir hale gelecektir.\n\nEmin misiniz?',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Vazgeç', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.expenseColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await context.read<FinanceProvider>().resetAllData();
                await context.read<InvestmentProvider>().resetAllData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white),
                          SizedBox(width: 10),
                          Text('Tüm veriler başarıyla sıfırlandı! Tertemiz bir başlangıç yapabilirsiniz.'),
                        ],
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }
              },
              child: const Text('Evet, Tümünü Sıfırla'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final finance = context.watch<FinanceProvider>();
    final bankWallets = finance.bankWallets;
    final creditWallets = finance.creditWallets;
    final cashWallet = finance.cashWallet;

    final cashTransactions = finance.transactions
        .where((t) => t.type == TransactionType.cashWithdrawal || t.paymentMethod == PaymentMethod.cash)
        .take(10)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cüzdan & Kart Yönetimi'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_card_rounded, color: primaryColor),
            tooltip: 'Yeni Kart / Banka Ekle',
            onPressed: () => _showAddWalletDialog(context),
          ),
          IconButton(
            icon: Icon(Icons.cloud_sync_rounded, color: primaryColor),
            tooltip: 'Yedekle / Geri Yükle',
            onPressed: () => BackupRestoreSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded, color: AppTheme.textSecondary),
            tooltip: 'Tüm Verileri Sıfırla (Temiz Başlangıç)',
            onPressed: () => _confirmResetAllData(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bank Accounts Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_rounded, size: 18, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Banka Hesapları (${bankWallets.length})',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Banka Ekle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  onPressed: () => _showAddWalletDialog(context, initialType: WalletType.bank),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...bankWallets.map((wallet) => _buildWalletCard(context, wallet, primaryColor)),

            const SizedBox(height: 16),

            // Credit Cards Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.credit_card_rounded, size: 18, color: Color(0xFF8E24AA)),
                    SizedBox(width: 8),
                    Text(
                      'Kredi Kartları',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Kart Ekle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  onPressed: () => _showAddWalletDialog(context, initialType: WalletType.creditCard),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...creditWallets.map((wallet) => _buildWalletCard(context, wallet, primaryColor)),

            const SizedBox(height: 16),

            // Cash Wallet Section
            if (cashWallet != null) ...[
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded, size: 18, color: AppTheme.incomeColor),
                  SizedBox(width: 8),
                  Text(
                    'Nakit Cüzdanı',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _buildWalletCard(context, cashWallet, primaryColor, isDeletable: false),
            ],

            const SizedBox(height: 18),

            // Cash Management Hero Box
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor.withValues(alpha: 0.22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.local_atm_rounded, color: primaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nakit Akışı ve ATM Takibi',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Çektiğiniz nakit paraların nereye harcandığını takip edin',
                              style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.local_atm_rounded, size: 18),
                          label: const Text(
                            'ATM\'den Çek',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddTransactionScreen(
                                  initialType: TransactionType.cashWithdrawal,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                          label: const Text(
                            'Nakit Harca',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddTransactionScreen(
                                  initialType: TransactionType.expense,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Cash Transaction History
            const Text(
              'Son Nakit Hareketleri (ATM & Nakit Harcamalar)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            if (cashTransactions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.money_off_rounded, size: 40, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      const Text(
                        'Henüz nakit çekim veya nakit harcama kaydı yok.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...cashTransactions.map(
                (tx) => TransactionTile(transaction: tx),
              ),
            const SizedBox(height: 20),

            // Danger Zone: Reset Button
            Center(
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.expenseColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                label: const Text(
                  'Tüm Verileri Sıfırla (Fabrika Ayarları)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
                onPressed: () => _confirmResetAllData(context),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showAddWalletDialog(BuildContext context, {WalletType initialType = WalletType.bank}) {
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    final limitCtrl = TextEditingController();
    final cutoffCtrl = TextEditingController();
    final dueCtrl = TextEditingController();
    final lastDigitsCtrl = TextEditingController();

    WalletType selectedType = initialType;
    String selectedBank = 'Garanti BBVA';

    final bankList = [
      'Garanti BBVA',
      'Türkiye İş Bankası',
      'Yapı Kredi',
      'Akbank',
      'QNB',
      'Ziraat Bankası',
      'Vakıfbank',
      'Halkbank',
      'Enpara.com',
      'Papara',
      'TEB',
      'Denizbank',
      'Diğer',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final isCredit = selectedType == WalletType.creditCard;
          final primaryColor = Theme.of(context).colorScheme.primary;

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isCredit ? 'Yeni Kredi Kartı Ekle' : 'Yeni Banka Hesabı Ekle',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(modalCtx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Type Toggle
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Banka Hesabı')),
                          selected: selectedType == WalletType.bank,
                          onSelected: (_) => setModalState(() => selectedType = WalletType.bank),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Kredi Kartı')),
                          selected: selectedType == WalletType.creditCard,
                          onSelected: (_) => setModalState(() => selectedType = WalletType.creditCard),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Bank Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedBank,
                    decoration: InputDecoration(
                      labelText: 'Banka / Kurum',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: bankList.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedBank = val;
                          if (nameCtrl.text.isEmpty) {
                            nameCtrl.text = isCredit ? '$val Kredi Kartı' : '$val Vadesiz Hesap';
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Custom Name
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Hesap / Kart Adı',
                      hintText: isCredit ? 'Örn: Bonus Platinum' : 'Örn: Maaş Hesabı',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Balance / Current Debt
                  TextField(
                    controller: balanceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: isCredit ? 'Güncel Dönem Borcu (₺)' : 'Mevcut Bakiye (₺)',
                      hintText: '0.00',
                      suffixText: '₺',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  if (isCredit) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: limitCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Kart Toplam Limiti (₺)',
                        hintText: '50000',
                        suffixText: '₺',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: cutoffCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Kesim Günü',
                              hintText: '15',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: dueCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Son Ödeme',
                              hintText: '25',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: lastDigitsCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            decoration: InputDecoration(
                              labelText: 'Son 4 Hane',
                              hintText: '1234',
                              counterText: '',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final title = nameCtrl.text.trim().isNotEmpty
                            ? nameCtrl.text.trim()
                            : (isCredit ? '$selectedBank Kartı' : '$selectedBank Hesabı');
                        final bal = double.tryParse(balanceCtrl.text.replaceAll(',', '.').trim()) ?? 0.0;
                        final limit = double.tryParse(limitCtrl.text.replaceAll(',', '.').trim());
                        final cut = int.tryParse(cutoffCtrl.text.trim());
                        final due = int.tryParse(dueCtrl.text.trim());
                        final last4 = lastDigitsCtrl.text.trim();

                        final newWallet = WalletModel(
                          id: 'wallet_${DateTime.now().millisecondsSinceEpoch}',
                          name: title,
                          bankName: selectedBank,
                          type: selectedType,
                          balance: bal,
                          cardLimit: limit,
                          cutoffDay: cut,
                          dueDay: due,
                          lastFourDigits: last4.isNotEmpty ? last4 : null,
                          icon: isCredit ? Icons.credit_card_rounded : Icons.account_balance_rounded,
                          color: isCredit ? const Color(0xFF8E24AA) : primaryColor,
                        );

                        await context.read<FinanceProvider>().addWallet(newWallet);
                        if (modalCtx.mounted) Navigator.of(modalCtx).pop();
                      },
                      child: const Text('Kaydet ve Ekle', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditBalanceDialog(BuildContext context, WalletModel wallet) {
    final controller = TextEditingController(text: wallet.balance > 0 ? wallet.balance.toStringAsFixed(2) : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${wallet.name} Bakiyesini Düzenle', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              wallet.type == WalletType.creditCard
                  ? 'Kredi kartınızdaki güncel dönem borcunu girin:'
                  : 'Hesabınızdaki güncel net bakiye tutarını girin:',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                suffixText: '₺',
                hintText: '0.00',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(controller.text.replaceAll(',', '.').trim());
              if (val != null) {
                await context.read<FinanceProvider>().setOfficialWalletBalance(wallet.id, val);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(
    BuildContext context,
    WalletModel wallet,
    Color themePrimaryColor, {
    bool isDeletable = true,
  }) {
    Color accentColor;
    Color bgColor;

    switch (wallet.type) {
      case WalletType.bank:
        accentColor = themePrimaryColor;
        bgColor = themePrimaryColor.withValues(alpha: 0.12);
        break;
      case WalletType.cash:
        accentColor = AppTheme.incomeColor;
        bgColor = AppTheme.incomeBg;
        break;
      case WalletType.creditCard:
        accentColor = const Color(0xFF8E24AA);
        bgColor = const Color(0xFF8E24AA).withValues(alpha: 0.12);
        break;
    }

    final isCredit = wallet.type == WalletType.creditCard;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showEditBalanceDialog(context, wallet),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(wallet.icon, color: accentColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                wallet.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            if (wallet.lastFourDigits != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F3F5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '• ${wallet.lastFourDigits}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isCredit
                              ? (wallet.cardLimit != null ? 'Limit: ${Formatters.formatCurrency(wallet.cardLimit!)}' : 'Dönem Borcu')
                              : (wallet.bankName ?? 'Kullanılabilir Bakiye'),
                          style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.formatCurrency(wallet.balance),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isCredit
                              ? (wallet.balance > 0 ? AppTheme.expenseColor : AppTheme.textPrimary)
                              : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined, size: 13, color: primaryColor(context)),
                          const SizedBox(width: 2),
                          Text(
                            'Düzenle',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: primaryColor(context)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (isCredit && wallet.dueDay != null) ...[
                const Divider(height: 16, color: AppTheme.divider),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      wallet.cutoffDay != null ? 'Hesap Kesim: Ayın ${wallet.cutoffDay}. Günü' : 'Kredi Kartı',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    Text(
                      'Son Ödeme: Ayın ${wallet.dueDay}. Günü',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8E24AA)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color primaryColor(BuildContext context) => Theme.of(context).colorScheme.primary;
}
