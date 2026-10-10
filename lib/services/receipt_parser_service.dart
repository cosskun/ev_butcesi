class ParsedReceipt {
  final String title;
  final double amount;
  final DateTime date;
  final String categoryId;
  final String? rawText;

  const ParsedReceipt({
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryId,
    this.rawText,
  });
}

class ReceiptParserService {
  /// Parses raw receipt text from OCR or pasted text
  static ParsedReceipt parseReceiptText(String rawText) {
    final lines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    DateTime date = DateTime.now();
    double amount = 0.0;
    String merchant = 'Hızlı Harcama';
    String categoryId = 'diger_gider';

    // 1. Date Detection (GG.AA.YYYY or GG/AA/YYYY)
    final dateRegex = RegExp(r'\b(0?[1-9]|[12][0-9]|3[01])[./\-](0?[1-9]|1[0-2])[./\-](\d{4}|\d{2})\b');
    for (final line in lines) {
      final match = dateRegex.firstMatch(line);
      if (match != null) {
        final d = int.tryParse(match.group(1)!) ?? 1;
        final m = int.tryParse(match.group(2)!) ?? 1;
        int y = int.tryParse(match.group(3)!) ?? DateTime.now().year;
        if (y < 100) y += 2000;
        date = DateTime(y, m, d);
        break;
      }
    }

    // 2. Merchant Detection
    final upperText = rawText.toUpperCase();
    if (upperText.contains('BIM') || upperText.contains('BİM')) {
      merchant = 'BİM Market';
      categoryId = 'market';
    } else if (upperText.contains('A101')) {
      merchant = 'A101 Market';
      categoryId = 'market';
    } else if (upperText.contains('SOK') || upperText.contains('ŞOK')) {
      merchant = 'ŞOK Market';
      categoryId = 'market';
    } else if (upperText.contains('MIGROS') || upperText.contains('MİGROS')) {
      merchant = 'Migros';
      categoryId = 'market';
    } else if (upperText.contains('CARREFOUR')) {
      merchant = 'CarrefourSA';
      categoryId = 'market';
    } else if (upperText.contains('TARIM KREDİ') || upperText.contains('TARIM KREDI')) {
      merchant = 'Tarım Kredi Koop.';
      categoryId = 'market';
    } else if (upperText.contains('FILE MARKET') || upperText.contains('FİLE MARKET')) {
      merchant = 'File Market';
      categoryId = 'market';
    } else if (upperText.contains('ECZANE')) {
      merchant = 'Eczane Harcaması';
      categoryId = 'saglik';
    } else if (upperText.contains('SHELL') || upperText.contains('OPET') || upperText.contains('BP') || upperText.contains('PETROL OFİSİ') || upperText.contains('TOTAL')) {
      merchant = 'Akaryakıt İstasyonu';
      categoryId = 'ulasim';
    } else if (upperText.contains('STARBUCKS') || upperText.contains('ESPRESSOLAB') || upperText.contains('KAHVE')) {
      merchant = 'Kafe / Kahve';
      categoryId = 'eglence';
    } else if (lines.isNotEmpty) {
      // Pick first readable title line (ignoring headers like T.C., FIS vb.)
      for (final line in lines.take(4)) {
        if (!line.toUpperCase().contains('MALİ DEĞERİ') &&
            !line.toUpperCase().contains('FİŞ NO') &&
            !line.toUpperCase().contains('TARİH') &&
            line.length > 3) {
          merchant = line;
          break;
        }
      }
    }

    // 3. Total Amount Detection (TOPLAM, ÖDENECEK TUTAR, KDV DAHİL TOPLAM)
    final totalRegex = RegExp(
      r'(?:TOPLAM|TUTAR|ODENECEK|ÖDENECEK|GENEL\s+TOPLAM|KDV\s+DAHİL\s+TOPLAM)[\s:*=]*([0-9]{1,3}(?:\.[0-9]{3})*(?:,[0-9]{1,2})|[0-9]+(?:[.,][0-9]{1,2}))',
      caseSensitive: false,
    );

    for (final line in lines.reversed) {
      final match = totalRegex.firstMatch(line);
      if (match != null) {
        final rawVal = match.group(1)!;
        final clean = rawVal.replaceAll('.', '').replaceAll(',', '.');
        final val = double.tryParse(clean);
        if (val != null && val > 0) {
          amount = val;
          break;
        }
      }
    }

    // Fallback: If no explicit "TOPLAM" keyword, find the largest amount in the bottom half of the receipt
    if (amount == 0.0) {
      final numberRegex = RegExp(r'\b([0-9]{1,3}(?:\.[0-9]{3})*(?:,[0-9]{2})|[0-9]+(?:[.,][0-9]{2}))\b');
      double maxFound = 0.0;
      for (final line in lines) {
        for (final m in numberRegex.allMatches(line)) {
          final rawVal = m.group(1)!;
          final clean = rawVal.replaceAll('.', '').replaceAll(',', '.');
          final val = double.tryParse(clean) ?? 0.0;
          if (val > maxFound && val < 500000.0) {
            maxFound = val;
          }
        }
      }
      amount = maxFound;
    }

    return ParsedReceipt(
      title: merchant,
      amount: amount,
      date: date,
      categoryId: categoryId,
      rawText: rawText,
    );
  }
}
