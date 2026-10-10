import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/investment_model.dart';

class MarketPriceService {
  /// Fetches live price in TRY for a specific investment based on its type and symbol
  static Future<double?> fetchLivePrice(InvestmentModel investment) async {
    switch (investment.type) {
      case InvestmentType.gold:
        return await fetchGoldPrice(investment.symbol);
      case InvestmentType.currency:
        return await fetchCurrencyRate(investment.symbol);
      case InvestmentType.stock:
        return await fetchStockPrice(investment.symbol);
      case InvestmentType.crypto:
        return await fetchCryptoPrice(investment.symbol);
      case InvestmentType.fund:
        return await fetchTefasFundPrice(investment.symbol);
      case InvestmentType.other:
        return null;
    }
  }

  /// Helper to parse Turkish localized number strings like "6.856,37" or "103,13" or 6856.37
  static double? _parseTrNumber(dynamic val) {
    if (val == null) return null;
    final s = val.toString().replaceAll('\$', '').replaceAll('₺', '').replaceAll('€', '').replaceAll(' ', '').trim();
    if (s.isEmpty) return null;
    // Replace thousands separator dot if comma is used as decimal separator
    String normalized = s;
    if (normalized.contains(',') && normalized.contains('.')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else if (normalized.contains(',')) {
      normalized = normalized.replaceAll(',', '.');
    }
    return double.tryParse(normalized);
  }

  /// 1. Gold & Precious Metals (Gram Altın, Çeyrek, Yarım, Tam, 22 Ayar, Gümüş vb.)
  /// Uses Truncgil API (Direct Turkish Market) + Binance PAXG + Open.er-api fallback
  static Future<double?> fetchGoldPrice(String symbol) async {
    final sym = symbol.toUpperCase().trim();

    // Strategy 1: Truncgil Turkish Gold & Finance Live API
    try {
      final res = await http.get(Uri.parse('https://finans.truncgil.com/today.json')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (sym.contains('GUMUS') || sym.contains('GÜMÜŞ') || sym.contains('XAG')) {
          final p = _parseTrNumber(data['gumus']?['Satış'] ?? data['gumus']?['Satis']);
          if (p != null && p > 0) return p;
        } else if (sym.contains('CEYREK') || sym.contains('ÇEYREK')) {
          final p = _parseTrNumber(data['ceyrek-altin']?['Satış'] ?? data['ceyrek-altin']?['Satis']);
          if (p != null && p > 0) return p;
        } else if (sym.contains('YARIM')) {
          final p = _parseTrNumber(data['yarim-altin']?['Satış'] ?? data['yarim-altin']?['Satis']);
          if (p != null && p > 0) return p;
        } else if (sym.contains('TAM') || sym.contains('CUMHURIYET') || sym.contains('CUMHURİYET')) {
          final p = _parseTrNumber(data['cumhuriyet-altini']?['Satış'] ?? data['cumhuriyet-altini']?['Satis'] ?? data['tam-altin']?['Satış']);
          if (p != null && p > 0) return p;
        } else if (sym.contains('ATA') || sym.contains('RESAT') || sym.contains('REŞAT')) {
          final p = _parseTrNumber(data['ata-altin']?['Satış'] ?? data['ata-altin']?['Satis']);
          if (p != null && p > 0) return p;
        } else if (sym.contains('22') || sym.contains('BILEZIK') || sym.contains('BİLEZİK')) {
          final p = _parseTrNumber(data['22-ayar-bilezik']?['Satış'] ?? data['22-ayar-bilezik']?['Satis']);
          if (p != null && p > 0) return p;
        } else if (sym.contains('14')) {
          final p = _parseTrNumber(data['14-ayar-altin']?['Satış'] ?? data['14-ayar-altin']?['Satis']);
          if (p != null && p > 0) return p;
        } else {
          // Default Gram Altın
          final p = _parseTrNumber(data['gram-altin']?['Satış'] ?? data['gram-altin']?['Satis'] ?? data['gram-has-altin']?['Satış']);
          if (p != null && p > 0) return p;
        }
      }
    } catch (_) {}

    // Strategy 2: Binance PAXG (1 PAXG = 1 Fine Troy Ounce Gold) + USDTTRY
    double? gramAltinTry;
    try {
      final rGold = await http.get(Uri.parse('https://api.binance.com/api/v3/ticker/price?symbol=PAXGUSDT')).timeout(const Duration(seconds: 4));
      final rUsdt = await http.get(Uri.parse('https://api.binance.com/api/v3/ticker/price?symbol=USDTTRY')).timeout(const Duration(seconds: 4));

      if (rGold.statusCode == 200 && rUsdt.statusCode == 200) {
        final goldUsd = double.tryParse(jsonDecode(rGold.body)['price']?.toString() ?? '');
        final usdtTry = double.tryParse(jsonDecode(rUsdt.body)['price']?.toString() ?? '');

        if (goldUsd != null && usdtTry != null && goldUsd > 0 && usdtTry > 0) {
          gramAltinTry = (goldUsd / 31.1034768) * usdtTry;
        }
      }
    } catch (_) {}

    // Strategy 3: Open Exchange Rates Fallback
    if (gramAltinTry == null) {
      try {
        final r = await http.get(Uri.parse('https://open.er-api.com/v6/latest/USD')).timeout(const Duration(seconds: 4));
        if (r.statusCode == 200) {
          final data = jsonDecode(r.body);
          final usdTry = (data['rates']['TRY'] as num).toDouble();
          final xauRate = data['rates']['XAU'] != null ? (data['rates']['XAU'] as num).toDouble() : null;
          if (xauRate != null && xauRate > 0) {
            final ounceUsd = 1.0 / xauRate;
            gramAltinTry = (ounceUsd / 31.1034768) * usdTry;
          }
        }
      } catch (_) {}
    }

    if (gramAltinTry != null && gramAltinTry > 0) {
      if (sym.contains('CEYREK') || sym.contains('ÇEYREK')) {
        return gramAltinTry * 1.635;
      } else if (sym.contains('YARIM')) {
        return gramAltinTry * 3.27;
      } else if (sym.contains('TAM') || sym.contains('CUMHURIYET') || sym.contains('CUMHURİYET')) {
        return gramAltinTry * 6.54;
      } else if (sym.contains('ATA') || sym.contains('RESAT') || sym.contains('REŞAT')) {
        return gramAltinTry * 7.216;
      } else if (sym.contains('22') || sym.contains('BILEZIK') || sym.contains('BİLEZİK')) {
        return gramAltinTry * 0.916;
      } else if (sym.contains('14')) {
        return gramAltinTry * 0.585;
      }
      return gramAltinTry;
    }

    return null;
  }

  /// 2. Foreign Currencies (USD, EUR, GBP, CHF, JPY, SAR, AED, CAD, AUD -> TRY)
  static Future<double?> fetchCurrencyRate(String symbol) async {
    final clean = symbol.toUpperCase().replaceAll('/TRY', '').replaceAll('TRY', '').replaceAll('/', '').trim();
    String base = 'USD';
    if (clean.contains('EUR')) base = 'EUR';
    if (clean.contains('GBP') || clean.contains('STERLIN')) base = 'GBP';
    if (clean.contains('CHF')) base = 'CHF';
    if (clean.contains('JPY')) base = 'JPY';
    if (clean.contains('SAR')) base = 'SAR';
    if (clean.contains('AED')) base = 'AED';
    if (clean.contains('CAD')) base = 'CAD';
    if (clean.contains('AUD')) base = 'AUD';

    // 1. Try Truncgil
    try {
      final res = await http.get(Uri.parse('https://finans.truncgil.com/today.json')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final rate = _parseTrNumber(data[base]?['Satış'] ?? data[base]?['Satis']);
        if (rate != null && rate > 0) return rate;
      }
    } catch (_) {}

    // 2. Try Binance USDTTRY for USD
    if (base == 'USD') {
      try {
        final rUsdt = await http.get(Uri.parse('https://api.binance.com/api/v3/ticker/price?symbol=USDTTRY')).timeout(const Duration(seconds: 3));
        if (rUsdt.statusCode == 200) {
          final val = double.tryParse(jsonDecode(rUsdt.body)['price']?.toString() ?? '');
          if (val != null && val > 0) return val;
        }
      } catch (_) {}
    }

    // 3. Try Open Exchange Rates
    try {
      final url = Uri.parse('https://open.er-api.com/v6/latest/$base');
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rate = (data['rates']['TRY'] as num?)?.toDouble();
        if (rate != null && rate > 0) return rate;
      }
    } catch (_) {}
    return null;
  }

