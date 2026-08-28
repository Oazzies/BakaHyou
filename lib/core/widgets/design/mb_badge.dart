import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';

/// Small uppercase badge — the reference's amber "TOP" tag.
///
/// [MbBadge.accent] is the loud amber-on-ink variant; the default constructor
/// is the quiet dark-well variant used for neutral metadata (type, status).
class MbBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const MbBadge({
    super.key,
    required this.label,
    Color? background,
    Color? foreground,
  })  : background = background ?? AppConstants.tertiaryBackground,
        foreground = foreground ?? AppConstants.textColor;

  const MbBadge.accent({super.key, required this.label})
      : background = AppConstants.accentColor,
        foreground = AppConstants.onAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.display(color: foreground, fontSize: 10),
      ),
    );
  }
}
