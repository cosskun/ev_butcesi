import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/investment_model.dart';
import '../../providers/investment_provider.dart';
import '../../services/market_price_service.dart';

class AddInvestmentScreen extends StatefulWidget {
  final InvestmentModel? editInvestment;

  const AddInvestmentScreen({super.key, this.editInvestment});

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  InvestmentType _selectedType = InvestmentType.gold;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _buyPriceController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  double? _livePrice;
  bool _isLoadingLivePrice = false;

  @override
  void initState() {
    super.initState();
    if (widget.editInvestment != null) {
      final inv = widget.editInvestment!;
      _selectedType = inv.type;
      _titleController.text = inv.title;
      _symbolController.text = inv.symbol;
      _quantityController.text = inv.quantity.toString();
      _buyPriceController.text = inv.buyUnitPrice.toString();
      _selectedDate = inv.buyDate;
      _noteController.text = inv.note ?? '';
    } else {
      _titleController.text = 'Gram Altın';
      _symbolController.text = 'GAU/TRY';
    }

    // Auto-fetch live market price on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLiveMarketPrice();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _symbolController.dispose();
    _quantityController.dispose();
    _buyPriceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveMarketPrice() async {
    if (!mounted) return;
    setState(() => _isLoadingLivePrice = true);

    try {
      final tempInv = InvestmentModel(
        id: 'temp',
        title: _titleController.text.trim(),
        symbol: _symbolController.text.trim().isNotEmpty ? _symbolController.text.trim() : _titleController.text.trim(),
        type: _selectedType,
        quantity: 1,
        buyUnitPrice: 1,
        currentUnitPrice: 1,
        buyDate: DateTime.now(),
      );

      final price = await MarketPriceService.fetchLivePrice(tempInv);
      if (mounted) {
        setState(() {
          _livePrice = price;
          _isLoadingLivePrice = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingLivePrice = false);
      }
    }
  }

  void _onTypeChanged(InvestmentType type) {
    setState(() {
      _selectedType = type;
      _livePrice = null;
      if (widget.editInvestment == null) {
        switch (type) {
          case InvestmentType.gold:
            _titleController.text = 'Gram Altın';
            _symbolController.text = 'GAU/TRY';
            break;
          case InvestmentType.stock:
            _titleController.text = 'THYAO';
            _symbolController.text = 'THYAO.IS';
            break;
          case InvestmentType.currency:
            _titleController.text = 'Amerikan Doları';
            _symbolController.text = 'USD/TRY';
            break;
          case InvestmentType.fund:
            _titleController.text = 'Yatırım Fonu';
            _symbolController.text = 'FON';
            break;
          case InvestmentType.crypto:
            _titleController.text = 'Bitcoin';
            _symbolController.text = 'BTC/USDT';
            break;
          case InvestmentType.other:
            _titleController.text = 'Varlık';
            _symbolController.text = 'VARLIK';
            break;
        }
      }
    });
    _fetchLiveMarketPrice();
  }

  void _applyPreset(String title, String symbol) {
    setState(() {
      _titleController.text = title;
      _symbolController.text = symbol;
      _livePrice = null;
    });
    _fetchLiveMarketPrice();
  }

  Future<void> _saveInvestment() async {
    final title = _titleController.text.trim();
    final symbol = _symbolController.text.trim().isNotEmpty ? _symbolController.text.trim() : title;
    final quantity = double.tryParse(_quantityController.text.replaceAll(',', '.').trim());
    final buyPrice = double.tryParse(_buyPriceController.text.replaceAll(',', '.').trim());
    
    final currentPrice = _livePrice ?? buyPrice;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen yatırım başlığı girin.')),
      );
      return;
    }

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir miktar / adet girin.')),
      );
      return;
    }

    if (buyPrice == null || buyPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen aldığınız birim fiyatı (Alış Fiyatı) girin.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final provider = context.read<InvestmentProvider>();

    if (widget.editInvestment != null) {
      final updated = widget.editInvestment!.copyWith(
        title: title,
        symbol: symbol,
        type: _selectedType,
        quantity: quantity,
        buyUnitPrice: buyPrice,
        currentUnitPrice: currentPrice ?? buyPrice,
        buyDate: _selectedDate,
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      );
      await provider.updateInvestment(updated);
    } else {
      final newInv = InvestmentModel(
        id: const Uuid().v4(),
        title: title,
        symbol: symbol,
        type: _selectedType,
        quantity: quantity,
        buyUnitPrice: buyPrice,
        currentUnitPrice: currentPrice ?? buyPrice,
        buyDate: _selectedDate,
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      );
      await provider.addInvestment(newInv);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(widget.editInvestment != null ? 'Yatırım güncellendi!' : 'Yatırım portföye eklendi!'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editInvestment != null ? 'Yatırımı Düzenle' : 'Yatırım & Varlık Ekle'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Investment Type Selector Chips
            const Text(
              'Varlık / Yatırım Türü',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: InvestmentType.values.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  avatar: Icon(type.icon, size: 16, color: isSelected ? Colors.white : type.color),
                  label: Text(type.displayName),
                  selected: isSelected,
                  selectedColor: type.color,
                  backgroundColor: type.bgColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  side: BorderSide(color: isSelected ? type.color : AppTheme.border),
                  onSelected: (selected) {
                    if (selected) _onTypeChanged(type);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Quick Presets according to selected type
            if (_selectedType == InvestmentType.gold) ...[
              const Text(
                'Hızlı Altın Seçenekleri',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildPresetChip('Gram Altın', 'GAU/TRY'),
                  _buildPresetChip('Çeyrek Altın', 'CEYREK'),
                  _buildPresetChip('Yarım Altın', 'YARIM'),
                  _buildPresetChip('Cumhuriyet Altını', 'CUMHURIYET'),
                  _buildPresetChip('Ata Altın', 'ATA'),
                  _buildPresetChip('22 Ayar Bilezik', '22AYAR'),
                  _buildPresetChip('Gümüş (gr)', 'GUMUS'),
                ],
              ),
              const SizedBox(height: 16),
            ] else if (_selectedType == InvestmentType.currency) ...[
              const Text(
                'Hızlı Döviz Seçenekleri',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildPresetChip('Dolar (\$)', 'USD/TRY'),
                  _buildPresetChip('Euro (€)', 'EUR/TRY'),
                  _buildPresetChip('Sterlin (£)', 'GBP/TRY'),
                  _buildPresetChip('İsviçre Frangı', 'CHF/TRY'),
                ],
              ),
              const SizedBox(height: 16),
            ] else if (_selectedType == InvestmentType.crypto) ...[
              const Text(
                'Hızlı Kripto Seçenekleri',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildPresetChip('Bitcoin', 'BTC/USDT'),
                  _buildPresetChip('Ethereum', 'ETH/USDT'),
                  _buildPresetChip('Solana', 'SOL/USDT'),
                  _buildPresetChip('Avalanche', 'AVAX/USDT'),
                  _buildPresetChip('Ripple (XRP)', 'XRP/USDT'),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Live Price Info Card / Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _selectedType.bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _selectedType.color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, color: _selectedType.color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _isLoadingLivePrice
                        ? const Text(
                            'Canlı piyasa fiyatı sorgulanıyor...',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                          )
                        : Text(
                            _livePrice != null
                                ? 'Canlı Piyasa Fiyatı: ${Formatters.formatCurrency(_livePrice!)} (Otomatik atanır)'
                                : 'Canlı piyasa fiyatı alınamadı (Manuel fiyat girebilirsiniz)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _livePrice != null ? _selectedType.color : AppTheme.textSecondary,
                            ),
                          ),
                  ),
                  if (_isLoadingLivePrice)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Piyasayı Yeniden Sorgula',
                      onPressed: _fetchLiveMarketPrice,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Title & Symbol
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Varlık Adı',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _titleController,
                        onChanged: (_) => _fetchLiveMarketPrice(),
                        decoration: InputDecoration(
                          hintText: 'örn: Gram Altın, THYAO',
                          prefixIcon: Icon(_selectedType.icon, color: _selectedType.color, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sembol / Kod',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _symbolController,
                        onChanged: (_) => _fetchLiveMarketPrice(),
                        decoration: const InputDecoration(
                          hintText: 'GAU, USD',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Quantity & Unit
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Miktar (${_selectedType.unitLabel}) *',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: 'örn: 1, 10, 25.5',
                          suffixText: _selectedType.unitLabel,
                          suffixStyle: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Buy Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alış Birim Fiyatı (₺) *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _buyPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Satın aldığınız birim fiyat (örn: 2850)',
                    prefixText: '₺ ',
                    prefixStyle: const TextStyle(fontWeight: FontWeight.w700),
                    helperText: _livePrice != null
                        ? 'Anlık piyasa değeri (${Formatters.formatCurrency(_livePrice!)}) otomatik olarak atanacaktır.'
                        : 'Anlık piyasa değeri sistem tarafından otomatik olarak atanacaktır.',
                    helperStyle: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Buy Date
            const Text(
              'Alım Tarihi',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2010),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        Formatters.formatShortDate(_selectedDate),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      'Değiştir',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Note
            const Text(
              'Not / Açıklama (Opsiyonel)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Yatırıma dair not ekleyebilirsiniz (örn: Düğün altını, 3 yıllık hedef)...',
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveInvestment,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.editInvestment != null ? 'Değişiklikleri Kaydet' : 'Yatırımı Portföye Ekle',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String title, String symbol) {
    final isSelected = _titleController.text == title || _symbolController.text == symbol;
    return ActionChip(
      label: Text(title),
      backgroundColor: isSelected ? _selectedType.bgColor : Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? _selectedType.color : AppTheme.textPrimary,
      ),
      side: BorderSide(
        color: isSelected ? _selectedType.color : AppTheme.border,
        width: isSelected ? 1.5 : 1.0,
      ),
      onPressed: () => _applyPreset(title, symbol),
    );
  }
}
