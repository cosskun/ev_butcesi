import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/backup_service.dart';
import '../providers/finance_provider.dart';
import '../providers/investment_provider.dart';

class BackupRestoreSheet extends StatefulWidget {
  const BackupRestoreSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const BackupRestoreSheet(),
    );
  }

  @override
  State<BackupRestoreSheet> createState() => _BackupRestoreSheetState();
}

class _BackupRestoreSheetState extends State<BackupRestoreSheet> {
  bool _isLoading = false;
  String? _statusMessage;

  void _exportBackup() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Yedek dosyası hazırlanıyor...';
    });

    final res = await BackupService.exportToFile();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = res.message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: res.success ? const Color(0xFF10B981) : Colors.red,
        ),
      );
    }
  }

  void _importBackup() async {
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (picked != null && picked.files.isNotEmpty) {
        final path = picked.files.first.path;
        if (path == null) return;

        setState(() {
          _isLoading = true;
          _statusMessage = 'Yedek geri yükleniyor...';
        });

        final file = File(path);
        final content = await file.readAsString();
        final res = await BackupService.restoreFromJson(content);

        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          final navigator = Navigator.of(context);
          if (res.success) {
            final finance = context.read<FinanceProvider>();
            final investment = context.read<InvestmentProvider>();
            await finance.reloadAll();
            await investment.init();
          }

          if (!mounted) return;

          setState(() {
            _isLoading = false;
            _statusMessage = res.message;
          });

          messenger.showSnackBar(
            SnackBar(
              content: Text('${res.message} (${res.transactionCount} işlem)'),
              backgroundColor: res.success ? const Color(0xFF10B981) : Colors.red,
            ),
          );

          if (res.success) {
            navigator.pop();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya açılamadı: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = theme.colorScheme.surface;
    final primaryColor = theme.colorScheme.primary;
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(24),
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
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.cloud_sync_rounded, color: primaryColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yedekleme & Geri Yükleme',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Google Drive / iCloud / Cihaz Hafızası',
                            style: TextStyle(fontSize: 11, color: textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Tüm harcamalarınız, cüzdanlarınız, bütçeleriniz ve yatırımlarınız şifreli/güvenli bir dosya olarak dışa aktarılır. Telefonunuzu değiştirdiğinizde tek tıkla geri yükleyebilirsiniz.',
            style: TextStyle(fontSize: 12, color: textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),

          if (_isLoading) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 12),
            if (_statusMessage != null)
              Center(
                child: Text(_statusMessage!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ),
          ] else ...[
            // Export Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Yeni Yedek Al (.JSON)', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: _exportBackup,
              ),
            ),
            const SizedBox(height: 10),

            // Import Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Yedekten Geri Yükle', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: _importBackup,
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
