import 'package:flutter/material.dart';
import 'package:ledgixerp/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class KPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool? isTrendUp;
  final VoidCallback? onTap;

  const KPICard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.isTrendUp,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.darkCard.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.86);
    final borderColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 1)
        : AppColors.lightBorder.withValues(alpha: 0.95);
    const positiveColor = Color(0xFF4F8A67);
    const negativeColor = Color(0xFFB46A5A);
    final trendColor = isTrendUp == true ? positiveColor : negativeColor;

    return MouseRegion(
      cursor: onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.18)
                    : const Color(0xFF94A3B8).withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, color: color.withValues(alpha: 0.8), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : Colors.grey[600],
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (trend != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      isTrendUp == true ? Icons.north_east : Icons.south_east,
                      color: trendColor,
                      size: 11,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        trend!,
                        style: TextStyle(
                          color: trendColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
}
