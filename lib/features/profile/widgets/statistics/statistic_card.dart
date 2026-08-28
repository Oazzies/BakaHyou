import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';

class StatisticCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const StatisticCard({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.secondaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amber icon in its own well, matching the settings/shortcut rows.
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppConstants.tertiaryBackground,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppConstants.accentColor, size: 18),
          ),
          const SizedBox(height: 14),
          // The number leads, the label sits under it as a caps kicker — a
          // statistic is read value-first.
          Text(
            value,
            style: AppTypography.display(
              color: AppConstants.textColor,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: AppTypography.monoLabel(
              color: AppConstants.textMutedColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
