import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/widgets/chip.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    if (status.isEmpty) return SizedBox.shrink();

    final lower = status.toLowerCase();
    final formatted =
        status[0].toUpperCase() + status.substring(1).toLowerCase();

    Color? bgColor;
    IconData? icon;
    TextStyle? textStyle;
    Color? iconColor;

    if (lower == 'releasing') {
      bgColor = AppConstants.successColor.withValues(alpha: 0.15);
      icon = Icons.play_arrow_outlined;
      textStyle = TextStyle(color: AppConstants.successColor);
      iconColor = AppConstants.successColor;
    } else if (lower == 'completed') {
      bgColor = AppConstants.infoColor.withValues(alpha: 0.15);
      icon = Icons.check_circle_outline_outlined;
      textStyle = TextStyle(color: AppConstants.infoColor);
      iconColor = AppConstants.infoColor;
    } else if (lower == 'hiatus') {
      bgColor = AppConstants.warningColor.withValues(alpha: 0.15);
      icon = Icons.pause_circle_outline;
      textStyle = TextStyle(color: AppConstants.warningColor);
      iconColor = AppConstants.warningColor;
    }

    return ChipBase(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 4),
          ],
          Text(formatted, style: textStyle),
        ],
      ),
      backgroundColor: bgColor,
    );
  }
}
