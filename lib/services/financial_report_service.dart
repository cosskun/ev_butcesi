import 'dart:io';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../core/utils/formatters.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

class MonthlyHealthSummary {
  final DateTime period;
  final int healthScore; // 0 - 100
  final String statusTitle;
  final String statusDescription;
  final double totalIncome;
  final double totalExpense;
  final double netSavings;
  final double savingsRate; // %
  final List<MapEntry<CategoryModel, double>> topCategories;
  final List<TransactionModel> topExpenses;
  final double installmentTotal;
  final double subscriptionTotal;

  const MonthlyHealthSummary({
    required this.period,
    required this.healthScore,
    required this.statusTitle,
    required this.statusDescription,
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.savingsRate,
    required this.topCategories,
    required this.topExpenses,
    required this.installmentTotal,
    required this.subscriptionTotal,
  });
}

class FinancialReportService {
  /// Generates the financial score and monthly breakdown
  static MonthlyHealthSummary generateSummary({
    required DateTime period,
    required List<TransactionModel> monthTransactions,
    required Map<CategoryModel, double> categoryBreakdown,
    required double installmentTotal,
    required double subscriptionTotal,
  }) {
    // 1. Calculate Income & Expense
    final incomeTxs = monthTransactions.where((t) {
      if (t.type != TransactionType.income) return false;
      final u = t.title.toUpperCase();
      return !u.contains('KREDİ KARTI') &&
          !u.contains('KREDI KARTI') &&
          !u.contains('K.KARTI') &&
          !u.contains('ÖDEMENİZ İÇİN TEŞEKKÜR') &&
          !u.contains('ODEMENIZ ICIN TESEKKUR');
    }).toList();

    final expenseTxs = monthTransactions.where((t) => t.type == TransactionType.expense || t.type == TransactionType.cashWithdrawal).toList();

    final totalIncome = incomeTxs.fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = expenseTxs.fold(0.0, (sum, t) => sum + t.amount);
    final netSavings = totalIncome - totalExpense;
    final savingsRate = totalIncome > 0 ? ((netSavings / totalIncome) * 100).clamp(-100.0, 100.0) : 0.0;

    // 2. Score Calculation (0 to 100)
    int score = 50; // base score

    // Savings rate impact (+- 30 pts)
    if (savingsRate >= 30) {
      score += 35;
    } else if (savingsRate >= 15) {
      score += 25;
    } else if (savingsRate >= 0) {
      score += 15;
    } else if (savingsRate >= -20) {
      score -= 15;
    } else {
      score -= 30;
    }

    // Debt/Installment burden impact (up to 15 pts)
    if (totalIncome > 0) {
      final installmentRatio = (installmentTotal / totalIncome) * 100;
      if (installmentRatio <= 20) {
        score += 15;
      } else if (installmentRatio <= 40) {
        score += 5;
      } else {
        score -= 10;
      }
    }

    score = score.clamp(10, 100);

    String statusTitle;
    String statusDescription;

    if (score >= 80) {
      statusTitle = 'Tasarruf Şampiyonu 🏆';
      statusDescription = 'Harika bir ay! Gelirinizin %${savingsRate.toStringAsFixed(0)}\'ini birikime ayırarak finansal hedeflerinize dev bir adım attınız.';
    } else if (score >= 60) {
      statusTitle = 'Dengeli ve Başarılı 👍';
      statusDescription = 'Bütçeniz kontrol altında. Gelir ve gider dengesini başarıyla korudunuz.';
    } else if (score >= 40) {
      statusTitle = 'Dikkatli Olunmalı ⚠️';
      statusDescription = 'Bu ay giderleriniz gelirinizin sınırında veya üzerinde gerçekleşti. Taksit ve abonelikleri gözden geçirebilirsiniz.';
    } else {
      statusTitle = 'Bütçe Aşımı Uyarısı 🚨';
      statusDescription = 'Bu ay harcamalar geliri aştı. Gelecek ay için zorunlu olmayan harcamaları kısmanız tavsiye edilir.';
    }

    // 3. Top Categories
    final sortedCategories = categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(5).toList();

    // 4. Top Single Expenses
    final sortedExpenses = List<TransactionModel>.from(expenseTxs)
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final topExpenses = sortedExpenses.take(5).toList();

    return MonthlyHealthSummary(
      period: period,
      healthScore: score,
      statusTitle: statusTitle,
      statusDescription: statusDescription,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netSavings: netSavings,
      savingsRate: savingsRate,
      topCategories: topCategories,
      topExpenses: topExpenses,
      installmentTotal: installmentTotal,
      subscriptionTotal: subscriptionTotal,
    );
  }

