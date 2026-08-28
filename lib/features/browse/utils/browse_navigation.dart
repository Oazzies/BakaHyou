import 'package:flutter/widgets.dart';
import 'package:mangabaka_app/features/browse/controllers/browse_controller.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/screens/browse_screen.dart';
import 'package:mangabaka_app/features/navigation/screens/main_screen.dart';

/// Hands a search to the Browse tab and takes the user there.
///
/// Three screens each had their own copy of this three-step dance — seed the
/// live [BrowseScreen] state, switch to its tab, unwind back to the root — and
/// a missed step showed up as the tab opening on stale results.
///
/// The Browse screen may not be mounted (its tab has never been visited), in
/// which case seeding is skipped: the navigation still happens, and Browse
/// starts from its own default state rather than crashing.
class BrowseNavigation {
  BrowseNavigation._();

  /// Index of the Browse tab in [MainScreen]'s bottom navigation.
  static const int browseTabIndex = 2;

  static void searchByTags(BuildContext context, List<String> tagIds) {
    _go(context, (controller) => controller.startTagSearch(tagIds));
  }

  static void searchByGenre(BuildContext context, String genreKey) {
    _go(context, (controller) => controller.startGenreSearch(genreKey));
  }

  static void searchWithFilters(BuildContext context, SearchFilters filters) {
    _go(context, (controller) => controller.startSearchWithFilters(filters));
  }

  static void _go(BuildContext context, void Function(BrowseController controller) seed) {
    final browseState = BrowseScreen.browseScreenKey.currentState;
    if (browseState != null) seed(browseState.controller);

    MainScreen.setTabIndex(browseTabIndex);

    // Pop back to the tab shell; the caller may be several pushes deep.
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
