// Riverpod providers for search state management
// These are optional foundation code for future state management migration
// Note: Requires flutter_riverpod integration with ConsumerWidget screens
//
// To enable these providers:
// 1. Convert screens to ConsumerWidget/ConsumerStatefulWidget
// 2. Add ProviderScope wrapper in main()
// 3. Import and use providers in build methods with ref.watch()

/*
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/features/series/services/series_search_service.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/utils/exceptions/app_exceptions.dart';

// Search Service Provider
final seriesSearchServiceProvider = Provider<SeriesSearchService>(
  (ref) => getIt<SeriesSearchService>(),
);

// Search Results State Notifier
class SearchStateNotifier extends StateNotifier<SearchState> {
  final SeriesSearchService _searchService;

  SearchStateNotifier(this._searchService)
      : super(
          const SearchState(
            results: [],
            isLoading: false,
            hasMore: true,
            currentPage: 1,
            error: null,
          ),
        );

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(
        results: [],
        currentPage: 1,
        hasMore: true,
        error: null,
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await _searchService.searchSeriesByName(
        query,
        extraParams: {
          'page': 1,
          'limit': 20,
        },
      );

      state = state.copyWith(
        results: results,
        isLoading: false,
        hasMore: results.length == 20,
        currentPage: 1,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to search series',
      );
    }
  }

  Future<void> loadMore(String query) async {
    if (state.isLoading || !state.hasMore) return;

    final nextPage = state.currentPage + 1;
    state = state.copyWith(isLoading: true);

    try {
      final results = await _searchService.searchSeriesByName(
        query,
        extraParams: {
          'page': nextPage,
          'limit': 20,
        },
      );

      state = state.copyWith(
        results: [...state.results, ...results],
        isLoading: false,
        hasMore: results.length == 20,
        currentPage: nextPage,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load more results',
      );
    }
  }
}

class SearchState {
  final List<Series> results;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const SearchState({
    required this.results,
    required this.isLoading,
    required this.hasMore,
    required this.currentPage,
    required this.error,
  });

  SearchState copyWith({
    List<Series>? results,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

// Search State Provider
final searchStateProvider =
    StateNotifierProvider<SearchStateNotifier, SearchState>(
  (ref) {
    final searchService = ref.watch(seriesSearchServiceProvider);
    return SearchStateNotifier(searchService);
  },
);
*/
