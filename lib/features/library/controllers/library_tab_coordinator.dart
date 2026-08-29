import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/library/constants/library_screen_constants.dart';
import 'package:mangabaka_app/features/library/helpers/library_filter_helper.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';

/// Decides which library tab should be showing, and counts what is in each.
///
/// Both answers come from the same filtered set, which is the point: the count
/// on a tab's badge has to agree with what opening that tab produces. The
/// screen used to build a [LibraryFilterHelper] separately for each with
/// slightly different arguments.
class LibraryTabCoordinator {
  static final _logger = LoggingService.logger;

  final TabController controller;

  LibraryTabCoordinator({required this.controller});

  String _query = '';
  SearchFilters _filters = SearchFilters();

  /// The most recent entries, kept so [autoSwitch] can look across every tab
  /// without waiting for another stream event.
  List<LibraryEntry> _entries = const [];

  void setEntries(List<LibraryEntry> entries) => _entries = entries;

  void setQuery(String query) => _query = query;

  void setFilters(SearchFilters filters) => _filters = filters;

  void reset() {
    _query = '';
    _filters = SearchFilters();
  }

  /// A helper over [entries] with the current query, filters and content
  /// preferences applied.
  LibraryFilterHelper filterFor(List<LibraryEntry> entries) =>
      LibraryFilterHelper(
        allEntries: entries,
        query: _query,
        contentPreferences: SettingsManager().contentPreferences,
        filters: _filters,
      );

  /// Entry counts per status, over the same filtered set the list shows.
  Map<String, int> countsFor(List<LibraryEntry> entries) {
    final counts = <String, int>{};
    for (final entry in filterFor(entries).getFilteredAndSorted()) {
      counts[entry.state] = (counts[entry.state] ?? 0) + 1;
    }
    return counts;
  }

  /// Moves to the first tab that has matches when the current one has none.
  ///
  /// Searching within a single status is rarely what the user meant: a query
  /// that matches nothing in "Reading" but three things in "Completed" should
  /// show those, not an empty tab. Only applies while something is being
  /// searched for — with no query and no filters, the user's chosen tab is the
  /// one they want.
  void autoSwitch() {
    if (_query.isEmpty && _filters.isEmpty) return;
    // Mid-swipe the index is in flux; moving it again would fight the gesture.
    if (controller.indexIsChanging) return;

    final helper = filterFor(_entries);
    final tabs = LibraryScreenConstants.tabs;
    final currentKey = tabs[controller.index].key;
    if (helper.getByTab(currentKey).isNotEmpty) return;

    _logger.info(
      'Current tab ($currentKey) is empty while searching. '
      'Looking for other tabs...',
    );
    for (var i = 0; i < tabs.length; i++) {
      if (helper.getByTab(tabs[i].key).isEmpty) continue;
      _logger.info('Auto-switching to tab: ${tabs[i].key} (index $i)');
      controller.animateTo(i);
      return;
    }
  }
}
