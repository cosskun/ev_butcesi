import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/theme_provider.dart';

class ThemeSelectorModal extends StatefulWidget {
  const ThemeSelectorModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ThemeSelectorModal(),
    );
  }

  @override
  State<ThemeSelectorModal> createState() => _ThemeSelectorModalState();
}

class _ThemeSelectorModalState extends State<ThemeSelectorModal> {
  late AppPalette _selectedPalette;
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    final tp = context.read<ThemeProvider>();
    _selectedPalette = tp.currentPalette;
    _isDark = tp.isDarkMode;
  }

  void _applyTheme() {
    final tp = context.read<ThemeProvider>();
    tp.setPalette(_selectedPalette);
    tp.toggleDarkMode(_isDark);

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Text('${_selectedPalette.displayName} teması uygulandı!'),
          ],
        ),
        backgroundColor: _selectedPalette.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = _isDark ? AppTheme.cardSurfaceDark : Colors.white;
    final textCol = _isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final primaryCol = _selectedPalette.primaryColor;
    final secondaryCol = _selectedPalette.secondaryColor;
    final previewBg = _selectedPalette.lightBg;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar & Title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _isDark ? AppTheme.dividerDark : AppTheme.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: previewBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.palette_rounded, color: primaryCol, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Görünüm & Tema Seçimi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textCol,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.divider),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LIVE PREVIEW CARD
                    Row(
                      children: [
                        Icon(Icons.remove_red_eye_rounded, size: 16, color: primaryCol),
                        const SizedBox(width: 6),
                        Text(
                          'CANLI ÖNİZLEME',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: primaryCol,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Mini Mockup Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _isDark ? const Color(0xFF131722) : previewBg.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: primaryCol.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mini Dashboard Hero Card Preview
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryCol, secondaryCol],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryCol.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'CÜZDAN TOPLAMI',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        '+%15 Tasarruf',
                                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  '₺42.500,00',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Sample Buttons & Badges preview
                          Row(
                            children: [
                              // Sample Filled Button
                              Expanded(
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: primaryCol,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_circle_outline, color: Colors.white, size: 15),
                                        SizedBox(width: 4),
                                        Text(
                                          '+ Gelir Ekle',
                                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Sample Outlined Chip Button (1000 TL muz)
                              Expanded(
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: _isDark ? const Color(0xFF1E2330) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: primaryCol.withValues(alpha: 0.5)),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.shopping_basket_rounded, color: primaryCol, size: 15),
                                        const SizedBox(width: 4),
                                        Text(
                                          '- 1000 ₺ Muz',
                                          style: TextStyle(
                                            color: textCol,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Color Swatches Row
                          Row(
                            children: [
                              _buildColorSwatchCircle('Ana Renk', primaryCol),
                              const SizedBox(width: 8),
                              _buildColorSwatchCircle('İkincil', secondaryCol),
                              const SizedBox(width: 8),
                              _buildColorSwatchCircle('Zemin', previewBg, isBordered: true),
                              const Spacer(),
                              Text(
                                _selectedPalette.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: primaryCol,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Dark Mode Toggle Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isDark ? const Color(0xFF131722) : AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _isDark ? AppTheme.borderDark : AppTheme.border,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                color: _isDark ? Colors.amber : Colors.orange,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isDark ? 'Koyu Soft Gece Modu' : 'Açık Soft Pastel Mod',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: textCol,
                                    ),
                                  ),
                                  Text(
                                    _isDark ? 'Göz yormayan yumuşak koyu tonlar' : 'Ferah ve aydınlık pastel görünüm',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Switch(
                            value: _isDark,
                            activeThumbColor: primaryCol,
                            onChanged: (val) {
                              setState(() => _isDark = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Color Palettes List
                    Text(
                      'Soft Renk Paletini Seçin',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textCol,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Palettes Options
                    ...AppPalette.values.map((palette) {
                      final isSelected = _selectedPalette == palette;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPalette = palette;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (_isDark ? const Color(0xFF1E2330) : palette.lightBg)
                                : (_isDark ? const Color(0xFF131722) : Colors.white),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected ? palette.primaryColor : (_isDark ? AppTheme.borderDark : AppTheme.border),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: palette.primaryColor.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            children: [
                              // 4-Color Swatch Preview
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(radius: 10, backgroundColor: palette.primaryColor),
                                    const SizedBox(width: 3),
                                    CircleAvatar(radius: 8, backgroundColor: palette.secondaryColor),
                                    const SizedBox(width: 3),
                                    CircleAvatar(radius: 8, backgroundColor: palette.lightBg),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Name
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      palette.displayName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: textCol,
                                      ),
                                    ),
                                    Text(
                                      isSelected ? 'Seçili (Önizlemede gösteriliyor)' : 'Önizlemek için dokunun',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                        color: isSelected ? palette.primaryColor : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Radio Indicator
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                color: isSelected ? palette.primaryColor : AppTheme.textMuted,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Bottom Apply Action Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bg,
                border: Border(top: BorderSide(color: _isDark ? AppTheme.dividerDark : AppTheme.divider)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryCol,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    '${_selectedPalette.displayName} Temasını Uygula',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  onPressed: _applyTheme,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSwatchCircle(String label, Color color, {bool isBordered = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isBordered ? Border.all(color: AppTheme.border) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