  /// Generates a PDF file and returns the File object
  static Future<File> generatePdfReport(MonthlyHealthSummary summary) async {
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();
    final Size pageSize = page.getClientSize();

    final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
    final PdfFont subtitleFont = PdfStandardFont(PdfFontFamily.helvetica, 11);
    final PdfFont headerFont = PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);
    final PdfFont bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
    final PdfFont boldFont = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);

    final PdfBrush primaryBrush = PdfSolidBrush(PdfColor(74, 124, 89)); // Brand green
    final PdfBrush textBrush = PdfSolidBrush(PdfColor(33, 37, 41));
    final PdfBrush mutedBrush = PdfSolidBrush(PdfColor(108, 117, 125));
    final PdfPen borderPen = PdfPen(PdfColor(222, 226, 230), width: 1);

    double y = 10;

    // 1. Header Banner
    final periodName = DateFormat('MMMM yyyy', 'tr_TR').format(summary.period).toUpperCase();
    page.graphics.drawString('KURUSU KURUSUNA', titleFont, brush: primaryBrush, bounds: Rect.fromLTWH(0, y, pageSize.width, 24));
    y += 24;
    page.graphics.drawString('AYLIK FINANSAL KARNE & BUTCE RAPORU • $periodName', subtitleFont, brush: mutedBrush, bounds: Rect.fromLTWH(0, y, pageSize.width, 18));
    y += 24;

    page.graphics.drawLine(borderPen, Offset(0, y), Offset(pageSize.width, y));
    y += 16;

    // 2. Health Score Card
    final Rect scoreBox = Rect.fromLTWH(0, y, pageSize.width, 68);
    page.graphics.drawRectangle(brush: PdfSolidBrush(PdfColor(245, 250, 246)), pen: borderPen, bounds: scoreBox);

    page.graphics.drawString(
      'Finansal Saglik Skoru: ${summary.healthScore} / 100  (${summary.statusTitle.replaceAll(RegExp(r'[^\x00-\x7F]+'), '')})',
      headerFont,
      brush: primaryBrush,
      bounds: Rect.fromLTWH(14, y + 12, pageSize.width - 28, 20),
    );

    page.graphics.drawString(
      'Net Tasarruf / Birikim Orani: %${summary.savingsRate.toStringAsFixed(1)} | Toplam Net Birikim: ${Formatters.formatCurrency(summary.netSavings)}',
      bodyFont,
      brush: textBrush,
      bounds: Rect.fromLTWH(14, y + 36, pageSize.width - 28, 18),
    );
    y += 82;

    // 3. Financial Summary Key Figures Grid
    page.graphics.drawString('Finansal Ozet Tablosu', headerFont, brush: textBrush, bounds: Rect.fromLTWH(0, y, pageSize.width, 18));
    y += 22;

    final PdfGrid summaryGrid = PdfGrid();
    summaryGrid.columns.add(count: 4);
    summaryGrid.headers.add(1);
    final PdfGridRow headerRow = summaryGrid.headers[0];
    headerRow.cells[0].value = 'Toplam Gelir';
    headerRow.cells[1].value = 'Toplam Gider';
    headerRow.cells[2].value = 'Taksit Yukumlulugu';
    headerRow.cells[3].value = 'Abonelik Toplami';
    headerRow.style = PdfGridRowStyle(font: boldFont, textBrush: primaryBrush, backgroundBrush: PdfSolidBrush(PdfColor(245, 247, 245)));

    final PdfGridRow dataRow = summaryGrid.rows.add();
    dataRow.cells[0].value = Formatters.formatCurrency(summary.totalIncome);
    dataRow.cells[1].value = Formatters.formatCurrency(summary.totalExpense);
    dataRow.cells[2].value = Formatters.formatCurrency(summary.installmentTotal);
    dataRow.cells[3].value = Formatters.formatCurrency(summary.subscriptionTotal);
    dataRow.style = PdfGridRowStyle(font: boldFont, textBrush: textBrush);

    summaryGrid.style.cellPadding = PdfPaddings(left: 8, top: 8, right: 8, bottom: 8);
    final PdfLayoutResult gridResult = summaryGrid.draw(page: page, bounds: Rect.fromLTWH(0, y, pageSize.width, 0))!;
    y = gridResult.bounds.bottom + 24;

    // 4. Top Spending Categories
    page.graphics.drawString('En Cok Harcama Yapilan Kategoriler', headerFont, brush: textBrush, bounds: Rect.fromLTWH(0, y, pageSize.width, 18));
    y += 22;

    final PdfGrid catGrid = PdfGrid();
    catGrid.columns.add(count: 3);
    catGrid.headers.add(1);
    catGrid.headers[0].cells[0].value = 'Kategori';
    catGrid.headers[0].cells[1].value = 'Tutar';
    catGrid.headers[0].cells[2].value = 'Gider Payi (%)';
    catGrid.headers[0].style = PdfGridRowStyle(font: boldFont, textBrush: primaryBrush, backgroundBrush: PdfSolidBrush(PdfColor(245, 247, 245)));

    for (final entry in summary.topCategories) {
      final row = catGrid.rows.add();
      final share = summary.totalExpense > 0 ? (entry.value / summary.totalExpense * 100) : 0.0;
      row.cells[0].value = entry.key.name;
      row.cells[1].value = Formatters.formatCurrency(entry.value);
      row.cells[2].value = '%${share.toStringAsFixed(1)}';
      row.style = PdfGridRowStyle(font: bodyFont, textBrush: textBrush);
    }

    catGrid.style.cellPadding = PdfPaddings(left: 8, top: 6, right: 8, bottom: 6);
    final PdfLayoutResult catResult = catGrid.draw(page: page, bounds: Rect.fromLTWH(0, y, pageSize.width, 0))!;
    y = catResult.bounds.bottom + 24;

    // 5. Largest Transactions
    page.graphics.drawString('Ayin En Buyuk Harcamalari', headerFont, brush: textBrush, bounds: Rect.fromLTWH(0, y, pageSize.width, 18));
    y += 22;

    final PdfGrid txGrid = PdfGrid();
    txGrid.columns.add(count: 3);
    txGrid.headers.add(1);
    txGrid.headers[0].cells[0].value = 'Harcama';
    txGrid.headers[0].cells[1].value = 'Tarih';
    txGrid.headers[0].cells[2].value = 'Tutar';
    txGrid.headers[0].style = PdfGridRowStyle(font: boldFont, textBrush: primaryBrush, backgroundBrush: PdfSolidBrush(PdfColor(245, 247, 245)));

    for (final tx in summary.topExpenses) {
      final row = txGrid.rows.add();
      row.cells[0].value = tx.title;
      row.cells[1].value = DateFormat('dd.MM.yyyy').format(tx.date);
      row.cells[2].value = Formatters.formatCurrency(tx.amount);
      row.style = PdfGridRowStyle(font: bodyFont, textBrush: textBrush);
    }

    txGrid.style.cellPadding = PdfPaddings(left: 8, top: 6, right: 8, bottom: 6);
    final PdfLayoutResult txResult = txGrid.draw(page: page, bounds: Rect.fromLTWH(0, y, pageSize.width, 0))!;
    y = txResult.bounds.bottom + 30;

    // Footer
    page.graphics.drawString(
      'Bu rapor Kurusu Kurusuna uygulamasi tarafindan olusturulmustur. Tum verileriniz cihazinizda guvenle saklanir.',
      PdfStandardFont(PdfFontFamily.helvetica, 8),
      brush: mutedBrush,
      bounds: Rect.fromLTWH(0, pageSize.height - 20, pageSize.width, 16),
    );

    // Save PDF
    final List<int> bytes = await document.save();
    document.dispose();

    final directory = await getApplicationDocumentsDirectory();
    final formattedDate = DateFormat('yyyy_MM').format(summary.period);
    final file = File('${directory.path}/Finansal_Karne_$formattedDate.pdf');
    await file.writeAsBytes(bytes, flush: true);

    return file;
  }
}
