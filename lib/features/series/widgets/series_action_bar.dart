import 'package:flutter/material.dart';
import 'package:bakahyou/features/library/models/library_entry.dart';
import 'package:bakahyou/features/series/widgets/state_selection_section.dart';
import 'package:bakahyou/features/series/widgets/rating_icon_button.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';

class SeriesActionBar extends StatelessWidget {
  final LibraryEntry? entry;
  final Function(String) onStateChanged;
  final Function(int) onRatingChanged;
  final LocalizationService l10n;

  const SeriesActionBar({
    super.key,
    this.entry,
    required this.onStateChanged,
    required this.onRatingChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (entry == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: StateSelectionSection(
            currentState: entry!.state,
            onStateChanged: onStateChanged,
          ),
        ),
        const SizedBox(width: 12),
        RatingIconButton(
          currentRating: entry!.rating,
          onRatingChanged: onRatingChanged,
        ),
      ],
    );
  }
}
