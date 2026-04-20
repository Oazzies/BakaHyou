import 'package:flutter/material.dart';
import 'dart:math';
import 'package:bakahyou/features/browse/controllers/browse_controller.dart';
import 'package:bakahyou/features/browse/widgets/mb_search_bar.dart';
import 'package:bakahyou/features/browse/widgets/shortcut_section.dart';
import 'package:bakahyou/features/browse/widgets/browse_state_widgets.dart';
import 'package:bakahyou/features/browse/screens/browse_results_screen.dart';
import 'package:bakahyou/features/browse/screens/browse_search_screen.dart';
import 'package:bakahyou/features/browse/models/series_filter.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({Key? key}) : super(key: key);

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  static const Color _backgroundColor = Color(0xFF0a0a0a);
  static const double _horizontalPadding = 16.0;
  static const double _verticalPadding = 16.0;

  late final BrowseController _controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = BrowseController();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    _controller.onScroll(_scrollController);
  }

  void _openSearchScreen() async {
    final result = await Navigator.push<SeriesFilter>(
      context,
      MaterialPageRoute(
        builder: (context) => const BrowseSearchScreen(),
      ),
    );

    if (result != null) {
      _controller.updateFilter(result);
      if (result.q != null && result.q!.isNotEmpty) {
        _controller.searchSeries(result.q!);
      }
    }
  }

  void _navigateToBrowseResults(String header, String sortBy, {String? type}) {
    num? randomSeed;
    if (sortBy == 'random') {
      randomSeed = Random().nextDouble() * 2 - 1;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BrowseResultsScreen(
          sortType: header,
          sortBy: sortBy,
          type: type,
          randomSeed: randomSeed,
        ),
      ),
    );
  }

  Widget _buildShortcutSections() {
    return SingleChildScrollView(
      child: Column(
        children: [
          ShortcutSection(
            header: 'Manga / Manhwa / Manhua',
            onMostPopular: () => _navigateToBrowseResults(
              'Most Popular',
              'popularity_asc',
              type: 'manga',
            ),
            onRandom: () => _navigateToBrowseResults(
              'Random',
              'random',
              type: 'manga',
            ),
          ),
          ShortcutSection(
            header: 'Novels',
            onMostPopular: () => _navigateToBrowseResults(
              'Most Popular',
              'popularity_asc',
              type: 'novel',
            ),
            onRandom: () => _navigateToBrowseResults(
              'Random',
              'random',
              type: 'novel',
            ),
          ),
          ShortcutSection(
            header: 'OEL / Other',
            onMostPopular: () => _navigateToBrowseResults(
              'Most Popular',
              'popularity_asc',
              type: 'oel',
            ),
            onRandom: () => _navigateToBrowseResults(
              'Random',
              'random',
              type: 'oel',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_controller.isLoading && _controller.searchResults.isEmpty) {
      return const BrowseLoadingState();
    }

    if (_controller.error != null && _controller.searchResults.isEmpty) {
      return BrowseErrorState(
        error: _controller.error!,
        onRetry: () => _controller.searchSeries(_controller.filter.q ?? ''),
      );
    }

    if (_controller.searchResults.isEmpty) {
      return Expanded(child: _buildShortcutSections());
    }

    return BrowseResultsListView(
      searchResults: _controller.searchResults,
      scrollController: _scrollController,
      isLoadingMore: _controller.isLoadingMore,
      onTapSeries: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _backgroundColor,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                left: _horizontalPadding,
                right: _horizontalPadding,
                top: _verticalPadding,
                bottom: 8.0,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: MBSearchBar(
                      onTap: _openSearchScreen,
                      onChanged: (text) {
                        if (text.isEmpty) {
                          _controller.resetSearchState();
                        }
                      },
                      onSubmitted: _controller.searchSeries,
                    ),
                  ),
                  _buildContent(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}