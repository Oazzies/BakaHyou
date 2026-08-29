import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/browse/screens/browse_screen.dart';
import 'package:mangabaka_app/features/browse/widgets/search/mb_search_bar.dart';
import 'package:mangabaka_app/features/library/screens/library_screen.dart';
import 'package:mangabaka_app/features/library/widgets/library_search_bar.dart';
import 'package:mangabaka_app/features/navigation/models/nav_destinations.dart';

/// The search field the wide top nav bar hosts on behalf of the current tab.
///
/// On a wide landscape window there is room for one persistent search field in
/// the chrome, which is better than each screen carrying its own — so Library
/// and Browse hand theirs up here instead of drawing it themselves (see
/// `MainScreen.showSearchBarInTopNavBar`).
///
/// The field is bound to the live screen state through its global key rather
/// than to a copy of its data: it has to drive the same query and filters the
/// screen is already showing results for.
class TopNavSearchField {
  TopNavSearchField._();

  /// Builds the field for [tabIndex], or null when that tab has no search or
  /// its screen is not mounted yet.
  ///
  /// A null is expected on the first frame after a tab switch — the target
  /// screen has not built — and the nav bar simply leaves the slot empty until
  /// the screen calls `MainScreenState.updateTopNavBar`.
  static Widget? build(int tabIndex) {
    switch (tabIndex) {
      case NavTabs.library:
        return _library();
      case NavTabs.browse:
        return _browse();
      default:
        return null;
    }
  }

  static Widget? _library() {
    final state = LibraryScreen.libraryScreenKey.currentState;
    if (state == null) return null;
    return LibrarySearchBar(
      focusNode: state.searchFocusNode,
      entriesStream: state.entriesStream,
      onResultSelected: state.handleResultSelected,
      onChanged: state.updateQuery,
      initialFilters: state.filters,
      onFilterApplied: state.updateFilters,
    );
  }

  static Widget? _browse() {
    final state = BrowseScreen.browseScreenKey.currentState;
    if (state == null) return null;
    final controller = state.controller;
    return MBSearchBar(
      focusNode: state.searchFocusNode,
      controller: controller.searchController,
      initialFilters: controller.currentFilters,
      onScanTap: state.handleBarcodeScan,
      onResultSelected: state.handleResultSelected,
      onChanged: controller.updateSearchQuery,
      onSubmitted: (_) => controller.searchSeries(),
      onFilterApplied: controller.updateFilters,
    );
  }
}
