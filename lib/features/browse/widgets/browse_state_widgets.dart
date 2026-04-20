import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/features/series/widgets/entry_list_item.dart';
import 'package:bakahyou/features/series/screens/series_detail_screen.dart';

class BrowseResultsListView extends StatelessWidget {
  final List<Series> searchResults;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final VoidCallback onTapSeries;

  const BrowseResultsListView({
    super.key,
    required this.searchResults,
    required this.scrollController,
    required this.isLoadingMore,
    required this.onTapSeries,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        controller: scrollController,
        itemCount: searchResults.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == searchResults.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final series = searchResults[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SeriesDetailScreen(series: series),
                ),
              );
            },
            child: EntryListItem(series: series),
          );
        },
      ),
    );
  }
}

class BrowseLoadingState extends StatelessWidget {
  const BrowseLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Expanded(
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class BrowseErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const BrowseErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              error,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
