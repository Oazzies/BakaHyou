import 'package:flutter/material.dart';
import 'package:bakahyou/features/browse/widgets/shortcut_section.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';

class BrowseShortcuts extends StatelessWidget {
  final Function(String, String, {String? type}) onNavigate;

  const BrowseShortcuts({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return ListenableBuilder(
      listenable: l10n,
      builder: (context, _) {
        return SingleChildScrollView(
          child: Column(
            children: [
              ShortcutSection(
                header: l10n.translate('manga_manhwa_manhua'),
                onMostPopular: () =>
                    onNavigate(l10n.translate('most_popular'), 'popularity_asc', type: 'manga'),
                onRandom: () => onNavigate(l10n.translate('random'), 'random', type: 'manga'),
              ),
              ShortcutSection(
                header: l10n.translate('novels'),
                onMostPopular: () =>
                    onNavigate(l10n.translate('most_popular'), 'popularity_asc', type: 'novel'),
                onRandom: () => onNavigate(l10n.translate('random'), 'random', type: 'novel'),
              ),
              ShortcutSection(
                header: l10n.translate('oel_other'),
                onMostPopular: () =>
                    onNavigate(l10n.translate('most_popular'), 'popularity_asc', type: 'oel'),
                onRandom: () => onNavigate(l10n.translate('random'), 'random', type: 'oel'),
              ),
            ],
          ),
        );
      },
    );
  }
}
