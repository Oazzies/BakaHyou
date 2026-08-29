import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/browse/models/browse_type.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/services/book_lookup_service.dart';
import 'package:mangabaka_app/features/browse/services/browse_search_gateway.dart';
import 'package:mangabaka_app/features/browse/utils/browse_helpers.dart';
import 'package:mangabaka_app/features/browse/utils/staff_aggregator.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/staff/models/staff.dart';

/// Drives the Browse screen: the query, the filters, the active result type,
/// and the accumulated pages.
///
/// Fetching itself belongs to [BrowseSearchGateway]; what stays here is the
/// state around it — which page is next, whether more exist, and the
/// generation guard that keeps a slow response from an abandoned search out of
/// the current results.
class BrowseController extends ChangeNotifier {
  static final _logger = LoggingService.logger;

  /// Scroll offset past which the back-to-top button appears.
  static const double _backToTopOffset = 500;

  final BrowseSearchGateway _gateway;

  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  BrowseController({BrowseSearchGateway? gateway})
      : _gateway = gateway ?? BrowseSearchGateway() {
    scrollController.addListener(_onScroll);
  }

  BrowseType _currentType = BrowseType.series;
  BrowseType get currentType => _currentType;

  List<Series> _seriesResults = [];
  List<Series> get seriesResults => _seriesResults;

  List<Publisher> _publisherResults = [];
  List<Publisher> get publisherResults => _publisherResults;

  List<Staff> _staffResults = [];
  List<Staff> get staffResults => _staffResults;

