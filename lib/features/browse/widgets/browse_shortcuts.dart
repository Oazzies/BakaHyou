import 'package:flutter/material.dart';
import 'package:bakahyou/features/browse/widgets/shortcut_section.dart';

class BrowseShortcuts extends StatelessWidget {
  final Function(String, String, {String? type}) onNavigate;

  const BrowseShortcuts({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ShortcutSection(
            header: 'Manga / Manhwa / Manhua',
            onMostPopular: () =>
                onNavigate('Most Popular', 'popularity_asc', type: 'manga'),
            onRandom: () => onNavigate('Random', 'random', type: 'manga'),
          ),
          ShortcutSection(
            header: 'Novels',
            onMostPopular: () =>
                onNavigate('Most Popular', 'popularity_asc', type: 'novel'),
            onRandom: () => onNavigate('Random', 'random', type: 'novel'),
          ),
          ShortcutSection(
            header: 'OEL / Other',
            onMostPopular: () =>
                onNavigate('Most Popular', 'popularity_asc', type: 'oel'),
            onRandom: () => onNavigate('Random', 'random', type: 'oel'),
          ),
        ],
      ),
    );
  }
}
