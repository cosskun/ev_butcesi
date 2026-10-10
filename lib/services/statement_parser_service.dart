import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';

class ParsedStatementItem {
  final TransactionModel transaction;
  final bool isDuplicate;
  final String? duplicateReason;
  bool isSelected;

  ParsedStatementItem({
    required this.transaction,
    this.isDuplicate = false,
    this.duplicateReason,
    this.isSelected = true,
  });
}

class StatementParseResult {
  final List<ParsedStatementItem> items;
  final int totalCount;
  final int newCount;
  final int duplicateCount;
  final double totalNewIncome;
  final double totalNewExpense;
  final String? detectedFormat;
  final String? rawExtractedText;
  final double? officialClosingBalance;
  final double? officialPeriodDebt;
  final DateTime? officialDueDate;
  final double? officialMinPayment;
  final bool isCreditCard;

  StatementParseResult({
    required this.items,
    required this.totalCount,
    required this.newCount,
    required this.duplicateCount,
    required this.totalNewIncome,
    required this.totalNewExpense,
    this.detectedFormat,
    this.rawExtractedText,
    this.officialClosingBalance,
    this.officialPeriodDebt,
    this.officialDueDate,
    this.officialMinPayment,
    this.isCreditCard = false,
  });

  List<TransactionModel> get selectedNewTransactions => items
      .where((i) => i.isSelected && !i.isDuplicate)
      .map((i) => i.transaction)
      .toList();
}

class StatementParserService {
  static const Map<String, int> _turkishMonths = {
    'ocak': 1, 'oca': 1,
    'şubat': 2, 'subat': 2, 'şub': 2, 'sub': 2,
    'mart': 3, 'mar': 3,
    'nisan': 4, 'nis': 4,
    'mayıs': 5, 'mayis': 5, 'may': 5,
    'haziran': 6, 'haz': 6,
    'temmuz': 7, 'tem': 7,
    'ağustos': 8, 'agustos': 8, 'ağu': 8, 'agu': 8, 'austos': 8,
    'eylül': 9, 'eylul': 9, 'eyl': 9,
    'ekim': 10, 'eki': 10,
    'kasım': 11, 'kasim': 11, 'kas': 11,
    'aralık': 12, 'aralik': 12, 'ara': 12,
  };

  /// Parse file bytes directly (Cross-platform: Web, Windows, Android, iOS)
  static Future<StatementParseResult> parseBytes(
    Uint8List bytes,
    String fileName, {
    List<TransactionModel> existingTransactions = const [],
    void Function(double progress, String status)? onProgress,
  }) async {
    final ext = p.extension(fileName).toLowerCase();

    if (ext == '.pdf') {
      try {
        onProgress?.call(0.05, 'PDF belgesi yükleniyor...');
        await Future.delayed(const Duration(milliseconds: 20));

        final PdfDocument document = PdfDocument(inputBytes: bytes);
        final StringBuffer sb = StringBuffer();
        final PdfTextExtractor extractor = PdfTextExtractor(document);
        final int totalPages = document.pages.count;

        for (int i = 0; i < totalPages; i++) {
          final progress = 0.1 + (0.75 * (i + 1) / (totalPages > 0 ? totalPages : 1));
          onProgress?.call(progress, 'Sayfa ${i + 1} / $totalPages taranıyor...');
          await Future.delayed(const Duration(milliseconds: 15));

          try {
            final pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
            sb.writeln(pageText);
          } catch (_) {
            try {
              final pageText = extractor.extractText(startPageIndex: i);
              sb.writeln(pageText);
            } catch (_) {}
          }
        }

        if (sb.isEmpty) {
          try {
            final allText = extractor.extractText();
            sb.writeln(allText);
          } catch (_) {}
        }

        document.dispose();

        onProgress?.call(0.90, 'İşlemler, taksitler ve mükerrerler ayıklanıyor...');
        await Future.delayed(const Duration(milliseconds: 20));

        final String extractedText = sb.toString();
        final result = parseText(
          extractedText,
          formatLabel: 'PDF Banka Ekstresi',
          existingTransactions: existingTransactions,
        );

        onProgress?.call(1.0, 'Ayrıştırma başarıyla tamamlandı!');
        await Future.delayed(const Duration(milliseconds: 30));
        return result;
      } catch (e) {
        return StatementParseResult(
          items: [],
          totalCount: 0,
          newCount: 0,
          duplicateCount: 0,
          totalNewIncome: 0,
          totalNewExpense: 0,
          detectedFormat: 'Hata: PDF okunamadı ($e)',
          rawExtractedText: '',
        );
      }
    }

    String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      content = latin1.decode(bytes);
    }

    onProgress?.call(0.5, 'Metin analiz ediliyor...');
    await Future.delayed(const Duration(milliseconds: 20));

    final res = parseText(
      content,
      formatLabel: ext == '.csv' ? 'CSV Dosyası' : 'Metin / Ekstre',
      existingTransactions: existingTransactions,
    );