  /// The results for whichever type is active, for callers that do not care
  /// which it is.
  List<dynamic> get searchResults {
    switch (_currentType) {
      case BrowseType.series:
        return _seriesResults;
      case BrowseType.publishers:
        return _publisherResults;
      case BrowseType.staff:
        return _staffResults;
      default:
        return const [];
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _error;
  String? get error => _error;

  String _currentSearchQuery = '';
  String get currentSearchQuery => _currentSearchQuery;

  int _currentPage = 1;
  bool _hasMore = true;

  int _totalResults = 0;
  int get totalResults => _totalResults;

  bool _isTotalCapped = false;
  bool get isTotalCapped => _isTotalCapped;

  SearchFilters _currentFilters = SearchFilters();
  SearchFilters get currentFilters => _currentFilters;

  /// Incremented whenever the search context changes (new query, reset, tab
  /// switch). In-flight responses compare their captured generation against
  /// this before touching state, so a slow page from an old search can never
  /// be appended to the results of a newer one.
  int _requestGeneration = 0;

  bool get isSearchMode =>
      _currentSearchQuery.trim().isNotEmpty ||
      !_currentFilters.isEmpty ||
      _isLoading ||
      _error != null ||
      searchResults.isNotEmpty;

  bool _showBackToTop = false;
  bool get showBackToTop => _showBackToTop;

  bool get _hasSearchContext =>
      _currentSearchQuery.isNotEmpty || _currentFilters.toMap().isNotEmpty;

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // ─── Scrolling ───────────────────────────────────────────────────────────

  void _onScroll() {
    // Two attached positions means the list is mid-rebuild between routes;
    // reading `position` would throw.
    if (!scrollController.hasClients ||
        scrollController.positions.length != 1) {
      return;
    }

    final isNearEnd = scrollController.position.pixels >=
        scrollController.position.maxScrollExtent -
            AppConstants.scrollThresholdPx;

    if (isNearEnd && _hasMore && !_isLoadingMore && _hasSearchContext) {
      _logger.fine(
        'Near end of scroll, loading more results for query: '
        '"$_currentSearchQuery"',
      );
      loadMoreResults();
    }

    final showBackToTop = scrollController.offset > _backToTopOffset;
    if (showBackToTop == _showBackToTop) return;
    _showBackToTop = showBackToTop;
    notifyListeners();
  }

  void checkScroll() => _onScroll();

  void scrollToTop() {
    scrollController.animateTo(
      0,
      duration: AppConstants.mediumAnimationDuration,
      curve: Curves.easeInOut,
    );
  }

  /// After a page loads, schedules a scroll check so the list auto-loads the
  /// next page if the content is short enough to fit on screen.
  void _scheduleScrollCheckIfNeeded() {
    if (!_hasMore) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => checkScroll());
  }

  // ─── Search context ──────────────────────────────────────────────────────

  void resetSearchState() {
    _logger.fine('Resetting search state');
    _requestGeneration++;
    _clearResults();
    _error = null;
    _currentSearchQuery = '';
    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  void _clearResults() {
    _seriesResults = [];
    _publisherResults = [];
    _staffResults = [];
    _currentPage = 1;
    _hasMore = true;
    _totalResults = 0;
    _isTotalCapped = false;
  }

  void setType(BrowseType type) {
    if (_currentType == type) return;
    _logger.info('Switching browse type to: $type');
    _currentType = type;
    // Carry an active search across the tab switch rather than dropping it.
    if (_hasSearchContext) {
      searchSeries();
    } else {
      resetSearchState();
    }
  }

  void updateSearchQuery(String text) {
    _currentSearchQuery = text;
    if (text.isEmpty && _currentFilters.toMap().isEmpty) resetSearchState();
  }

  void updateFilters(SearchFilters filters) {
    _logger.info('Filters updated: ${filters.toMap()}');
    _currentFilters = filters;
    // Filters only apply to series; the Publishers and Staff tabs are hidden
    // while any are set, so an active one has to fall back.
    if (!filters.isEmpty &&
        (_currentType == BrowseType.publishers ||
            _currentType == BrowseType.staff)) {
      _currentType = BrowseType.series;
    }
    searchSeries();
  }

  void startTagSearch(List<String> tagIds) {
    _logger.info('Starting tag search with tag IDs: $tagIds');
    _startFilteredSearch(SearchFilters(tag: tagIds));
  }

  void startGenreSearch(String genre) {
    _logger.info('Starting genre search with genre: $genre');
    _startFilteredSearch(SearchFilters(genre: [genre]));
  }

  void startSearchWithFilters(SearchFilters filters) {
    _logger.info('Starting search with filters: ${filters.toMap()}');
    _startFilteredSearch(filters);
  }

  /// Replaces the whole search context with [filters] and runs it. The text
  /// query is cleared: these entry points come from tapping a chip elsewhere
  /// in the app, where a leftover query would silently narrow the results.
  void _startFilteredSearch(SearchFilters filters) {
    searchController.clear();
    _currentSearchQuery = '';
    _currentType = BrowseType.series;
    _currentFilters = filters;
    searchSeries();
  }

  // ─── Fetching ────────────────────────────────────────────────────────────

  Future<void> searchSeries() async {
    if (_currentSearchQuery.trim().isEmpty &&
        _currentFilters.toMap().isEmpty) {
      _logger.fine('Search query and filters are empty, skipping search');
      resetSearchState();
      return;
    }

    _logger.info(
      'Starting new search for $_currentType with query: '
      '"$_currentSearchQuery" with filters: ${_currentFilters.toMap()}',
    );
    _requestGeneration++;
    _isLoading = true;
    _isLoadingMore = false;
    _error = null;
    _clearResults();
    notifyListeners();

    await _fetchPage();
  }

  Future<void> loadMoreResults() async {
    // _isLoading guards against the initial page still being in flight: an
    // empty list has maxScrollExtent 0, which counts as "near end", so the
    // scroll listener could otherwise fire page 2 concurrently with page 1.
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    _logger.info(
      'Loading more results for query: "$_currentSearchQuery", '
      'page: ${_currentPage + 1}',
    );
    _isLoadingMore = true;
    notifyListeners();

    _currentPage++;
    await _fetchPage();
  }

  Future<void> _fetchPage() async {
    final generation = _requestGeneration;
    try {
      switch (_currentType) {
        case BrowseType.series:
          _applySeries(
            await _gateway.fetchSeries(
              query: _currentSearchQuery,
              page: _currentPage,
              filters: _currentFilters,
              alreadyLoaded: _seriesResults.length,
            ),
            generation,
          );
        case BrowseType.publishers:
          _applyPublishers(
            await _gateway.fetchPublishers(
              query: _currentSearchQuery,
              page: _currentPage,
              filters: _currentFilters,
              alreadyLoaded: _publisherResults.length,
            ),
            generation,
          );
        case BrowseType.staff:
          _applyStaff(
            await _gateway.fetchStaff(
              query: _currentSearchQuery,
              page: _currentPage,
              filters: _currentFilters,
            ),
            generation,
          );
        default:
          // A type with no backing endpoint yet: settle into an empty,
          // non-loading state rather than spinning forever.
          _hasMore = false;
          _isLoading = false;
          _isLoadingMore = false;
          notifyListeners();
      }
    } catch (e) {
      if (generation != _requestGeneration) return;
      _logger.severe(
        'Failed to fetch search results for type $_currentType, query '
        '"$_currentSearchQuery" at page $_currentPage: $e',
      );
      _isLoading = false;
      _isLoadingMore = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  void _applySeries(BrowsePage<Series> page, int generation) {
    if (_isStale(generation, 'series')) return;
    _totalResults = page.total;
    _isTotalCapped = page.isTotalCapped;
    _seriesResults.addAll(page.items);
    _finishPage(page.hasMore);
  }

  void _applyPublishers(BrowsePage<Publisher> page, int generation) {
    if (_isStale(generation, 'publisher')) return;
    _totalResults = page.total;
    _publisherResults.addAll(page.items);
    _finishPage(page.hasMore);
  }

  void _applyStaff(BrowsePage<Staff> page, int generation) {
    if (_isStale(generation, 'staff')) return;
    // Staff accumulate by identity rather than by appending: the same person
    // appears on many series, and a later page can reveal that someone
    // credited as author is also the artist.
    StaffAggregator.merge(_staffResults, page.items);
    _totalResults = _staffResults.length;
    _finishPage(page.hasMore);
  }

  bool _isStale(int generation, String label) {
    if (generation == _requestGeneration) return false;
    _logger.fine('Discarding stale $label results for superseded search');
    return true;
  }

  void _finishPage(bool hasMore) {
    _hasMore = hasMore;
    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
    _scheduleScrollCheckIfNeeded();
  }

  // ─── Barcode ─────────────────────────────────────────────────────────────

  static double generateRandomSeed() => Random().nextDouble();

  /// Looks an ISBN up and searches for the title it resolves to.
  ///
  /// Returns null on success, or a localisation key naming what went wrong —
  /// the caller shows it, since only the UI knows how.
  ///
  /// A scanned title often carries volume numbers and edition text that no
  /// series is filed under, so a fruitless search is retried against a cleaned
  /// version before giving up.
  Future<String?> handleBarcodeScan(String isbn) async {
    if (isbn.isEmpty) return null;

    _logger.info('Handling barcode scan for ISBN: $isbn');
    _isLoading = true;
    _error = null;
    notifyListeners();

    final String? title;
    try {
      title = await getIt<BookLookupService>().lookupTitleByIsbn(isbn);
    } catch (e) {
      _logger.severe('Error handling barcode scan for ISBN $isbn: $e');
      _isLoading = false;
      notifyListeners();
      return 'barcode_lookup_failed';
    }

    if (title == null || title.isEmpty) {
      _logger.warning('No title found for ISBN: $isbn');
      _isLoading = false;
      notifyListeners();
      return 'barcode_not_found';
    }

    _logger.info('Found title from ISBN: $title');
    if (await _searchFor(title)) return null;

    final cleaned = BrowseHelpers.cleanTitle(title);
    if (cleaned != title && cleaned.isNotEmpty) {
      _logger.info(
        'No results for raw title, trying cleaned title: $cleaned',
      );
      if (await _searchFor(cleaned)) return null;
    }

    _logger.warning(
      'No series found for title associated with ISBN: $isbn (Title: $title)',
    );
    return 'no_series_found_for';
  }

  /// Runs [title] as a search, returning whether it matched anything.
  Future<bool> _searchFor(String title) async {
    searchController.text = title;
    _currentSearchQuery = title;
    await searchSeries();
    return _seriesResults.isNotEmpty;
  }
}