  /// 3. Stocks (BIST & Global Stocks)
  static Future<double?> fetchStockPrice(String symbol) async {
    try {
      String formattedSymbol = symbol.toUpperCase().trim();
      if (!formattedSymbol.contains('.') && !formattedSymbol.contains('^')) {
        formattedSymbol = '$formattedSymbol.IS';
      }

      final url = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$formattedSymbol?interval=1d');
      final response = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 4));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final meta = data['chart']['result'][0]['meta'];
        final price = (meta['regularMarketPrice'] as num).toDouble();
        return price;
      }
    } catch (_) {}
    return null;
  }

  /// 4. Cryptocurrencies (BTC, ETH, SOL, XRP, AVAX, BNB -> TRY)
  /// Uses Binance Public API
  static Future<double?> fetchCryptoPrice(String symbol) async {
    try {
      String clean = symbol.toUpperCase().replaceAll('/', '').replaceAll('-', '').replaceAll('TRY', '').replaceAll('USDT', '').trim();
      
      // Try direct TRY pair first e.g. BTCTRY
      final urlTry = Uri.parse('https://api.binance.com/api/v3/ticker/price?symbol=${clean}TRY');
      final resTry = await http.get(urlTry).timeout(const Duration(seconds: 4));
      if (resTry.statusCode == 200) {
        final data = json.decode(resTry.body);
        final price = double.tryParse(data['price']?.toString() ?? '');
        if (price != null && price > 0) return price;
      }

      // Fallback: USDT pair * USDTTRY
      final urlUsdt = Uri.parse('https://api.binance.com/api/v3/ticker/price?symbol=${clean}USDT');
      final resUsdt = await http.get(urlUsdt).timeout(const Duration(seconds: 4));
      final resFx = await http.get(Uri.parse('https://api.binance.com/api/v3/ticker/price?symbol=USDTTRY')).timeout(const Duration(seconds: 4));

      if (resUsdt.statusCode == 200 && resFx.statusCode == 200) {
        final priceUsdt = double.tryParse(json.decode(resUsdt.body)['price']?.toString() ?? '');
        final usdTry = double.tryParse(json.decode(resFx.body)['price']?.toString() ?? '');
        if (priceUsdt != null && usdTry != null) {
          return priceUsdt * usdTry;
        }
      }
    } catch (_) {}
    return null;
  }

  /// 5. TEFAS Investment Funds
  static Future<double?> fetchTefasFundPrice(String fundCode) async {
    try {
      final code = fundCode.toUpperCase().replaceAll('FON', '').trim();
      final url = Uri.parse('https://www.tefas.gov.tr/api/DB/BindHistoryInfo');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0',
        },
        body: {
          'fontip': 'YAT',
          'fonkod': code,
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && (data['data'] as List).isNotEmpty) {
          final latest = (data['data'] as List).first;
          return (latest['FIYAT'] as num).toDouble();
        }
      }
    } catch (_) {}
    return null;
  }
}