    onProgress?.call(1.0, 'Ayrıştırma tamamlandı!');
    return res;
  }

  /// Parse file (PDF, CSV, TXT or others) with intelligent deduplication
  static Future<StatementParseResult> parseFile(
    File file, {
    List<TransactionModel> existingTransactions = const [],
    void Function(double progress, String status)? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    return parseBytes(
      bytes,
      file.path,
      existingTransactions: existingTransactions,
      onProgress: onProgress,
    );
  }

  static String _normalizeRawText(String text) {
    var result = text
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u200B', '')
        .replaceAll('\uFEFF', '')
        .replaceAll('\t', ' ');

    // PostScript / CID / Adobe Glyph names found in Turkish banking PDFs
    result = result.replaceAll('Odieresis', 'Ö').replaceAll('odieresis', 'ö');
    result = result.replaceAll('Udieresis', 'Ü').replaceAll('udieresis', 'ü');
    result = result.replaceAll('Ccedilla', 'Ç').replaceAll('ccedilla', 'ç');
    result = result.replaceAll('Scedilla', 'Ş').replaceAll('scedilla', 'ş');
    result = result.replaceAll('Gbreve', 'Ğ').replaceAll('gbreve', 'ğ');
    result = result.replaceAll('Idotaccent', 'İ').replaceAll('dotlessi', 'ı').replaceAll('dotlessI', 'ı');

    result = result.replaceAll(RegExp(r'A\s+ustos', caseSensitive: false), 'Ağustos');
    result = result.replaceAll(RegExp(r'Ş\s*ub\s*at|Sub\s*at', caseSensitive: false), 'Şubat');
    result = result.replaceAll(RegExp(r'Eyl\s*ul|Eyl\s*ül', caseSensitive: false), 'Eylül');
    result = result.replaceAll(RegExp(r'Kas\s*ım|Kas\s*im', caseSensitive: false), 'Kasım');
    result = result.replaceAll(RegExp(r'Tem\s*muz', caseSensitive: false), 'Temmuz');
    result = result.replaceAll(RegExp(r'Haz\s*iran', caseSensitive: false), 'Haziran');
    result = result.replaceAll(RegExp(r'May\s*ıs|May\s*is', caseSensitive: false), 'Mayıs');
    result = result.replaceAll(RegExp(r'Nis\s*an', caseSensitive: false), 'Nisan');
    result = result.replaceAll(RegExp(r'Mar\s*t', caseSensitive: false), 'Mart');
    result = result.replaceAll(RegExp(r'Oc\s*ak', caseSensitive: false), 'Ocak');
    result = result.replaceAll(RegExp(r'Ar\s*al\s*ık|Ar\s*al\s*ik', caseSensitive: false), 'Aralık');
    return result;
  }

  static bool _detectIfCreditCard(String text) {
    final u = text.toUpperCase();
    return u.contains('DÖNEM BORCUNUZ') ||
        u.contains('DONEM BORCUNUZ') ||
        u.contains('KREDİ KARTI EKSTRESİ') ||
        u.contains('KREDI KARTI EKSTRESI') ||
        u.contains('BONUS TRİNK') ||
        u.contains('BONUS TRINK') ||
        u.contains('WORLDCARD') ||
        u.contains('MAXIMUM KART') ||
        u.contains('AXESS') ||
        u.contains('KART LİMİTİ') ||
        u.contains('KART LIMITI') ||
        u.contains('ASGARİ ÖDEME') ||
        u.contains('ASGARI ODEME') ||
        u.contains('HESAP KESİM TARİHİ') ||
        u.contains('HESAP KESIM TARIHI') ||
        u.contains('SON ÖDEME TARİHİ') ||
        u.contains('SON ODEME TARIHI');
  }

  static double? _detectOfficialClosingBalance(String text) {
    final regex = RegExp(
      r'(?:Kullanılabilir\s+Bakiye|Bakiye)\s*[:\s]*([0-9]{1,3}(?:\.[0-9]{3})*(?:,[0-9]{1,2})|[0-9]+(?:[.,][0-9]{1,2}))',
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    if (match != null) {
      return _tryParseAmount(match.group(1)!);
    }
    return null;
  }

  static double? _detectOfficialPeriodDebt(String text) {
    final regex = RegExp(
      r'(?:DÖNEM\s+BORCUNUZ|DONEM\s+BORCUNUZ|TOPLAM\s+BORÇ|TOPLAM\s+BORC)\s*[:\s]*([0-9]{1,3}(?:\.[0-9]{3})*(?:,[0-9]{1,2})|[0-9]+(?:[.,][0-9]{1,2}))',
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    if (match != null) {
      return _tryParseAmount(match.group(1)!);
    }
    return null;
  }

  static DateTime? _detectOfficialDueDate(String text) {
    final regex = RegExp(
      r'(?:Son\s+Ödeme\s+Tarihi|Son\s+Odeme\s+Tarihi)\s*[:\s]*([0-9]{1,2})\s*([a-zA-ZğüşıöçĞÜŞİÖÇ]+|[0-9]{1,2})\s*([0-9]{4})?',
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    if (match != null) {
      final day = int.tryParse(match.group(1)!);
      final rawMonth = match.group(2)!.toLowerCase().trim();
      final yearStr = match.group(3);
      int year = DateTime.now().year;
      if (yearStr != null) {
        year = int.tryParse(yearStr) ?? year;
      }
      if (day != null && day >= 1 && day <= 31) {
        final monthInt = int.tryParse(rawMonth);
        if (monthInt != null && monthInt >= 1 && monthInt <= 12) {
          return DateTime(year, monthInt, day);
        }
        var mStr = rawMonth;
        if (mStr.startsWith('a') && mStr.endsWith('ustos')) mStr = 'ağustos';
        final m = _turkishMonths[mStr];
        if (m != null) {
          return DateTime(year, m, day);
        }
      }
    }
    return null;
  }

  static double? _detectOfficialMinPayment(String text) {
    final regex = RegExp(
      r'(?:Min\.?\s*Ödeme\s*Tutarı|Min\.?\s*Odeme\s*Tutari|Asgari\s*Ödeme|Asgari\s*Odeme)\s*[:\s]*([0-9]{1,3}(?:\.[0-9]{3})*(?:,[0-9]{1,2})|[0-9]+(?:[.,][0-9]{1,2}))',
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    if (match != null) {
      return _tryParseAmount(match.group(1)!);
    }
    return null;
  }

  /// Parse text content directly with deduplication
  static StatementParseResult parseText(
    String rawText, {
    String? formatLabel,
    List<TransactionModel> existingTransactions = const [],
  }) {
    final normalized = _normalizeRawText(rawText);
    final lines = const LineSplitter().convert(normalized);
    List<TransactionModel> extracted = [];
    String format = formatLabel ?? 'Metin / Ekstre';

    final isCreditCard = _detectIfCreditCard(rawText);
    final officialClosingBalance = _detectOfficialClosingBalance(rawText);
    final officialPeriodDebt = _detectOfficialPeriodDebt(rawText);
    final officialDueDate = _detectOfficialDueDate(rawText);
    final officialMinPayment = _detectOfficialMinPayment(rawText);

    // Check if CSV
    if (lines.isNotEmpty && (lines.first.contains(';') || lines.first.contains(','))) {
      final csvResults = _parseCsvLines(lines);
      if (csvResults.isNotEmpty) {
        extracted = csvResults;
        format = 'CSV Dosyası';
      }
    }

    if (extracted.isEmpty) {
      extracted = _parseGenericTextLines(lines, isCreditCard: isCreditCard);
    }

    return _buildDeduplicatedResult(
      extracted,
      existingTransactions,
      format,
      rawText,
      isCreditCard: isCreditCard,
      officialClosingBalance: officialClosingBalance,
      officialPeriodDebt: officialPeriodDebt,
      officialDueDate: officialDueDate,
      officialMinPayment: officialMinPayment,
    );
  }

  /// Detects duplicates by comparing occurrence frequency against existing records
  static StatementParseResult _buildDeduplicatedResult(
    List<TransactionModel> extracted,
    List<TransactionModel> existing,
    String format,
    String rawText, {
    bool isCreditCard = false,
    double? officialClosingBalance,
    double? officialPeriodDebt,
    DateTime? officialDueDate,
    double? officialMinPayment,
  }) {
    // Count occurrences of each signature in existing database
    final Map<String, int> existingSignatureCounts = {};
    for (final t in existing) {
      existingSignatureCounts[t.signature] = (existingSignatureCounts[t.signature] ?? 0) + 1;
    }

    final Map<String, int> currentFileSignatureCounts = {};
    final List<ParsedStatementItem> parsedItems = [];
    int newCount = 0;
    int duplicateCount = 0;
    double newIncome = 0;
    double newExpense = 0;

    for (final tx in extracted) {
      final sig = tx.signature;
      final currentCount = currentFileSignatureCounts[sig] ?? 0;
      final existingCount = existingSignatureCounts[sig] ?? 0;

      // Duplicate ONLY if this occurrence is already in the database
      final isDuplicate = currentCount < existingCount;
      currentFileSignatureCounts[sig] = currentCount + 1;

      String? reason;
      if (isDuplicate) {
        reason = 'Bu işlem daha önce kaydedilmiş.';
        duplicateCount++;
      } else {
        newCount++;
        if (tx.type == TransactionType.income) {
          newIncome += tx.amount;
        } else {
          newExpense += tx.amount;
        }
      }

      parsedItems.add(
        ParsedStatementItem(
          transaction: tx,
          isDuplicate: isDuplicate,
          duplicateReason: reason,
          isSelected: !isDuplicate,
        ),
      );
    }

    return StatementParseResult(
      items: parsedItems,
      totalCount: extracted.length,
      newCount: newCount,
      duplicateCount: duplicateCount,
      totalNewIncome: newIncome,
      totalNewExpense: newExpense,
      detectedFormat: format,
      rawExtractedText: rawText,
      officialClosingBalance: officialClosingBalance,
      officialPeriodDebt: officialPeriodDebt,
      officialDueDate: officialDueDate,
      officialMinPayment: officialMinPayment,
      isCreditCard: isCreditCard,
    );
  }

  static List<TransactionModel> _parseCsvLines(List<String> lines) {
    final List<TransactionModel> result = [];
    if (lines.isEmpty) return result;

    final delimiter = lines.first.contains(';') ? ';' : ',';

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || _isNoiseOrSummaryLine(line)) continue;

      final columns = line.split(delimiter).map((c) => c.replaceAll('"', '').trim()).toList();
      if (columns.length < 3) continue;

      DateTime? date;
      double? amount;
      String title = '';
      bool isIncome = false;
      bool isCashWithdrawal = false;

      // Date
      for (final col in columns) {
        final parsedDate = _tryParseDate(col);
        if (parsedDate != null && date == null) {
          date = parsedDate;
          break;
        }
      }

      // Amount (from right to left)
      for (int c = columns.length - 1; c >= 0; c--) {
        final parsedAmount = _tryParseAmount(columns[c]);
        if (parsedAmount != null && amount == null) {
          amount = parsedAmount.abs();
          if (parsedAmount > 0 && (columns[c].contains('+') || line.toLowerCase().contains('alacak') || line.toLowerCase().contains('gelen'))) {
            isIncome = true;
          }
          break;
        }
      }

      // Title
      for (final col in columns) {
        if (_tryParseDate(col) == null && _tryParseAmount(col) == null && col.length > 2) {
          title = col;
          break;
        }
      }

      if (title.isEmpty && columns.length > 1) {
        title = columns[1];
      }

      if (amount != null && amount > 0 && amount < 10000000) {
        date ??= DateTime.now();
        if (title.isEmpty) title = 'Banka İşlemi';

        final upper = title.toUpperCase();
        if (upper.contains('ATM') || upper.contains('NAKİT') || upper.contains('NAKIT') || upper.contains('PARA ÇEKME') || upper.contains('PARA CEKME')) {
          isCashWithdrawal = true;
        } else if (upper.contains('MAAŞ') || upper.contains('MAAS') || upper.contains('GELEN EFT') || upper.contains('GELEN HAVALE')) {
          isIncome = true;
        }

        final categoryId = autoClassifyCategory(title, isIncome, isCashWithdrawal);

        result.add(
          TransactionModel(
            id: const Uuid().v4(),
            title: title,
            amount: amount,
            type: isCashWithdrawal
                ? TransactionType.cashWithdrawal
                : (isIncome ? TransactionType.income : TransactionType.expense),
            categoryId: categoryId,
            date: date,
            paymentMethod: isCashWithdrawal ? PaymentMethod.cash : PaymentMethod.bankCard,
            sourceWalletId: 'wallet_bank',
            targetWalletId: isCashWithdrawal ? 'wallet_cash' : null,
          ),
        );
      }
    }

    return result;
  }

  static List<TransactionModel> _parseGenericTextLines(List<String> rawLines, {bool isCreditCard = false}) {
    final List<TransactionModel> result = [];

    // Regex for Turkish and numeric dates (requires valid day 1-31, month 1-12, and 2-4 digit year)
    final dateNumericRegex = RegExp(r'^\s*(0?[1-9]|[12][0-9]|3[01])[./\-](0?[1-9]|1[0-2])[./\-](\d{4}|\d{2})\b');
    final dateTurkishRegex = RegExp(
      r'^\s*(\d{1,2})\s+(Ocak|Şubat|Subat|Mart|Nisan|Mayıs|Mayis|Haziran|Temmuz|Ağustos|Agustos|A\s*ustos|Eylül|Eylul|Ekim|Kasım|Kasim|Aralık|Aralik|Oca|Şub|Sub|Mar|Nis|May|Haz|Tem|Ağu|Agu|Eyl|Eki|Kas|Ara)(?:\s+(\d{2,4}))?',
      caseSensitive: false,
    );

    // Multi-line / Wrapped-line Reconstruction
    final List<String> lines = [];
    String currentBuffer = '';

    for (final rawLine in rawLines) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty) continue;

      final hasDate = dateTurkishRegex.hasMatch(trimmed) || dateNumericRegex.hasMatch(trimmed);

      if (!hasDate && _isNoiseOrSummaryLine(trimmed)) {
        if (currentBuffer.isNotEmpty) {
          lines.add(currentBuffer);
          currentBuffer = '';
        }
        continue;
      }

      if (hasDate) {
        if (currentBuffer.isNotEmpty) {
          lines.add(currentBuffer);
        }
        currentBuffer = trimmed;
      } else {
        if (currentBuffer.isNotEmpty) {
          currentBuffer = '$currentBuffer $trimmed';
        } else {
          lines.add(trimmed);
        }
      }
    }
    if (currentBuffer.isNotEmpty) {
      lines.add(currentBuffer);
    }

    // Regex for amounts with optional sign: e.g. 6.666,68 or 84.752,00+ or 1,26-
    final amountRegex = RegExp(
      r'([+\-]?\s*\d{1,3}(?:\.\d{3})*(?:,\d{1,2})[+\-]?|[+\-]?\s*\d+(?:[.,]\d{1,2})[+\-]?)',
    );

    for (final line in lines) {
      final lineHasDate = dateTurkishRegex.hasMatch(line) || dateNumericRegex.hasMatch(line);
      if (line.isEmpty || (!lineHasDate && _isNoiseOrSummaryLine(line))) continue;

      DateTime? date;
      String remainingText = line;

      // 1. Try match date at beginning or within line
      final trMatch = dateTurkishRegex.firstMatch(line);
      final numMatch = dateNumericRegex.firstMatch(line);

      if (trMatch != null) {
        date = _parseTurkishDateMatch(trMatch);
        remainingText = line.replaceFirst(trMatch.group(0)!, '').trim();
      } else if (numMatch != null) {
        date = _tryParseDate(numMatch.group(0)!);
        remainingText = line.replaceFirst(numMatch.group(0)!, '').trim();
      } else {
        continue;
      }

      if (date == null) continue;

      // 2. Look for amounts in remaining text
      double? finalAmount;
      bool isIncome = false;
      String matchedAmountRaw = '';

      final amountMatches = amountRegex.allMatches(remainingText).toList();
      if (amountMatches.isEmpty) continue;

      // 2a. Priority 1: Check if there is an explicitly signed amount (+ or -)
      // In Turkish bank account statements (Hesap Hareketleri), Tutar is signed (+10.000,00 or -826,00)
      // while Bakiye (Balance) is unsigned (130.923,15 TL).
      Match? signedMatch;
      for (int i = 0; i < amountMatches.length; i++) {
        final rawVal = amountMatches[i].group(0)?.trim() ?? '';
        if (rawVal.contains('+') || rawVal.contains('-')) {
          signedMatch = amountMatches[i];
          break;
        }
      }

      if (signedMatch != null) {
        final rawVal = signedMatch.group(0)?.trim() ?? '';
        final parsed = _tryParseAmount(rawVal);
        if (parsed != null && parsed > 0 && parsed < 100000000) {
          finalAmount = parsed;
          matchedAmountRaw = rawVal;
          if (rawVal.contains('+')) {
            isIncome = true;
          }
        }
      }

      // 2b. Priority 2: If no signed amount, take the last matched amount (Credit card statement behavior)
      if (finalAmount == null) {
        for (int i = amountMatches.length - 1; i >= 0; i--) {
          final m = amountMatches[i];
          final rawVal = m.group(0)?.trim() ?? '';
          final parsed = _tryParseAmount(rawVal);

          if (parsed != null && parsed > 0 && parsed < 100000000) {
            finalAmount = parsed;
            matchedAmountRaw = rawVal;
            if (rawVal.endsWith('+') || rawVal.startsWith('+')) {
              isIncome = true;
            }
            break;
          }
        }
      }

      if (finalAmount == null || finalAmount <= 0) continue;

      // 3. Extract and clean Title
      String title = remainingText;

      // Remove the matched amount from title
      if (matchedAmountRaw.isNotEmpty) {
        final lastIdx = title.lastIndexOf(matchedAmountRaw);
        if (lastIdx != -1) {
          if (signedMatch != null) {
            // Drop everything after the signed transaction amount (which is the running balance 'Bakiye' column)
            title = title.substring(0, lastIdx).trim();
          } else {
            title = title.substring(0, lastIdx) + title.substring(lastIdx + matchedAmountRaw.length);
          }
        }
      }

      // Check for installment note e.g. "1.Taksit", "(1/3)", "(2/6)", "3 Taksit", "6.666,68x3=20.000,00 1.Taksit"
      String installmentNote = '';
      final taksitMatch = RegExp(
        r'(\d+[\.,]\d+x\d+=\d+[\.,]\d+\s+\d+\.Taksit|\d+\.Taksit|\(\s*\d+\s*/\s*\d+\s*(?:Taksit)?\s*\)|\b\d+\s*/\s*\d+\s+Taksit\b|\b\d+\s+Taksit\b)',
        caseSensitive: false,
      ).firstMatch(title);
      if (taksitMatch != null) {
        final taksitText = taksitMatch.group(0)!;
        installmentNote = ' ($taksitText)'.replaceAll('((', '(').replaceAll('))', ')');
        title = title.replaceFirst(taksitText, '').trim();
      }

      // Remove bank column tags and city names from right of title: e.g. "İSTANBUL Market", "İSTANBUL Sağlık / Bakım", "ANKARA Vergi", "Kurum Ödemesi", "Alışveriş"
      title = title.replaceAll(RegExp(r'\s*(İSTANBUL|ISTANBUL|ANKARA|BURSA|İZMİR|IZMIR|MSBILL\.INFO)?\s*(Market|Sağlık / Bakım|Saglik / Bakim|Yeme / İçme|Yeme / Icme|Ev / Dekorasyon|Giyim / Aksesuar|Eğlence / Hobi|Eglence / Hobi|Vergi|Diğer|Diger|Alışveriş|Alısveris|Kurum Ödemesi|Para Transferi|Para Çekme|Para Yatırma|Kart Ödemesi|Kart Odemesi|Faiz / Komisyon|Faiz/Komisyon)\s*$', caseSensitive: false), '').trim();
      title = title.replaceAll(RegExp(r'\s*(Kurum Ödemesi|Para Transferi|Para Çekme|Para Yatırma|Alışveriş|Alısveris|Kart Ödemesi|Kart Odemesi|Faiz / Komisyon|Faiz/Komisyon|Diğer|Diger)\s*$', caseSensitive: false), '').trim();

      // Remove bonus amount columns e.g. "10,00", "0,10", "1,80" from right of title
      title = title.replaceAll(RegExp(r'\s+\d{1,3}(?:,\d{1,2})[+\-]?\s*$'), '').trim();

      // Clean special characters and whitespace
      title = title
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'^[|;\-,/.\s]+|[|;\-,/.\s]+$'), '')
          .trim();

      if (title.isEmpty) {
        title = 'Banka Harcaması';
      }

      final upper = title.toUpperCase();

      // Ignore credit card payment receipt lines (e.g. "Ödemeniz için teşekkür ederiz")
      // These are NOT income! They are just credit card payment receipts and already deducted from bank account.
      if (upper.contains('ÖDEMENİZ İÇİN TEŞEKKÜR') ||
          upper.contains('ODEMENIZ ICIN TESEKKUR') ||
          upper.contains('HESAPTAN ÖDEME') ||
          upper.contains('HESAPTAN ODEME') ||
          upper.contains('DİREKT ÖDEME') ||
          upper.contains('DIREKT ODEME') ||
          upper.contains('İŞCEP') ||
          upper.contains('ISCEP') ||
          upper.contains('AKBANK DİREKT') ||
          upper.contains('MOBİL ŞUBE ÖDEME') ||
          upper.contains('MOBIL SUBE ODEME') ||
          upper.contains('ÖDEMEN Z Ç N TE EKKÜR') ||
          upper.contains('ODEMEN Z C N TE EKKUR')) {
        continue;
      } else if (upper.contains('PARA YATIRMA') ||
          upper.contains('PARA YATIR') ||
          upper.contains('GELEN EFT') ||
          upper.contains('GELEN HAVALE') ||
          upper.contains('GELEN TRANSFER') ||
          upper.contains('FAST GELEN') ||
          upper.contains('HESABA GELEN') ||
          upper.contains('MAAŞ') ||
          upper.contains('MAAS') ||
          upper.contains('BORDR') ||
          upper.contains('BURS') ||
          upper.contains('KYK') ||
          upper.contains('FAİZ GELİRİ') ||
          upper.contains('FON SATIŞ') ||
          upper.contains('DÖVİZ BOZMA') ||
          upper.contains('NEMA') ||
          upper.contains('TEMETTÜ') ||
          upper.contains('KÂR PAYI') ||
          upper.contains('KAR PAYI') ||
          upper.contains('KATILMA HESABI') ||
          upper.contains('HEDİYE PARA') ||
          upper.contains('HEDIYE PARA') ||
          upper.contains('HESABA PARA YATIRMA') ||
          upper.contains('KASADAN YATIRILAN') ||
          upper.contains('AYIN ENPARALISI KAZANCI') ||
          upper.contains('(ALACAK)') ||
          upper.contains(' ALACAK') ||
          upper.contains('(A)')) {
        isIncome = true;
      } else if (upper.contains('İADE') || upper.contains('IADE')) {
        if (!title.toLowerCase().contains('iade') && !title.toLowerCase().contains('ödeme')) {
          title = '$title (İade)';
        }
        isIncome = true;
      } else {
        title = '$title$installmentNote';
      }

      // Cash withdrawal: MUST be explicitly withdrawing cash (NOT depositing cash)
      final bool isCash = (upper.contains('PARA ÇEKME') ||
              upper.contains('PARA CEKME') ||
              upper.contains('NAKİT ÇEK') ||
              upper.contains('NAKIT CEK') ||
              upper.contains('P.ÇEKME') ||
              upper.contains('P.CEKME')) &&
          !upper.contains('YATIRMA');

      if (isCash) isIncome = false;

      final catId = autoClassifyCategory(title, isIncome, isCash);

      result.add(
        TransactionModel(
          id: const Uuid().v4(),
          title: title,
          amount: finalAmount,
          type: isCash
              ? TransactionType.cashWithdrawal
              : (isIncome ? TransactionType.income : TransactionType.expense),
          categoryId: catId,
          date: date,
          paymentMethod: isCash
              ? PaymentMethod.cash
              : (isCreditCard ? PaymentMethod.creditCard : PaymentMethod.bankCard),
          sourceWalletId: isCash
              ? 'wallet_cash'
              : (isCreditCard ? 'wallet_credit' : 'wallet_bank'),
          targetWalletId: isCash ? 'wallet_cash' : null,
        ),
      );
    }

    return result;
  }

  /// Filters out statement headers, legal text, summaries, card info and noise
  static bool _isNoiseOrSummaryLine(String line) {
    final u = line.toUpperCase();

    // Summary numbers, card limits, header banners (Multi-bank: Garanti, İş, Yapı Kredi, Akbank, Enpara, Ziraat, QNB, Vakıf, Halk)
    if (u.startsWith('TOPLAM') ||
        u.contains('TOPLAM BORCUNUZ') ||
        u.contains('TOPLAM BORÇ') ||
        u.contains('TOPLAM BORC') ||
        u.contains('TOPLAM TUTAR') ||
        u.contains('TOPLAM HARCAMA') ||
        u.contains('DEVREDEN BAKİYE') ||
        u.contains('DEVREDEN BAKIYE') ||
        u.contains('ÖNCEKİ DÖNEMDEN DEVİR') ||
        u.contains('ONCEKI DONEMDEN DEVIR') ||
        u.contains('ÖNCEKİ BAKİYE') ||
        u.contains('ONCEKI BAKIYE') ||
        u.contains('ÖNCEKİ DÖNEM BORCU') ||
        u.contains('ONCEKI DONEM BORCU') ||
        u.contains('HESAP ÖZETİ BORCU') ||
        u.contains('HESAP OZETI BORCU') ||
        u.contains('DÖNEM BORCU') ||
        u.contains('DONEM BORCU') ||
        u.contains('DÖNEM BORCUNUZ') ||
        u.contains('DONEM BORCUNUZ') ||
        u.contains('ASGARİ ÖDEME') ||
        u.contains('ASGARI ODEME') ||
        u.contains('MİN. ÖDEME') ||
        u.contains('MIN. ODEME') ||
        u.contains('MİNİMUM ÖDEME') ||
        u.contains('MINIMUM ODEME') ||
        u.contains('ÖDEMENİZ İÇİN TEŞEKKÜR') ||
        u.contains('ODEMENIZ ICIN TESEKKUR') ||
        u.contains('ÖDEMEN Z Ç N TE EKKÜR') ||
        u.contains('ODEMEN Z C N TE EKKUR') ||
        u.contains('HESAP KESİM TARİHİ') ||
        u.contains('HESAP KESIM TARIHI') ||
        u.contains('SON ÖDEME TARİHİ') ||
        u.contains('SON ODEME TARIHI') ||
        u.contains('DÖNEM HARCAMALARI') ||
        u.contains('DONEM HARCAMALARI') ||
        u.contains('FAİZ VE ÜCRETLER') ||
        u.contains('FAIZ VE UCRETLER') ||
        u.contains('DÖNEM FAİZİ') ||
        u.contains('DONEM FAIZI') ||
        u.contains('KKDF + BSMV') ||
        u.contains('GECİKME FAİZİ') ||
        u.contains('GECIKME FAIZI') ||
        u.contains('AKDİ FAİZ') ||
        u.contains('AKDI FAIZ') ||
        u.contains('KULLANILABİLİR LİMİT') ||
        u.contains('KULLANILABILIR LIMIT') ||
        u.contains('KULLANILABİLİR KART LİMİTİ') ||
        u.contains('KART LİMİTİ') ||
        u.contains('KART LIMITI') ||
        u.contains('MÜŞTERİ LİMİTİ') ||
        u.contains('MUSTERI LIMITI') ||
        u.contains('NAKİT AVANS LİMİTİ') ||
        u.contains('NAKIT AVANS LIMITI') ||
        u.contains('EKSTRE NO') ||
        u.contains('EKSTRE SAYFASI') ||
        u.contains('EKSTRE ÖZETİ') ||
        u.contains('EKSTRE OZETI') ||
        u.contains('EKSTRE ÖZET') ||
        u.contains('EKSTRENİZ İLE İLGİLİ') ||
        u.contains('EKSTRENIZ ILE ILGILI') ||
        u.contains('MÜŞTERİ NUMARASI') ||
        u.contains('MUSTERI NUMARASI') ||
        u.contains('KART NUMARASI') ||
        // Bank loyalty points / miles
        u.contains('BUGÜNE KADAR KAZANILAN') ||
        u.contains('BU DÖNEM KAZANILAN') ||
        u.contains('BU DÖNEM HARCANAN') ||
        u.contains('HARCANABİLECEK TOPLAM') ||
        u.contains('HARCANABİLİR BONUS') ||
        u.contains('HARCANABILIR BONUS') ||
        u.contains('HARCANABİLECEK BONUS') ||
        u.contains('BONUS TRİNK') ||
        u.contains('BONUS TRINK') ||
        u.contains('MAXİPUAN') ||
        u.contains('MAXIPUAN') ||
        u.contains('MAXİ MİL') ||
        u.contains('MAXI MIL') ||
        u.contains('WORLDPUAN') ||
        u.contains('WORLD PUAN') ||
        u.contains('CHİP-PARA') ||
        u.contains('CHIP-PARA') ||
        u.contains('CHIP PARA') ||
        u.contains('BANKKART LİRA') ||
        u.contains('BANKKART LIRA') ||
        u.contains('PARAPUAN') ||
        u.contains('PARA PUAN') ||
        u.contains('PARAFPARA') ||
        u.contains('PARAF PARA') ||
        // All 35 Turkish Banks Official Corporate Headers & Footers
        u.contains('GENEL MÜDÜRLÜK') ||
        u.contains('GENEL MUDURLUK') ||
        u.contains('GENEL MÜDÜRLÜĞÜ') ||
        u.contains('GENEL MUDURLUGU') ||
        u.contains('MERSİS NUMARASI') ||
        u.contains('MERSIS NUMARASI') ||
        u.contains('BÜYÜK MÜKELLEFLER') ||
        u.contains('BUYUK MUKELLEFLER') ||
        u.contains('HESAP ÖZETİ') ||
        u.contains('HESAP OZETI') ||
        u.contains('T.A.Ş.') ||
        u.contains('A.Ş.') ||
        u.contains('A.S.') ||
        u.contains('T.A.O.') ||
        // Bank official domains
        u.contains('.COM.TR') ||
        u.contains('AKBANK.COM') ||
        u.contains('ISBANK.COM') ||
        u.contains('YAPIKREDI.COM') ||
        u.contains('GARANTI.COM') ||
        u.contains('ZIRAAT.COM') ||
        u.contains('HALKBANK.COM') ||
        u.contains('VAKIFBANK.COM') ||
        u.contains('DENIZBANK.COM') ||
        u.contains('QNB.COM') ||
        u.contains('TEB.COM') ||
        u.contains('ING.COM') ||
        u.contains('ENPARA.COM') ||
        u.contains('ALBARAKA.COM') ||
        u.contains('KUVEYTTURK.COM') ||
        u.contains('HSBC.COM') ||
        // General statement notices
        u.contains('GELECEK DÖNEM TAKSİTLERİ') ||
        u.contains('GELECEK DONEM TAKSITLERI') ||
        u.contains('HARCAMALARINIZIN DAĞILIMI') ||
        u.contains('HARCAMALARINIZIN DAGILIMI') ||
        u.startsWith('SAYIN ') ||
        u.contains('ERGENEKON MAH') ||
        u.contains('HALASKARGAZİ') ||
        u.contains('HALASKARGAZI') ||
        u.contains('HİDAYET SOK') ||
        u.contains('HIDAYET SOK')) {
      return true;
    }

    // Category Section Headers in statement
    if (u == 'HEDİYELİK EŞYA/CAM,PORSELEN ÜRÜNLERİ' ||
        u == 'SPOR GİYİM' ||
        u == 'SPOR GIYIM' ||
        u == 'CAFE & RESTAURANT' ||
        u == 'SÜPERMARKET' ||
        u == 'SUPERMARKET' ||
        u == 'FAST FOOD' ||
        u == 'PASTANE' ||
        u == 'ULAŞIM' ||
        u == 'ULASIM' ||
        u == 'DİĞER HARCAMALARINIZ' ||
        u == 'DIGER HARCAMALARINIZ') {
      return true;
    }

    return false;
  }

  static DateTime? _parseTurkishDateMatch(Match match) {
    try {
      final day = int.parse(match.group(1)!);
      var monthStr = match.group(2)!.toLowerCase().replaceAll(' ', '');
      if (monthStr.startsWith('a') && monthStr.endsWith('ustos')) monthStr = 'ağustos';

      int year = DateTime.now().year;
      if (match.group(3) != null) {
        year = int.parse(match.group(3)!);
        if (year < 100) year += 2000;
      }
      final month = _turkishMonths[monthStr];

      if (month != null && day >= 1 && day <= 31) {
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }

  static DateTime? _tryParseDate(String input) {
    try {
      final clean = input.trim();
      final parts = clean.split(RegExp(r'[./\-]'));
      if (parts.length >= 2) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = DateTime.now().year;

        if (parts.length == 3) {
          year = int.parse(parts[2]);
          if (parts[0].length == 4) {
            year = int.parse(parts[0]);
            month = int.parse(parts[1]);
            day = int.parse(parts[2]);
          } else if (year < 100) {
            year += 2000;
          }
        }

        if (day >= 1 && day <= 31 && month >= 1 && month <= 12) {
          return DateTime(year, month, day);
        }
      }
    } catch (_) {}
    return null;
  }

  static double? _tryParseAmount(String input) {
    try {
      String clean = input
          .replaceAll('TL', '')
          .replaceAll('₺', '')
          .replaceAll('TRY', '')
          .replaceAll('+', '')
          .replaceAll('-', '')
          .replaceAll(' ', '')
          .trim();

      if (clean.isEmpty) return null;

      if (clean.contains(',') && clean.contains('.')) {
        if (clean.lastIndexOf(',') > clean.lastIndexOf('.')) {
          clean = clean.replaceAll('.', '').replaceAll(',', '.');
        } else {
          clean = clean.replaceAll(',', '');
        }
      } else if (clean.contains(',')) {
        clean = clean.replaceAll(',', '.');
      }

      final val = double.tryParse(clean);
      return val;
    } catch (_) {}
    return null;
  }

  static String autoClassifyCategory(String title, bool isIncome, bool isCash) {
    if (isCash) return 'nakit_cekildi';
    if (isIncome) {
      final u = title.toUpperCase();
      if (u.contains('MAAŞ') || u.contains('MAAS') || u.contains('BORDR')) return 'maas';
      if (u.contains('KİRA') || u.contains('KIRA')) return 'kira_gelir';
      if (u.contains('FAİZ') || u.contains('TEMETTÜ') || u.contains('FON') || u.contains('KÂR PAYI') || u.contains('KAR PAYI')) return 'yatirim';
      return 'ek_gelir';
    }

    final upper = title.toUpperCase();

    // 1. Online E-Commerce Shopping Platforms (Must be checked before general "Market" keyword)
    if (upper.contains('AMAZON') ||
        upper.contains('TRENDYOL') ||
        upper.contains('HEPSİBURADA') ||
        upper.contains('HEPSIBURADA') ||
        upper.contains('HEPSİPAY') ||
        upper.contains('HEPSIPAY') ||
        upper.contains('IYZICO') ||
        upper.contains('N KOLAY') ||
        upper.contains('N11') ||
        upper.contains('ÇİÇEKSEPETİ') ||
        upper.contains('CICEKSEPETI') ||
        upper.contains('PAZARAMA')) {
      return 'alisveris';
    }

    // 2. Clothing & Accessories
    if (upper.contains('ZARA') ||
        upper.contains('LCW') ||
        upper.contains('MAVI') ||
        upper.contains('MAVİ') ||
        upper.contains('BOYNER') ||
        upper.contains('H&M') ||
        upper.contains('KOTON') ||
        upper.contains('DEFACTO') ||
        upper.contains('GIYIM') ||
        upper.contains('GİYİM') ||
        upper.contains('PENTİ') ||
        upper.contains('PENTI') ||
        upper.contains('DECATHLON') ||
        upper.contains('AYAKKABI') ||
        upper.contains('FLO') ||
        upper.contains('BTM MAĞAZALARI') ||
        upper.contains('PULL&BEAR') ||
        upper.contains('BERSHKA') ||
        upper.contains('STRADIVARIUS') ||
        upper.contains('MANGO') ||
        upper.contains('TOUCHEPRIVE') ||
        upper.contains('TOUCHÉ') ||
        upper.contains('DERİMOD') ||
        upper.contains('BEYMEN') ||
        upper.contains('NETWORK') ||
        upper.contains('İPEKYOL') ||
        upper.contains('IPEK YOL') ||
        upper.contains('TWIST') ||
        upper.contains('COLIN') ||
        upper.contains('KİĞILI') ||
        upper.contains('KIGILI') ||
        upper.contains('SARAR') ||
        upper.contains('D\'S DAMAT') ||
        upper.contains('SÜVARİ') ||
        upper.contains('SUVARI') ||
        upper.contains('TERGAN') ||
        upper.contains('KEMAL TANCA') ||
        upper.contains('YARGICI') ||
        upper.contains('ÇANTA') ||
        upper.contains('CANTA') ||
        upper.contains('AKSESUAR') ||
        upper.contains('CEP AKSESUAR')) {
      return 'giyim';
    }

    // 3. Personal Care & Cosmetics
    if (upper.contains('GRATIS') ||
        upper.contains('GRATİS') ||
        upper.contains('WATSONS') ||
        upper.contains('WATSOON') ||
        upper.contains('ROSSMANN') ||
        upper.contains('SEPHORA') ||
        upper.contains('KOZMETIK') ||
        upper.contains('KOZMETİK') ||
        upper.contains('KUAFÖR') ||
        upper.contains('KUAFOR') ||
        upper.contains('BERBER')) {
      return 'kisisel_bakim';
    }

    if (upper.contains('MUZ') || upper.contains('MANAV') || upper.contains('MEYVE') || upper.contains('SEBZE') || upper.contains('PAZAR')) {
      return 'manav';
    }
    if (upper.contains('MIGROS') ||
        upper.contains('MİGROS') ||
        upper.contains('M GROS') ||
        upper.contains('A101') ||
        upper.contains('BIM') ||
        upper.contains('BİM') ||
        upper.contains('B M-') ||
        upper.contains('SOK') ||
        upper.contains('ŞOK') ||
        upper.contains('OK-') ||
        upper.contains('CARREFOUR') ||
        upper.contains('TARIM KREDİ') ||
        upper.contains('TARIM KREDI') ||
        upper.contains('FILE MARKET') ||
        upper.contains('FİLE MARKET') ||
        upper.contains('HAPPY CENTER') ||
        upper.contains('BAKKAL') ||
        upper.contains('GIDA') ||
        upper.contains('FIRIN') ||
        upper.contains('KASAP') ||
        upper.contains('HIPER') ||
        upper.contains('MARKET')) {
      return 'market';
    }
    if (upper.contains('FATURA') ||
        upper.contains('TURKNET') ||
        upper.contains('TURKCELL') ||
        upper.contains('VODAFONE') ||
        upper.contains('TELEKOM') ||
        upper.contains('ENERJISA') ||
        upper.contains('ENERJİSA') ||
        upper.contains('IGDAS') ||
        upper.contains('İGDAŞ') ||
        upper.contains('IGDAŞ') ||
        upper.contains('ISKI') ||
        upper.contains('İSKİ') ||
        upper.contains('BEDAŞ') ||
        upper.contains('BEDAS') ||
        upper.contains('AYEDAŞ') ||
        upper.contains('AYEDAS') ||
        upper.contains('CK BOĞAZİÇİ') ||
        upper.contains('GDZ ELEKTRİK') ||
        upper.contains('BAŞKENT') ||
        upper.contains('İZSU') ||
        upper.contains('ASKİ') ||
        upper.contains('BUSKİ') ||
        upper.contains('TÜRKSAT') ||
        upper.contains('KABLONET') ||
        upper.contains('D-SMART') ||
        upper.contains('DOGALGAZ') ||
        upper.contains('DOĞALGAZ') ||
        upper.contains('ELEKTRIK') ||
        upper.contains('ELEKTRİK') ||
        upper.contains('SU FATURA') ||
        upper.contains('SU İDARESİ') ||
        upper.contains('SU IDARESI') ||
        upper.contains('SU VE KANAL') ||
        upper.contains(' SU ')) {
      return 'fatura';
    }
    if (upper.contains('KIRA') ||
        upper.contains('KİRA') ||
        upper.contains('AIDAT') ||
        upper.contains('AİDAT') ||
        upper.contains('SITE') ||
        upper.contains('IKEA') ||
        upper.contains('VIVENSE') ||
        upper.contains('VİVENSE') ||
        upper.contains('ALTUN BRODE') ||
        upper.contains('ENGLISH HOME') ||
        upper.contains('KARACA') ||
        upper.contains('MADAME COCO') ||
        upper.contains('ENZA') ||
        upper.contains('BELLONA') ||
        upper.contains('YATAŞ') ||
        upper.contains('KORKMAZ') ||
        upper.contains('TEFAL') ||
        upper.contains('ÇEYİZ') ||
        upper.contains('CEYIZ')) {
      return 'kira';
    }
    if (upper.contains('PETROL') ||
        upper.contains('OPET') ||
        upper.contains('SHELL') ||
        upper.contains('BP') ||
        upper.contains('TOTAL') ||
        upper.contains('PETROL OFİSİ') ||
        upper.contains('PETROL OFISI') ||
        upper.contains('AYGAZ') ||
        upper.contains('TRAKPET') ||
        upper.contains('MEMOCAN') ||
        upper.contains('BENZIN') ||
        upper.contains('MAZOT') ||
        upper.contains('AKARYAKIT') ||
        upper.contains('OTOPARK') ||
        upper.contains('UBER') ||
        upper.contains('BİTAKSİ') ||
        upper.contains('BITAKSI') ||
        upper.contains('TAKSİ ') ||
        upper.contains('TAKSI ') ||
        upper.contains('TAXI') ||
        upper.contains('MARTI') ||
        upper.contains('BINBIN') ||
        upper.contains('TCDD') ||
        upper.contains('TRENITALIA') ||
        upper.contains('THY') ||
        upper.contains('PEGASUS') ||
        upper.contains('AJET') ||
        upper.contains('ISTANBULKART') ||
        upper.contains('BELBIM') ||
        upper.contains('BELBİM') ||
        upper.contains('TOPLU TASIMA') ||
        upper.contains('OTOBUS') ||
        upper.contains('METRO') ||
        upper.contains('MARMARAY') ||
        upper.contains('RENT') ||
        upper.contains('FILO') ||
        upper.contains('ENUYGUN')) {
      return 'ulasim';
    }
    if (upper.contains('ECZANE') ||
        upper.contains('HASTANE') ||
        upper.contains('SAGLIK') ||
        upper.contains('SAĞLIK') ||
        upper.contains('DOKTOR') ||
        upper.contains('DT ') ||
        upper.contains('DİŞ') ||
        upper.contains('DIS') ||
        upper.contains('AĞIZ') ||
        upper.contains('AGIZ') ||
        upper.contains('KLİNİK') ||
        upper.contains('KLINIK') ||
        upper.contains('MEDIKAL') ||
        upper.contains('MEDİKAL') ||
        upper.contains('OPTİK') ||
        upper.contains('OPTIK') ||
        upper.contains('SUPPLEMENTLER')) {
      return 'saglik';
    }
    if (upper.contains('RESTORAN') ||
        upper.contains('KAFE') ||
        upper.contains('CAFE') ||
        upper.contains('CAFFE') ||
        upper.contains('KAHVE') ||
        upper.contains('STARBUCKS') ||
        upper.contains('ESPRESSOLAB') ||
        upper.contains('GETIR') ||
        upper.contains('GETİR') ||
        upper.contains('YEMEKSEPETI') ||
        upper.contains('YEMEK SEPETİ') ||
        upper.contains('YEMEK') ||
        upper.contains('YİYECEK') ||
        upper.contains('YIYECEK') ||
        upper.contains('İÇECEK') ||
        upper.contains('ICECEK') ||
        upper.contains('TANTUNI') ||
        upper.contains('TANTUNİ') ||
        upper.contains('KEBAP') ||
        upper.contains('DÖNER') ||
        upper.contains('DONER') ||
        upper.contains('KÖFTECİ YUSUF') ||
        upper.contains('KOFTECI YUSUF') ||
        upper.contains('TAVUK DÜNYASI') ||
        upper.contains('HD İSKENDER') ||
        upper.contains('PİLAV') ||
        upper.contains('PILAV') ||
        upper.contains('KÜNEFE') ||
        upper.contains('KUNEFE') ||
        upper.contains('MC DONALDS') ||
        upper.contains('BURGER') ||
        upper.contains('PIZZA') ||
        upper.contains('PİZZA') ||
        upper.contains('DOMINOS') ||
        upper.contains('BELTUR') ||
        upper.contains('PİDE') ||
        upper.contains('PIDE') ||
        upper.contains('MİKEL') ||
        upper.contains('MIKEL') ||
        upper.contains('HAFIZ MUSTAFA') ||
        upper.contains('VİYANA KAHVESİ') ||
        upper.contains('NETFLIX') ||
        upper.contains('SPOTIFY') ||
        upper.contains('YOUTUBE') ||
        upper.contains('DISNEY') ||
        upper.contains('APPLE.COM') ||
        upper.contains('STEAM') ||
        upper.contains('CINEMA') ||
        upper.contains('SİNEMA')) {
      return 'eglence';
    }
    if (upper.contains('GRATIS') ||
        upper.contains('GRATİS') ||
        upper.contains('WATSONS') ||
        upper.contains('WATSOON') ||
        upper.contains('ROSSMANN') ||
        upper.contains('SEPHORA') ||
        upper.contains('KOZMETIK') ||
        upper.contains('KOZMETİK') ||
        upper.contains('KUAFÖR') ||
        upper.contains('KUAFOR') ||
        upper.contains('BERBER')) {
      return 'kisisel_bakim';
    }
    if (upper.contains('EMİN EVİM') ||
        upper.contains('EMIN EVIM') ||
        upper.contains('EMİNEVİM') ||
        upper.contains('EMINEVIM') ||
        upper.contains('TASARRUF FİNANS') ||
        upper.contains('TASARRUF FINANS') ||
        upper.contains('FUZUL') ||
        upper.contains('BİREVİM') ||
        upper.contains('BIREVIM') ||
        upper.contains('KATILIMEV')) {
      return 'birikim';
    }

    if (upper.contains('KREŞ') ||
        upper.contains('KRES') ||
        upper.contains('OKUL') ||
        upper.contains('KURS') ||
        upper.contains('KIRTASİYE') ||
        upper.contains('KITAP') ||
        upper.contains('KİTAP') ||
        upper.contains('EGITIM') ||
        upper.contains('EĞİTİM') ||
        upper.contains('ÖLÇME SEÇME') ||
        upper.contains('OLCME SECME') ||
        upper.contains('ENNOVA ÇOCUK') ||
        upper.contains('D&R') ||
        upper.contains('KÜLTÜR')) {
      return 'egitim';
    }

    return 'diger_gider';
  }
}
