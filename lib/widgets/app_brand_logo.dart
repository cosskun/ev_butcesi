import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppBrandLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isVertical;

  const AppBrandLogo({
    super.key,
    this.size = 40,
    this.showText = true,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final logoIcon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset(
          'assets/images/app_logo.png',
          fit: BoxFit.cover,
        ),
      ),
    );

    if (!showText) return logoIcon;

    final textWidget = Column(
      crossAxisAlignment: isVertical ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'KURUŞU KURUŞUNA',
          style: GoogleFonts.plusJakartaSans(
            fontSize: size * 0.32,
            fontWeight: FontWeight.w800,
            color: primaryColor,
            letterSpacing: 0.6,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          'Ev Ekonomisi & Portföy',
          style: GoogleFonts.plusJakartaSans(
            fontSize: size * 0.24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
            letterSpacing: 0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    if (isVertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          logoIcon,
          SizedBox(height: size * 0.2),
          textWidget,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoIcon,
        const SizedBox(width: 10),
        Flexible(child: textWidget),
      ],
    );
  }
}
