import 'package:flutter/material.dart';
import 'package:bakahyou/features/browse/models/series_filter.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/features/series/services/series_search_service.dart';

class BrowseController extends ChangeNotifier {
  static const int _pageLimit = 20;
  static const double _scrollThreshold = 100;

  final SeriesSearchService _searchService = SeriesSearchService();

  List<Series> _searchResults = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _currentSearchQuery = '';
  SeriesFilter _filter = SeriesFilter();
  int _currentPage = 1;
  bool _hasMore = true;

  // Getters
  List<Series> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;
  SeriesFilter get filter => _filter;

  void updateFilter(SeriesFilter newFilter) {
    _filter = newFilter;
    _currentSearchQuery = newFilter.q ?? '';
    notifyListeners();
  }

  Future<void> searchSeries(String text) async {
    if (text.trim().isEmpty) {
      resetSearchState();
      return;
    }

    _isLoading = true;
    _error = null;
    _searchResults = [];
    _currentSearchQuery = text;
    _filter.q = text;
    _currentPage = 1;
    _hasMore = true;
    _isLoadingMore = false;
    notifyListeners();

    await _fetchSearchResults();
  }

  Future<void> loadMoreResults() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();
    _currentPage++;
    await _fetchSearchResults();
  }

  Future<void> _fetchSearchResults() async {
    try {
      _filter.page = _currentPage;
      _filter.limit = _pageLimit;
      final results = await _searchService.searchSeries(_filter);

      if (_currentPage == 1) {
        _searchResults = results;
      } else {
        _searchResults.addAll(results);
      }
      _isLoading = false;
      _isLoadingMore = false;
      _hasMore = results.length == _pageLimit;
    } catch (e) {
      _error = "Not found or error";
      _isLoading = false;
      _isLoadingMore = false;
      if (_currentPage > 1) {
        _currentPage--;
      }
    }
    notifyListeners();
  }

  void resetSearchState() {
    _searchResults = [];
    _error = null;
    _currentSearchQuery = '';
    _filter = SeriesFilter();
    _currentPage = 1;
    _hasMore = true;
    _isLoadingMore = false;
    notifyListeners();
  }

  void onScroll(ScrollController scrollController) {
    final isNearEnd = scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - _scrollThreshold;

    if (isNearEnd && _hasMore && !_isLoadingMore && _currentSearchQuery.isNotEmpty) {
      loadMoreResults();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
