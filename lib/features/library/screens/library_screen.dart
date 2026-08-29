import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/utils/browse_helpers.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/filter_chips_row.dart';
import 'package:mangabaka_app/features/library/constants/library_screen_constants.dart';
import 'package:mangabaka_app/features/library/helpers/library_filter_helper.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/models/library_sync_status.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/library/widgets/library_app_bar.dart';
import 'package:mangabaka_app/features/library/widgets/library_body.dart';
import 'package:mangabaka_app/features/library/widgets/library_status_banners.dart';
import 'package:mangabaka_app/features/library/widgets/library_tab_bar.dart';
import 'package:mangabaka_app/features/navigation/screens/main_screen.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/features/series/models/series.dart' as api;
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/shared/widgets/app_shortcuts.dart';

/// The user's library, tabbed by reading status.
///
/// Owns the entries stream, the search and filter state, and the tab
/// controller. The app bar, tab bar and status banners are their own widgets;
/// what stays here is the state they all read from and the sync lifecycle.
class LibraryScreen extends StatefulWidget {
  static final GlobalKey<LibraryScreenState> libraryScreenKey =
      GlobalKey<LibraryScreenState>();

  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen>
    with TickerProviderStateMixin {
  static final _logger = LoggingService.logger;

  /// Widest the list grows before it is centred. Grids are left unbounded —
  /// they use the extra width for more columns, where a list would just get
  /// unreadably long lines.
  static const double _maxListWidth = 800;

  late final ProfileAuthService _auth;
  late final LibraryService _libraryService;
  late final TabController _tabController;
  late final Map<String, ScrollController> _scrollControllers;

  final FocusNode _searchFocusNode = FocusNode();

  late bool _loggedIn;
  String _query = '';
  SearchFilters _filters = SearchFilters();
  bool _isSearching = false;

  Stream<List<LibraryEntry>>? _entriesStream;
  StreamSubscription<List<LibraryEntry>>? _entriesSubscription;

  /// The most recent entries, kept so auto tab switching can look across every
  /// tab without waiting for another stream event.
  List<LibraryEntry> _lastEntries = const [];

  bool _isLibraryIncomplete = false;

  // ─── Public surface, driven by MainScreen's shared top nav bar ───────────

  FocusNode get searchFocusNode => _searchFocusNode;
  Stream<List<LibraryEntry>>? get entriesStream => _entriesStream;
  SearchFilters get filters => _filters;
  String get query => _query;

  void enterSearchMode() {
    setState(() => _isSearching = true);
    _searchFocusNode.requestFocus();
  }

  void updateQuery(String value) {
    setState(() => _query = value);
    _performAutoTabSwitching();
  }

  void updateFilters(SearchFilters filters) {
    setState(() => _filters = filters);
    _performAutoTabSwitching();
  }

  void handleResultSelected(AutocompleteSeriesResult result) {
    _logger.info('Library autocomplete result selected: ${result.title}');
    _navigateToSeriesDetail(BrowseHelpers.convertAutocompleteToSeries(result));
  }

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _logger.info('Library screen initialized');

    _auth = getIt<ProfileAuthService>();
    _libraryService = getIt<LibraryService>();
    _auth.addListener(_onAuthStateChanged);

    _tabController = TabController(
      length: LibraryScreenConstants.tabs.length,
      vsync: this,
    );
    _tabController.addListener(_handleTabSelection);
    _scrollControllers = {
      for (final tab in LibraryScreenConstants.tabs)
        tab.key: ScrollController(),
    };

    _loggedIn = _auth.isLoggedIn;
    _logger.fine('Library bootstrap: loggedIn=$_loggedIn');
    if (_loggedIn) _setupStreamAndSync();

    // The shared top nav bar hosts this screen's search field on wide
    // layouts, and can only pick it up once this screen is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.findAncestorStateOfType<MainScreenState>()?.updateTopNavBar();
    });
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthStateChanged);
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    _searchFocusNode.dispose();
    _entriesSubscription?.cancel();
    super.dispose();
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging) return;
    _logger.info('Library tab switched to: ${_tabController.index}');
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    _logger.info(
      'Auth state changed in LibraryScreen. LoggedIn: ${_auth.isLoggedIn}',
    );
    setState(() {
      _loggedIn = _auth.isLoggedIn;
      if (_loggedIn) {
        _setupStreamAndSync();
      } else {
        _tearDownStream();
      }
    });
  }

  void _setupStreamAndSync() {
    _logger.info('Setting up library entries stream and sync tasks');
    _entriesStream = _libraryService.watchEntriesFromDb();
    _entriesSubscription?.cancel();
    _entriesSubscription = _entriesStream?.listen(_onEntriesUpdate);
    // Full import only on first load; later calls do an incremental catch-up.
    _runInitialSync();
  }

  void _tearDownStream() {
    _entriesStream = null;
    _entriesSubscription?.cancel();
    _entriesSubscription = null;
  }

  void _onEntriesUpdate(List<LibraryEntry> entries) {
    if (!mounted) return;
    _lastEntries = entries;
    _performAutoTabSwitching();
  }

  Future<void> _runInitialSync() async {
    try {
      await _libraryService.performInitialSyncIfNeeded();
      _logger.info('Initial sync task completed');
      final incomplete = await _libraryService.isLibraryIncomplete();
      if (mounted) setState(() => _isLibraryIncomplete = incomplete);
    } catch (e) {
      // The local copy is still usable; the banner and a manual retry cover
      // it, so a failed sync must not take the screen down.
      _logger.severe('Initial sync task failed: $e');
    }
  }

  Future<void> _loginAndReload() async {
    _logger.info('User attempting login from library screen');
    try {
      await _auth.login();
      if (!mounted) return;
      _logger.info('Login successful in library screen');
      setState(() {
        _loggedIn = true;
        _setupStreamAndSync();
      });
    } on AuthCancelledException {
      // The user backed out of the browser flow; nothing to report.
      _logger.info('Login cancelled by user in library screen');
    } catch (e) {
      _logger.severe('Login failed in library screen: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService().translate('login_failed_retry')),
        ),
      );
    }
  }

  Future<void> _onRefresh() async {
    _logger.info('User triggered manual library refresh from screen');
    _libraryService.syncLibrary().catchError((Object e) {
      // Reported through syncStatus, which raises the banner.
      _logger.severe('Manual refresh failed: $e');
    });
  }

  // ─── Search ──────────────────────────────────────────────────────────────

  void _exitSearch() {
    setState(() {
      _isSearching = false;
      _query = '';
      _filters = SearchFilters();
    });
    _performAutoTabSwitching();
  }

  /// Moves to the first tab that has matches when the current one has none.
  ///
  /// Searching within a single status is rarely what the user meant: a query
  /// that matches nothing in "Reading" but three things in "Completed" should
  /// show those, not an empty tab.
  void _performAutoTabSwitching() {
    if (!mounted ||
        (_query.isEmpty && _filters.isEmpty) ||
        _tabController.indexIsChanging) {
      return;
    }

    final helper = _filterHelper(_lastEntries);
    final currentTabKey =
        LibraryScreenConstants.tabs[_tabController.index].key;
    if (helper.getByTab(currentTabKey).isNotEmpty) return;

    _logger.info(
      'Current tab ($currentTabKey) is empty while searching. '
      'Looking for other tabs...',
    );
    for (var i = 0; i < LibraryScreenConstants.tabs.length; i++) {
      final tabKey = LibraryScreenConstants.tabs[i].key;
      if (helper.getByTab(tabKey).isEmpty) continue;
      _logger.info('Auto-switching to tab: $tabKey (index $i)');
      _tabController.animateTo(i);
      return;
    }
  }

  LibraryFilterHelper _filterHelper(List<LibraryEntry> entries) =>
      LibraryFilterHelper(
        allEntries: entries,
        query: _query,
        contentPreferences: SettingsManager().contentPreferences,
        filters: _filters,
      );

  void _navigateToSeriesDetail(api.Series series) {
    Navigator.of(context)
        .push(AppTransitions.slideUp(SeriesDetailScreen(series: series)));
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), SettingsManager()]),
      builder: (context, _) {
        final isGrid = SettingsManager().resolvedLibraryListStyle.isGrid;

        return PopScope(
          // Back leaves search before it leaves the tab.
          canPop: !_isSearching,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _exitSearch();
          },
          child: Scaffold(
            backgroundColor: LibraryScreenConstants.backgroundColor,
            appBar: _buildAppBar(context),
            body: ValueListenableBuilder<LibrarySyncStatus>(
              valueListenable: _libraryService.syncStatus,
              builder: (context, status, _) => Actions(
                actions: <Type, Action<Intent>>{
                  SearchIntent: CallbackAction<SearchIntent>(
                    onInvoke: (_) {
                      enterSearchMode();
                      return null;
                    },
                  ),
                  RefreshIntent: CallbackAction<RefreshIntent>(
                    onInvoke: (_) {
                      _onRefresh();
                      return null;
                    },
                  ),
                },
                child: WidgetUtils.responsiveConstraint(
                  _buildContent(status),
                  maxWidth: isGrid ? double.infinity : _maxListWidth,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(LibrarySyncStatus status) {
    return Column(
      children: [
        LibraryStatusBanners(
          status: status,
          isIncomplete: _isLibraryIncomplete,
          onRetrySync: _onRefresh,
          onDismissError: () => _libraryService.syncStatus.value =
              _libraryService.syncStatus.value.copyWith(clearError: true),
          onImportFullLibrary: _libraryService.importFullLibrary,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: FilterChipsRow(
            filters: _filters,
            onFiltersChanged: updateFilters,
          ),
        ),
        Expanded(
          child: LibraryBody(
            loggedIn: _loggedIn,
            entriesStream: _entriesStream,
            query: _query,
            filters: _filters,
            tabController: _tabController,
            scrollControllers: _scrollControllers,
            onRefresh: _onRefresh,
            onLogin: _loginAndReload,
            onItemTap: _navigateToSeriesDetail,
          ),
        ),
      ],
    );
  }

  /// Null when the shared top nav bar is hosting the search field instead —
  /// two search fields on one screen would be a confusing duplicate.
  PreferredSizeWidget? _buildAppBar(BuildContext context) {
    if (MainScreen.showSearchBarInTopNavBar(context)) return null;

    return LibraryAppBar(
      isSearching: _isSearching,
      isLandscape:
          MediaQuery.orientationOf(context) == Orientation.landscape,
      searchFocusNode: _searchFocusNode,
      entriesStream: _entriesStream,
      filters: _filters,
      onEnterSearch: enterSearchMode,
      onExitSearch: _exitSearch,
      onQueryChanged: updateQuery,
      onFiltersChanged: updateFilters,
      onResultSelected: handleResultSelected,
      bottom: _buildTabBar(context),
    );
  }

  PreferredSizeWidget _buildTabBar(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: StreamBuilder<List<LibraryEntry>>(
        stream: _entriesStream,
        builder: (context, snapshot) => LibraryTabBar(
          controller: _tabController,
          counts: _countsByState(snapshot.data ?? const []),
          isLandscape: isLandscape,
        ),
      ),
    );
  }

  /// Counts per status, over the same filtered set the list shows — a tab's
  /// badge has to agree with what opening it produces.
  Map<String, int> _countsByState(List<LibraryEntry> entries) {
    final counts = <String, int>{};
    for (final entry in _filterHelper(entries).getFilteredAndSorted()) {
      counts[entry.state] = (counts[entry.state] ?? 0) + 1;
    }
    return counts;
  }
}
