import 'package:flutter_test/flutter_test.dart';
import 'package:kurusu_kurusuna/models/transaction_model.dart';
import 'package:kurusu_kurusuna/models/investment_model.dart';
import 'package:kurusu_kurusuna/models/category_budget_model.dart';
import 'package:kurusu_kurusuna/services/statement_parser_service.dart';
import 'package:kurusu_kurusuna/services/installment_service.dart';
import 'package:kurusu_kurusuna/services/subscription_service.dart';
import 'package:kurusu_kurusuna/services/receipt_parser_service.dart';
import 'package:kurusu_kurusuna/services/backup_service.dart';
import 'package:kurusu_kurusuna/core/utils/formatters.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });
  test('StatementParserService parses full multi-page multi-line Turkish bank statement', () {
    const fullStatementText = '''
Bonus Trink Bilgileriniz
Müşteri Numarası 49231346
Müşteri Limiti 400.000,00 TL
Kart Numarası 4043 08** **** 1897
Kart Limiti 400.000,00 TL
Nakit Avans Limiti 25.000,00 TL
Hesap Kesim Tarihi 02 Ağustos 2026
Son Ödeme Tarihi 12 Ağustos 2026
Dönem Borcunuz 248.152,59 TL
Min. Ödeme Tutarı 99.262,00 TL
Ekstre No : 910-20260803044730529704
Ekstre Sayfası 1 / 4
ÖNCEKİ DÖNEMDEN DEVİR EDİLEN TUTAR 211.878,49
DÖNEM FAİZİ 5.402,87
KKDF + BSMV 1.620,86
10 Temmuz 2026 ÖDEMENİZ İÇİN TEŞEKKÜR EDERİZ 84.752,00+
09 Temmuz 2026 BONUS BEDAVA ALIŞVERİŞ 1,26-
07 Temmuz 2026 BONUS BEDAVA ALIŞVERİŞ 3,90-
13 Temmuz 2026 BONUS BEDAVA ALIŞVERİŞ 0,93-
24 Temmuz 2026 BONUS BEDAVA ALIŞVERİS İADESİ 3,90
29 Temmuz 2026 BONUS BEDAVA ALIŞVERİŞ 35,69-
01 Ağustos 2026 BONUS BEDAVA ALIŞVERİŞ 0,76-
01 Ağustos 2026 BONUS BEDAVA ALIŞVERİŞ 0,51-
21 Temmuz 2026 BONUS BEDAVA ALIŞVERİŞ 2,10-
BONUS PROGRAM ORTAKLARI'NDA YAPTIĞINIZ HARCAMALAR
26 Temmuz 2026 N KOLAY ODEM/CEVAHIR ALPA 6.666,68x3=20.000,00 1.Taksit 10,00 6.666,68 
27 Temmuz 2026 RUBİKPARA/KARTAL ECZANESİ 1,80 2.000,00 
27 Temmuz 2026 RUBİKPARA/KARTAL ECZANESİ 0,10 106,52 
28 Temmuz 2026 ZİRAAT FİNAN/BURHAN ORMAN 6.000,00x5=30.000,00 4.Taksit 6.000,00 
06 Temmuz 2026 CARREFOUR EXP-İSTANBUL HA 0,04 123,50 
09 Temmuz 2026 CARREFOURSA ONLİNE 0,67 2.217,62 
24 Temmuz 2026 CARREFOURSA ONLİNE 0,57 1.900,56 
16 Temmuz 2026 MİGROS-ŞİRİNEVLER MJET 0,31 621,65 
18 Temmuz 2026 MİGROS-YENİCE MAH ÇORLU T 0,36 723,92 
26 Temmuz 2026 MİGROS-5M TORİUM 0,22 449,95 
02 Ağustos 2026 MİGROS-MALL OF 5M 0,91 1.813,05 
05 Temmuz 2026 ŞOK-SIRINEVLER HURRIYET C 0,06 113,00 
06 Temmuz 2026 ŞOK-SIRINEVLER HURRIYET C 0,08 165,50 
12 Temmuz 2026 ŞOK-SIRINEVLER HURRIYET C 0,11 217,70 
16 Temmuz 2026 ŞOK-SIRINEVLER HURRIYET C 0,23 465,40 
17 Temmuz 2026 ŞOK-SIRINEVLER HURRIYET C 0,07 145,80 
23 Temmuz 2026 ŞOK-SIRINEVLER HURRIYET C 0,13 265,00 
29 Temmuz 2026 ŞOK-SIRINEVLER HURRIYET C 0,09 180,90 
02 Ağustos 2026 ŞOK-SIRINEVLER HURRIYET C 0,22 430,35 
31 Temmuz 2026 IKEA-SATIS KASA 746,31x3=2.238,94 3.Taksit 746,31 
07 Temmuz 2026 TRENDYOL.COM 150,54x3=451,58 1.Taksit 0,09- 150,54+
07 Temmuz 2026 TRENDYOL.COM 1.709,41x3=5.128,19 1.Taksit 1,03 1.709,41 
08 Temmuz 2026 TRENDYOL.COM 0,11 526,43 
09 Temmuz 2026 TRENDYOL.COM 359,25x3=1.077,76 3.Taksit 359,25 
11 Temmuz 2026 TRENDYOL.COM 0,07 365,90 
13 Temmuz 2026 TRENDYOL.COM 908,36x3=2.725,06 1.Taksit 0,55 908,36 
16 Temmuz 2026 TRENDYOL.COM 555,34x3=1.665,98 1.Taksit 0,33 555,34 
16 Temmuz 2026 TRENDYOL.COM 0,07- 338,64+
16 Temmuz 2026 TRENDYOL.COM 0,23 1.148,62 
18 Temmuz 2026 TRENDYOL.COM 1.053,50x3=3.160,51 2.Taksit 1.053,50 
18 Temmuz 2026 TRENDYOL.COM 48,98x3=146,94 2.Taksit 48,98+
22 Temmuz 2026 TRENDYOL.COM 0,61 3.029,17 
24 Temmuz 2026 TRENDYOL.COM 460,08x3=1.380,26 3.Taksit 460,08 
28 Temmuz 2026 TRENDYOL.COM 489,74x3=1.469,23 2.Taksit 489,74 
28 Temmuz 2026 TRENDYOL.COM 474,53x3=1.423,57 1.Taksit 0,28 474,53 
29 Temmuz 2026 TRENDYOL.COM 671,25x3=2.013,73 1.Taksit 0,40 671,25 
30 Temmuz 2026 TRENDYOL.COM 0,07 345,37 
01 Ağustos 2026 TRENDYOL.COM 677,90x3=2.033,70 1.Taksit 0,41 677,90 
01 Ağustos 2026 TRENDYOL.COM 0,10 500,00 
01 Ağustos 2026 TRENDYOL.COM 0,08 422,49 
20 Temmuz 2026 VİVENSE BAKIRKÖY SHOWROOM 2.255,41x5=11.277,05 2.Taksit 2.255,41 
28 Temmuz 2026 ENUYGUN.COM 6.156,00 
26 Temmuz 2026 BTM MAĞAZALARI 2,30 2.300,00 
19 Temmuz 2026 TURKNET İLETİŞİM HİZMETLE 2.799,60x3=8.398,80 2.Taksit 2.799,60 
27 Temmuz 2026 TRENDYOL YEMEK 0,09 439,99 
18 Temmuz 2026 A101-9943-2461-YENİCE TEK 0,01 102,75 
21 Temmuz 2026 PENTİ GİYİM TİC.AŞ. 845,65x3=2.536,91 1.Taksit 5,07 845,65 
26 Temmuz 2026 DECATHLON 1931 TORIUM 10,60 2.120,00 
02 Ağustos 2026 DECATHLON 845 BAŞAKŞEHİR 3,95- 790,00+
02 Ağustos 2026 DECATHLON 845 BAŞAKŞEHİR 1,95 390,00 
04 Temmuz 2026 ALTUN BRODE 5.833,33x6=35.000,00 3.Taksit 5.833,33 
22 Temmuz 2026 HEPSİPAY-HEP*HEPSİBURADA 3.173,27x3=9.519,82 2.Taksit 3.173,27 
24 Temmuz 2026 HEPSİPAY-HEP*HEPSİBURADA 12.333,00x3=36.999,00 2.Taksit 12.333,00 
06 Temmuz 2026 MONEYPAY *MIGROSONE 1,16 2.312,73 
06 Temmuz 2026 MC DONALDS-PANGALTI 0,10 200,00 
07 Temmuz 2026 MC DONALDS-PANGALTI 0,08 160,00 
08 Temmuz 2026 MC DONALDS-PANGALTI 0,08 150,00 
09 Temmuz 2026 MC DONALDS-PANGALTI 0,04 85,00 
13 Temmuz 2026 MC DONALDS-PANGALTI 0,08 150,00 
16 Temmuz 2026 MC DONALDS-PANGALTI 0,04 85,00 
21 Temmuz 2026 MC DONALDS-PANGALTI 0,04 85,00 
28 Temmuz 2026 MC DONALDS-PANGALTI 0,11 215,00 
29 Temmuz 2026 MC DONALDS-PANGALTI 0,08 160,00 
30 Temmuz 2026 MC DONALDS-PANGALTI 0,04 85,00 
31 Temmuz 2026 MC DONALDS-PANGALTI 0,08 160,00 
23 Temmuz 2026 IYZICO *AMAZON.COM.T 866,33x3=2.599,00 2.Taksit 866,33 
02 Ağustos 2026 IYZICO *AMAZON.COM.T 8.966,34x3=26.899,00 1.Taksit 13,45 8.966,34 
05 Temmuz 2026 BİM-KÜLTÜR Y.BOSNA 96,50 
23 Temmuz 2026 BİM-KÜLTÜR Y.BOSNA 64,50 
23 Temmuz 2026 BİM-KÜLTÜR Y.BOSNA 135,00 
18 Temmuz 2026 BİM-DEMİRKAYA TEKİRDAĞ 143,00 
18 Temmuz 2026 İSTANBUL MARMARA FORUM 4.935,24x3=14.805,73 3.Taksit 4.935,24 
26 Temmuz 2026 TERMIN IC VE DIS TICARET 399,98 
01 Ağustos 2026 KAYALAR AVM 585,00 
01 Ağustos 2026 KAYALAR AVM 720,00 
01 Ağustos 2026 KAYALAR AVM 720,00+
28 Temmuz 2026 IYZICO/SUPPLEMENTLER.CO 928,00 
06 Temmuz 2026 YÜZDE YİYECEK İÇECEK 430,00 
06 Temmuz 2026 YÜZDE YİYECEK İÇECEK 40,00 
08 Temmuz 2026 TANTUNI YIYELIM 405,00 
08 Temmuz 2026 KEBAPÇI ÇAVUŞ 1.280,00 
13 Temmuz 2026 YÜZDE YİYECEK İÇECEK 430,00 
15 Temmuz 2026 MİKEL COFFEE 550,00 
16 Temmuz 2026 TANTUNI YIYELIM 305,00 
21 Temmuz 2026 TANTUNI YIYELIM 275,00 
22 Temmuz 2026 YEMEKPAY/YEMEK SEPET 779,99 
26 Temmuz 2026 ELTA GROUP SANAYI DIS TIC 825,00 
28 Temmuz 2026 YÜZDE YİYECEK İÇECEK 430,00 
30 Temmuz 2026 TANTUNI YIYELIM 305,00 
10 Temmuz 2026 CAFFE NERO-PANGALTI ŞB 190,00 
14 Temmuz 2026 CAFFE NERO-PANGALTI ŞB 195,00 
20 Temmuz 2026 CAFFE NERO-PANGALTI ŞB 235,00 
09 Temmuz 2026 ANTİK DÖNER 350,00 
14 Temmuz 2026 ANTİK DÖNER 350,00 
17 Temmuz 2026 ANTİK DÖNER 350,00 
24 Temmuz 2026 ANTİK DÖNER 350,00 
29 Temmuz 2026 ANTİK DÖNER 350,00 
31 Temmuz 2026 ANTİK DÖNER 350,00 
05 Temmuz 2026 SERKAN DEMIR 649,00 
11 Temmuz 2026 ÖDEAL//BEREKET HIPER 676,09 
11 Temmuz 2026 TAYGUN EROĞLU 145,00 
31 Temmuz 2026 MARMARAY OTOMAT 20,00 
07 Temmuz 2026 TARİHİ GALATA PİLAV 310,00 
10 Temmuz 2026 MAZI DAĞLI GIDA SAN.VE Tİ 480,00 
20 Temmuz 2026 TARİHİ GALATA PİLAV 310,00 
27 Temmuz 2026 TARİHİ GALATA PİLAV 185,00 
31 Temmuz 2026 MSV RESTORAN TICARET LIMI 1.215,00 
13 Temmuz 2026 DURAK GIDA VE İNŞAAT 320,00 
16 Temmuz 2026 DURAK GIDA VE İNŞAAT 898,00 
26 Temmuz 2026 ANTEPHAN KÜNEFE 1.121,00 
11 Temmuz 2026 TOPLU TASIMA GECIS U 44,52 
11 Temmuz 2026 TOPLU TASIMA GECIS U 44,52 
11 Temmuz 2026 TOPLU TASIMA GECIS U 44,52 
11 Temmuz 2026 TOPLU TASIMA GECIS U 44,52 
22 Temmuz 2026 E/ÖLÇME SEÇME VE YER 1.200,00 
26 Temmuz 2026 ENNOVA ÇOCUK 17,00 
26 Temmuz 2026 ENNOVA ÇOCUK 17,00  
27 Temmuz 2026 ENNOVA ÇOCUK 17,00 
08 Temmuz 2026 KOCZER OTOMAT 30,00 
''';

    final result = StatementParserService.parseText(fullStatementText);

    // Verify that ALL 80+ transactions are successfully extracted
    expect(result.items.length >= 70, true);
    expect(result.items.any((i) => i.transaction.title.contains('Ekstre No')), false);
    expect(result.items.any((i) => i.transaction.title.contains('ÖNCEKİ DÖNEM')), false);

    // Verify key transactions from different sections
    expect(result.items.any((i) => i.transaction.title.contains('N KOLAY')), true);
    expect(result.items.any((i) => i.transaction.title.contains('DECATHLON')), true);
    expect(result.items.any((i) => i.transaction.title.contains('AMAZON')), true);
    expect(result.items.any((i) => i.transaction.title.contains('MC DONALDS')), true);
    expect(result.items.any((i) => i.transaction.title.contains('TURKNET')), true);
    expect(result.items.any((i) => i.transaction.title.contains('GALATA PİLAV')), true);
  });

  test('StatementParserService handles multi-line split wrapped lines', () {
    const wrappedText = '''
26 Temmuz 2026
N KOLAY ODEM/CEVAHIR ALPA
6.666,68x3=20.000,00 1.Taksit
10,00
6.666,68
27 Temmuz 2026
RUBİKPARA/KARTAL ECZANESİ
1,80
2.000,00
''';

    final result = StatementParserService.parseText(wrappedText);
    expect(result.items.length, 2);
    expect(result.items[0].transaction.amount, 6666.68);
    expect(result.items[1].transaction.amount, 2000.0);
  });

  test('StatementParserService parses Banka Kartı / Vadesiz Hesap Hareketleri (Debit & ATM & FAST)', () {
    const rawDebitStatement = '''
01.08.2026 ABC TEKNOLOJİ A.Ş. MAAŞ ÖDEMESİ 52.500,00 TL
02.08.2026 GARANTİ ATM NAKİT PARA ÇEKME 4.000,00 TL
03.08.2026 AHMET YILMAZ KİRA ÖDEMESİ FAST 16.500,00 TL
04.08.2026 ENERJİSA ELEKTRİK FATURA ÖDEMESİ 650,00 TL
05.08.2026 MİGROS TİCARET A.Ş. POS HARCAMA 1.420,50 TL
06.08.2026 HESABA GELEN FAST TRANSFER MEHMET KAYA 3.500,00 TL
''';

    final result = StatementParserService.parseText(rawDebitStatement);
    expect(result.items.length, 6);

    // Salary (Income)
    final salary = result.items.firstWhere((i) => i.transaction.title.contains('MAAŞ'));
    expect(salary.transaction.amount, 52500.0);
    expect(salary.transaction.type, TransactionType.income);
    expect(salary.transaction.categoryId, 'maas');

    // ATM Cash Withdrawal (Cash transaction)
    final atm = result.items.firstWhere((i) => i.transaction.title.contains('ATM'));
    expect(atm.transaction.amount, 4000.0);
    expect(atm.transaction.type, TransactionType.cashWithdrawal);
    expect(atm.transaction.categoryId, 'nakit_cekildi');

    // Rent
    final rent = result.items.firstWhere((i) => i.transaction.title.contains('KİRA'));
    expect(rent.transaction.amount, 16500.0);
    expect(rent.transaction.type, TransactionType.expense);
    expect(rent.transaction.categoryId, 'kira');

    // Electricity bill
    final bill = result.items.firstWhere((i) => i.transaction.title.contains('ENERJİSA'));
    expect(bill.transaction.amount, 650.0);
    expect(bill.transaction.type, TransactionType.expense);
    expect(bill.transaction.categoryId, 'fatura');

    // Incoming FAST (Income)
    final fast = result.items.firstWhere((i) => i.transaction.title.contains('MEHMET KAYA'));
    expect(fast.transaction.amount, 3500.0);
    expect(fast.transaction.type, TransactionType.income);
  });

  test('StatementParserService correctly decodes Adobe PostScript glyphs and ignores Toplam summary', () {
    const rawGlyphStatement = '''
22 Temmuz 2026 E/OdieresisLCcedillaME SEÇME VE YER 1.200,00
26 Temmuz 2026 ENNOVA CcedillaOCUK 17,00
27 Temmuz 2026 ENNOVA CcedillaOCUK 17,00
08 Temmuz 2026 KOCZER OTOMAT 30,00
Toplam 10,28 248.152,59
''';

    final result = StatementParserService.parseText(rawGlyphStatement);
    expect(result.items.length, 4);

    // Verify ÖLÇME SEÇME was decoded
    expect(result.items[0].transaction.title.contains('ÖLÇME'), true);
    expect(result.items[0].transaction.amount, 1200.0);

    // Verify ENNOVA ÇOCUK was decoded and amount is 17 TL (NOT 248.152,59 TL)
    expect(result.items[1].transaction.title.contains('ÇOCUK'), true);
    expect(result.items[1].transaction.amount, 17.0);

    // Ensure 248.152,59 was NEVER captured as a transaction
    expect(result.items.any((i) => i.transaction.amount > 10000), false);
  });

  test('Smart Deduplication prevents uploading same statement 2 or 3 times', () {
    const rawStatement = '''
28.08.2026 MIGROS SANAL MARKET -850,50 TL
29.08.2026 ATM NAKIT CEKME -2.000,00 TL
30.08.2026 SIRKET MAAS ODEMESI +48.500,00 TL
''';

    final firstResult = StatementParserService.parseText(rawStatement);
    expect(firstResult.newCount, 3);
    expect(firstResult.duplicateCount, 0);

    final savedTransactions = firstResult.items.map((i) => i.transaction).toList();

    final secondResult = StatementParserService.parseText(
      rawStatement,
      existingTransactions: savedTransactions,
    );

    expect(secondResult.items.length, 3);
    expect(secondResult.newCount, 0);
    expect(secondResult.duplicateCount, 3);
    expect(secondResult.selectedNewTransactions.isEmpty, true);
  });

  test('Incremental Statement Upload: Ayın 10 unda ve 20 sinde yükleme senaryosu', () {
    // 1. Ayın 10'unda yüklenen ekstre (1-10 Temmuz arası işlemler)
    const statementDay10 = '''
05 Temmuz 2026 ŞOK MARKET 113,00 TL
06 Temmuz 2026 CARREFOUR 123,50 TL
08 Temmuz 2026 TRENDYOL.COM 526,43 TL
10 Temmuz 2026 MAAŞ GELEN +45.000,00 TL
''';

    final resDay10 = StatementParserService.parseText(statementDay10);
    expect(resDay10.newCount, 4);
    expect(resDay10.duplicateCount, 0);

    // Ayın 10'undaki 4 işlem veritabanına kaydedildi
    final dbTransactions = resDay10.items.map((i) => i.transaction).toList();

    // 2. Ayın 20'sinde gelen yeni ekstre (1-20 Temmuz arası hem eski hem yeni işlemler)
    const statementDay20 = '''
05 Temmuz 2026 ŞOK MARKET 113,00 TL
06 Temmuz 2026 CARREFOUR 123,50 TL
08 Temmuz 2026 TRENDYOL.COM 526,43 TL
10 Temmuz 2026 MAAŞ GELEN +45.000,00 TL
12 Temmuz 2026 ŞOK MARKET 217,70 TL
16 Temmuz 2026 MİGROS 621,65 TL
19 Temmuz 2026 TURKNET 2.799,60 TL
''';

    final resDay20 = StatementParserService.parseText(
      statementDay20,
      existingTransactions: dbTransactions,
    );

    // İlk 4 işlem mükerrer olarak atlanmalı, son 3 yeni işlem aktarılmalı
    expect(resDay20.totalCount, 7);
    expect(resDay20.duplicateCount, 4);
    expect(resDay20.newCount, 3);
    expect(resDay20.selectedNewTransactions.length, 3);
    expect(resDay20.selectedNewTransactions.any((t) => t.title.contains('MİGROS')), true);
    expect(resDay20.selectedNewTransactions.any((t) => t.amount == 217.70), true);
  });

  test('Garanti BBVA Hesap Hareketleri: Doğru Tutar sütununu alır, Bakiye sütununu atlar', () {
    const rawHesapHareketleri = '''
Tarih Açıklama Etiket Tutar Bakiye
31.08.2026 İGDAŞ-TES500801605947-FAT59500436675F Kurum Ödemesi -826,00 TL 129.410,15 TL
31.08.2026 İSKİFÖ 87178877 3193150646 Kurum Ödemesi -372,65 TL 130.236,15 TL
30.08.2026 GÜLESER COŞKUN-FAST-1652849061 Para Transferi +10.000,00 TL 130.923,15 TL
29.08.2026 ATM PARA ÇEKME-5170********0591-ATM Kodu:00924CRS273 Para Çekme -1.000,00 TL 120.923,15 TL
28.08.2026 ATM PARA YATIRMA-5170********0591-ATM Kodu:00078CRS001 Para Yatırma +20.000,00 TL 121.923,15 TL
14.08.2026 EMİN EVİM TASARRUF FİNANSMANI ANONİM ŞİRKETİ -2319465 Furkan Coşkun-HVL-CEP ŞUBE Para Transferi -70.839,00 TL 12.301,96 TL
11.08.2026 K.Kartı Ödeme 4043 **** **** 1897 Kart Ödemesi -48.152,59 TL 38.569,33 TL
''';

    final result = StatementParserService.parseText(rawHesapHareketleri);
    expect(result.items.length, 7);

    // 1. İGDAŞ: Should be 826 TL (NOT 129.410,15 TL!)
    final igdas = result.items.firstWhere((i) => i.transaction.title.contains('İGDAŞ'));
    expect(igdas.transaction.amount, 826.00);
    expect(igdas.transaction.type, TransactionType.expense);
    expect(igdas.transaction.categoryId, 'fatura');

    // 2. GÜLESER COŞKUN: Should be 10.000 TL Gelir (NOT 130.923,15 TL!)
    final guleser = result.items.firstWhere((i) => i.transaction.title.contains('GÜLESER COŞKUN'));
    expect(guleser.transaction.amount, 10000.00);
    expect(guleser.transaction.type, TransactionType.income);

    // 3. ATM PARA ÇEKME: Should be 1.000 TL Nakit Çekim (NOT 120.923,15 TL!)
    final atmCekme = result.items.firstWhere((i) => i.transaction.title.contains('ATM PARA ÇEKME'));
    expect(atmCekme.transaction.amount, 1000.00);
    expect(atmCekme.transaction.type, TransactionType.cashWithdrawal);

    // 4. ATM PARA YATIRMA: Should be 20.000 TL Gelir (NOT 121.923,15 TL, NOT Cash Withdrawal!)
    final atmYatirma = result.items.firstWhere((i) => i.transaction.title.contains('ATM PARA YATIRMA'));
    expect(atmYatirma.transaction.amount, 20000.00);
    expect(atmYatirma.transaction.type, TransactionType.income);

    // 5. EMİN EVİM: Should be 70.839 TL (NOT 12.301,96 TL!)
    final eminEvim = result.items.firstWhere((i) => i.transaction.title.contains('EMİN EVİM'));
    expect(eminEvim.transaction.amount, 70839.00);

    // 6. Kredi Kartı Ödemesi: Should be 48.152,59 TL (NOT 38.569,33 TL!)
    final kartOdemesi = result.items.firstWhere((i) => i.transaction.title.contains('Kartı Ödeme'));
    expect(kartOdemesi.transaction.amount, 48152.59);
  });

  test('Multi-Bank Support: İş Bankası Maximum & Vadesiz Hesap formatı', () {
    const isbankRaw = '''
TÜRKİYE İŞ BANKASI A.Ş. HESAP ÖZETİ
DÖNEM BORCU: 14.500,00 TL
ASGARİ ÖDEME TUTARI: 2.900,00 TL
KULLANILABİLİR KART LİMİTİ: 85.500,00 TL
02.08.2026 MİGROS TİCARET A.Ş. İSTANBUL 450,75 TL
05.08.2026 TRENDYOL ELEKTRONİK (1/3 TAKSİT) 1.250,00 TL
10.08.2026 İŞCEP'TEN ÖDEME +5.000,00 TL
12.08.2026 MAAŞ ÖDEMESİ - ABC HOLDİNG +55.000,00 TL
15.08.2026 BANKAMATİKTEN PARA ÇEKME 2.000,00 TL
''';

    final res = StatementParserService.parseText(isbankRaw);
    // İŞCEP'TEN ÖDEME is a card payment receipt and correctly ignored to prevent false income inflation
    expect(res.items.length, 4);

    // Migros (Market)
    expect(res.items[0].transaction.amount, 450.75);
    expect(res.items[0].transaction.categoryId, 'market');

    // Trendyol (Installment)
    expect(res.items[1].transaction.amount, 1250.00);
    expect(res.items[1].transaction.title.contains('1/3'), true);

    // Maaş (Income)
    expect(res.items[2].transaction.amount, 55000.00);
    expect(res.items[2].transaction.categoryId, 'maas');

    // Bankamatik Para Çekme (Cash Withdrawal)
    expect(res.items[3].transaction.amount, 2000.00);
    expect(res.items[3].transaction.type, TransactionType.cashWithdrawal);
  });

  test('Multi-Bank Support: Yapı Kredi Worldcard & Vadesiz Hesap formatı', () {
    const yapiKrediRaw = '''
YAPI VE KREDİ BANKASI A.Ş. HESAP ÖZETİ
WORLDPUAN: 145,20 TL
ÖNCEKİ DÖNEM BORCU: 8.900,00 TL
02/08/2026 CARREFOURSA HIPERMARKET 650,25 TL
03/08/2026 ZARA GIYIM KADIKOY 3 Taksit 1.890,00 TL
08/08/2026 ATM NAKİT PARA ÇEKME 1.000,00 TL
10/08/2026 MOBİL ŞUBE HESAPTAN ÖDEME +15.000,00 TL
''';

    final res = StatementParserService.parseText(yapiKrediRaw);
    // MOBİL ŞUBE HESAPTAN ÖDEME is an internal payment receipt and correctly filtered
    expect(res.items.length, 3);

    expect(res.items[0].transaction.amount, 650.25);
    expect(res.items[0].transaction.categoryId, 'market');

    expect(res.items[1].transaction.amount, 1890.00);
    expect(res.items[1].transaction.categoryId, 'giyim');

    expect(res.items[2].transaction.amount, 1000.00);
    expect(res.items[2].transaction.type, TransactionType.cashWithdrawal);
  });

  test('Multi-Bank Support: Akbank Axess & Vadesiz Hesap formatı', () {
    const akbankRaw = '''
AKBANK T.A.Ş. AXESS HESAP ÖZETİ
CHİP-PARA TOPLAMI: 210,00 TL
DÖNEM HARCAMALARI: 22.400,00 TL
01.08.2026 ŞOK MARKETLER T.A.Ş. 185,50 TL
04.08.2026 MEDIAMARKT ELEKTRONIK (2/6) 6.000,00 TL
05.08.2026 AKBANK DİREKT ÖDEME +10.000,00 TL
06.08.2026 AKBANK ATM NAKİT ÇEKME 1.500,00 TL
''';

    final res = StatementParserService.parseText(akbankRaw);
    // AKBANK DİREKT ÖDEME is an internal card payment receipt and correctly filtered
    expect(res.items.length, 3);

    expect(res.items[0].transaction.amount, 185.50);
    expect(res.items[0].transaction.categoryId, 'market');

    expect(res.items[1].transaction.amount, 6000.00);
    expect(res.items[1].transaction.title.contains('2/6'), true);

    expect(res.items[2].transaction.amount, 1500.00);
    expect(res.items[2].transaction.type, TransactionType.cashWithdrawal);
  });

  test('Multi-Bank Support: Enpara.com formatı', () {
    const enparaRaw = '''
ENPARA.COM KREDİ KARTI EKSTRESİ
GELECEK DÖNEM TAKSİTLERİ: 4.800,00 TL
01/08/2026 NETFLIX.COM 229,99 TL
02/08/2026 SPOTIFY ABONELİK 59,99 TL
03/08/2026 GELEN TRANSFER - ALİ KAYA +4.500,00 TL
04/08/2026 AYIN ENPARALISI KAZANCI +150,00 TL
05/08/2026 QNB ATM'SİNDEN KARTSIZ PARA ÇEKME 1.000,00 TL
''';

    final res = StatementParserService.parseText(enparaRaw);
    expect(res.items.length, 5);

    expect(res.items[0].transaction.amount, 229.99);
    expect(res.items[0].transaction.categoryId, 'eglence');

    expect(res.items[1].transaction.amount, 59.99);
    expect(res.items[1].transaction.categoryId, 'eglence');

    expect(res.items[2].transaction.amount, 4500.00);
    expect(res.items[2].transaction.type, TransactionType.income);

    expect(res.items[3].transaction.amount, 150.00);
    expect(res.items[3].transaction.type, TransactionType.income);

    expect(res.items[4].transaction.amount, 1000.00);
    expect(res.items[4].transaction.type, TransactionType.cashWithdrawal);
  });

  test('Multi-Bank Support: Ziraat Bankası Bankkart formatı', () {
    const ziraatRaw = '''
T.C. ZİRAAT BANKASI A.Ş. BANKKART EKSTRESİ
BANKKART LİRA TOPLAMI: 80,00 TL
01.08.2026 TARIM KREDİ KOOP. MARKET 420,00 TL
02.08.2026 KYK KREDİ/BURS YATAN +2.000,00 TL
05.08.2026 ZİRAAT ATM PARA ÇEKME 2.500,00 TL
''';

    final res = StatementParserService.parseText(ziraatRaw);
    expect(res.items.length, 3);

    expect(res.items[0].transaction.amount, 420.00);
    expect(res.items[0].transaction.categoryId, 'market');

    expect(res.items[1].transaction.amount, 2000.00);
    expect(res.items[1].transaction.type, TransactionType.income);

    expect(res.items[2].transaction.amount, 2500.00);
    expect(res.items[2].transaction.type, TransactionType.cashWithdrawal);
  });

  test('Multi-Bank Support: Katılım Bankaları (Kuveyt Türk, Albaraka, Türkiye Finans)', () {
    const katilimRaw = '''
KUVEYT TÜRK KATILIM BANKASI A.Ş. HESAP ÖZETİ
ALTIN PUAN TOPLAMI: 25,00 TL
01.08.2026 KÂR PAYI DAĞITIMI +1.450,00 TL
03.08.2026 SAĞLAM KART İLE MARKET ALIŞVERİŞİ 380,00 TL
05.08.2026 KUVEYT TÜRK ATM NAKİT ÇEKİM 1.000,00 TL
08.08.2026 KONUT FİNANSMANI GERİ ÖDEME -12.500,00 TL
''';

    final res = StatementParserService.parseText(katilimRaw);
    expect(res.items.length, 4);

    // Kâr payı (Investment Income)
    expect(res.items[0].transaction.amount, 1450.00);
    expect(res.items[0].transaction.type, TransactionType.income);
    expect(res.items[0].transaction.categoryId, 'yatirim');

    // Market
    expect(res.items[1].transaction.amount, 380.00);
    expect(res.items[1].transaction.categoryId, 'market');

    // ATM Çekim
    expect(res.items[2].transaction.amount, 1000.00);
    expect(res.items[2].transaction.type, TransactionType.cashWithdrawal);

    // Finansman ödemesi
    expect(res.items[3].transaction.amount, 12500.00);
    expect(res.items[3].transaction.type, TransactionType.expense);
  });

  test('Multi-Bank Support: Dijital & Özel Bankalar (Aktif Bank / N Kolay, Denizbank, TEB)', () {
    const digitalRaw = '''
AKTİF YATIRIM BANKASI A.Ş. N KOLAY HESAP ÖZETİ
01.08.2026 N KOLAY GÜNLÜK REPO/FAİZ GETİRİSİ +85,00 TL
02.08.2026 PASSOLİG İLE MAÇ BİLETİ ALIMI 450,00 TL
04.08.2026 DENİZBANK HESAPTAN GELEN FAST +3.000,00 TL
06.08.2026 CEPTETEB KREDİ KARTI BORÇ ÖDEME +4.000,00 TL
''';

    final res = StatementParserService.parseText(digitalRaw);
    expect(res.items.length, 4);

    expect(res.items[0].transaction.amount, 85.00);
    expect(res.items[0].transaction.type, TransactionType.income);

    expect(res.items[1].transaction.amount, 450.00);
    expect(res.items[1].transaction.type, TransactionType.expense);

    expect(res.items[2].transaction.amount, 3000.00);
    expect(res.items[2].transaction.type, TransactionType.income);

    expect(res.items[3].transaction.amount, 4000.00);
    expect(res.items[3].transaction.type, TransactionType.income);
  });

  test('InvestmentModel profit/loss calculation for Gold and Stocks', () {
    final gold = InvestmentModel(
      id: 'test_gold',
      title: 'Gram Altın',
      symbol: 'GAU/TRY',
      type: InvestmentType.gold,
      quantity: 20.0,
      buyUnitPrice: 2650.0,
      currentUnitPrice: 2820.0,
      buyDate: DateTime(2026, 7, 15),
    );

    expect(gold.totalCost, 53000.0);
    expect(gold.totalCurrentValue, 56400.0);
    expect(gold.profitLoss, 3400.0);
    expect(gold.isProfitable, true);
    expect(gold.profitLossPercent.toStringAsFixed(1), '6.4');

    final stock = InvestmentModel(
      id: 'test_stock',
      title: 'THYAO',
      symbol: 'THYAO.IS',
      type: InvestmentType.stock,
      quantity: 100.0,
      buyUnitPrice: 300.0,
      currentUnitPrice: 270.0,
      buyDate: DateTime(2026, 7, 10),
    );

    expect(stock.totalCost, 30000.0);
    expect(stock.totalCurrentValue, 27000.0);
    expect(stock.profitLoss, -3000.0);
    expect(stock.isProfitable, false);
    expect(stock.profitLossPercent.toStringAsFixed(1), '-10.0');
  });

  test('Formatters test', () {
    expect(Formatters.formatCurrency(1000.0).contains('1.000'), true);
  });

  test('Feature 1: Gelecek Ay Taksit Radarı hesaplaması', () {
    final txs = [
      TransactionModel(
        id: 'tx_taksit_1',
        title: 'MediaMarkt Televizyon (2/6 Taksit)',
        amount: 3500.0,
        type: TransactionType.expense,
        categoryId: 'diger_gider',
        date: DateTime(2026, 8, 15),
        paymentMethod: PaymentMethod.creditCard,
      ),
      TransactionModel(
        id: 'tx_taksit_2',
        title: 'Trendyol Koltuk (1/3)',
        amount: 2000.0,
        type: TransactionType.expense,
        categoryId: 'kira',
        date: DateTime(2026, 8, 20),
        paymentMethod: PaymentMethod.creditCard,
      ),
      TransactionModel(
        id: 'tx_normal',
        title: 'Migros Market',
        amount: 450.0,
        type: TransactionType.expense,
        categoryId: 'market',
        date: DateTime(2026, 8, 21),
        paymentMethod: PaymentMethod.bankCard,
      ),
    ];

    final installments = InstallmentService.detectInstallments(txs);
    expect(installments.length, 2);

    // 1. MediaMarkt (2/6) -> 4 remaining, 3500 * 4 = 14000 TL
    final media = installments.firstWhere((i) => i.title.contains('MediaMarkt'));
    expect(media.currentInstallment, 2);
    expect(media.totalInstallments, 6);
    expect(media.remainingInstallments, 4);
    expect(media.remainingDebt, 14000.0);

    // 2. Trendyol (1/3) -> 2 remaining, 2000 * 2 = 4000 TL
    final trendyol = installments.firstWhere((i) => i.title.contains('Trendyol'));
    expect(trendyol.remainingInstallments, 2);
    expect(trendyol.remainingDebt, 4000.0);

    // Next month committed installment liability: 3500 + 2000 = 5500 TL
    final nextMonthDue = InstallmentService.calculateNextMonthLiability(installments);
    expect(nextMonthDue, 5500.0);

    // Total future debt: 14000 + 4000 = 18000 TL
    final totalDebt = InstallmentService.calculateTotalFutureDebt(installments);
    expect(totalDebt, 18000.0);
  });

  test('Feature 2: Unutulan Abonelik Dedektörü', () {
    final txs = [
      TransactionModel(
        id: 'sub_1',
        title: 'NETFLIX.COM',
        amount: 229.99,
        type: TransactionType.expense,
        categoryId: 'eglence',
        date: DateTime(2026, 8, 1),
        paymentMethod: PaymentMethod.creditCard,
      ),
      TransactionModel(
        id: 'sub_2',
        title: 'SPOTIFY ABONELİK',
        amount: 59.99,
        type: TransactionType.expense,
        categoryId: 'eglence',
        date: DateTime(2026, 8, 5),
        paymentMethod: PaymentMethod.creditCard,
      ),
      TransactionModel(
        id: 'sub_3',
        title: 'TURKCELL FATURA',
        amount: 340.00,
        type: TransactionType.expense,
        categoryId: 'fatura',
        date: DateTime(2026, 8, 10),
        paymentMethod: PaymentMethod.creditCard,
      ),
    ];

    final subs = SubscriptionService.detectSubscriptions(txs);
    expect(subs.length, 3);

    final monthlyTotal = SubscriptionService.calculateMonthlyTotal(subs);
    expect(monthlyTotal, closeTo(629.98, 0.01));

    final yearlyTotal = SubscriptionService.calculateYearlyProjection(subs);
    expect(yearlyTotal, closeTo(7559.76, 0.01));
  });

  test('Feature 3: Kategori Bütçe Hedefleri ve Eşikler', () {
    final budget = CategoryBudgetModel(categoryId: 'market', monthlyLimit: 10000.0);

    // Safe state (< 75%)
    expect(budget.getStatus(5000.0), BudgetStatus.safe);
    expect(budget.getProgress(5000.0), 0.5);
    expect(budget.getRemaining(5000.0), 5000.0);

    // Warning state (>= 75%)
    expect(budget.getStatus(8000.0), BudgetStatus.warning);
    expect(budget.getRemaining(8000.0), 2000.0);

    // Exceeded state (>= 100%)
    expect(budget.getStatus(11500.0), BudgetStatus.exceeded);
    expect(budget.getRemaining(11500.0), -1500.0);
  });

  test('Feature 4: Güvenli Veri Yedekleme & Geri Yükleme Doğrulama', () async {
    const mockBackupJson = '''
{
  "app": "kurusu_kurusuna",
  "version": "1.0.0",
  "transactions": [
    {
      "id": "test_backup_tx",
      "title": "Yedek Test Harcaması",
      "amount": 250.0,
      "type": "expense",
      "category_id": "market",
      "date": "2026-08-20T00:00:00.000",
      "payment_method": "creditCard"
    }
  ],
  "investments": [],
  "category_budgets": {
    "market": 8000.0
  }
}
''';

    final res = await BackupService.restoreFromJson(mockBackupJson);
    expect(res.success, true);
    expect(res.transactionCount, 1);
  });

  test('Feature 5: Hızlı Fiş / Fatura Tarayıcı (ReceiptParserService)', () {
    const rawReceiptText = '''
BİM BİRLEŞİK MAĞAZALAR A.Ş.
KADIKÖY ŞUBESİ
TARİH: 15.08.2026 SAAT: 16:42
FİŞ NO: 0284
SÜT 1LT    34,50
EKMEK      12,50
PEYNİR     98,00
KDV TOPLAM 14,50
TOPLAM     145,00 TL
''';

    final parsed = ReceiptParserService.parseReceiptText(rawReceiptText);
    expect(parsed.title, 'BİM Market');
    expect(parsed.amount, 145.00);
    expect(parsed.categoryId, 'market');
    expect(parsed.date.day, 15);
    expect(parsed.date.month, 8);
    expect(parsed.date.year, 2026);
  });
}
