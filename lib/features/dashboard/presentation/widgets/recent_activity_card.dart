import 'package:flutter/material.dart';
import 'package:ledgixerp/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class RecentActivityItem {
  final String title;
  final String subtitle;
  final String trailing;
  final IconData icon;
  final Color iconColor;
  final DateTime date;

  RecentActivityItem({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.icon,
    required this.iconColor,
    required this.date,
  });
}

class RecentActivityCard extends StatelessWidget {
  final String title;
  final List<RecentActivityItem> items;
  final VoidCallback? onViewAll;
  final ValueChanged<RecentActivityItem>? onItemTap;

  const RecentActivityCard({
    super.key,
    required this.title,
    required this.items,
    this.onViewAll,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.darkCard.withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.72);
    final borderColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.86);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
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
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
                if (onViewAll != null)
                  InkWell(
                    onTap: onViewAll,
                    child: Text(
                      'View all',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (items.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No recent activity',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return InkWell(
                  onTap: onItemTap == null ? null : () => onItemTap!(item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : Colors.grey[100]!,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          item.trailing,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
