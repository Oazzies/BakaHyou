import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

/// Base chip widget used across the app for genres, tags, metadata etc.
/// Pill-shaped, minimal, with a subtle tinted border.
class ChipBase extends StatelessWidget {
  final Widget label;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final TextStyle? labelStyle;

  const ChipBase({
    required this.label,
    this.backgroundColor,
    this.borderColor,
    this.padding,
    this.labelStyle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppConstants.tertiaryBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor ??
              AppConstants.borderColor.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: DefaultTextStyle(
        style: labelStyle ??
            TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppConstants.textColor,
              height: 1.2,
            ),
        child: label,
      ),
    );
  }
}
