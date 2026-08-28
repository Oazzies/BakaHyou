import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';

/// A single settings row.
///
/// Layout follows the design system's list idiom: the icon sits in its own
/// rounded well so the row has an anchor on the left, the title is set in
/// display caps, and the value/summary sits beneath it in muted sans.
class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isFirst;
  final bool isLast;
  final Color? iconColor;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.isFirst = false,
    this.isLast = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.vertical(
      top: isFirst ? Radius.circular(AppConstants.cardRadius) : Radius.zero,
      bottom: isLast ? Radius.circular(AppConstants.cardRadius) : Radius.zero,
    );

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppConstants.tertiaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor ?? AppConstants.accentColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: AppTypography.display(
                    color: AppConstants.textColor,
                    fontSize: 14,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: AppTypography.sans(
                      color: AppConstants.textMutedColor,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailing ??
              Icon(
                Icons.chevron_right_rounded,
                color: AppConstants.textMutedColor,
                size: 22,
              ),
        ],
      ),
    );

    // A row with a switch/other control in its trailing slot is not itself
    // tappable, so it must not get press feedback.
    if (onTap == null) return row;

    return MbTappable(
      onTap: onTap,
      pressedScale: 0.985,
      child: ClipRRect(borderRadius: radius, child: row),
    );
  }
}
