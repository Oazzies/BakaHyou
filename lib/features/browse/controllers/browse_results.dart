import 'package:mangabaka_app/features/browse/models/browse_type.dart';
import 'package:mangabaka_app/features/browse/services/browse_search_gateway.dart';
import 'package:mangabaka_app/features/browse/utils/staff_aggregator.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/staff/models/staff.dart';

/// The pages of browse results accumulated so far, and what is known about
/// how many more there are.
///
/// Split from `BrowseController` so paging arithmetic sits apart from the
/// query, the loading flags and the scroll listener. It holds no notion of
/// *loading* — the controller owns that, along with deciding when a page is
/// stale enough to drop.
class BrowseResults {
  final List<Series> series = [];
  final List<Publisher> publishers = [];
  final List<Staff> staff = [];

  /// The page number to request next. 1 until a page has been taken.
  int _page = 1;
  int get page => _page;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  int _total = 0;
  int get total => _total;

  /// True when [total] is a floor rather than a count — see
  /// [BrowsePage.isTotalCapped].
  bool _isTotalCapped = false;
  bool get isTotalCapped => _isTotalCapped;

  /// The list matching [type], for callers that do not care which it is.
  List<dynamic> forType(BrowseType type) {
    switch (type) {
      case BrowseType.series:
        return series;
      case BrowseType.publishers:
        return publishers;
      case BrowseType.staff:
        return staff;
      default:
        return const [];
    }
  }

  /// How many of [type] are already held — the gateway needs it to work out a
  /// total when the server does not report one.
  int loadedCount(BrowseType type) => forType(type).length;

  void clear() {
    series.clear();
    publishers.clear();
    staff.clear();
    _page = 1;
    _hasMore = true;
    _total = 0;
    _isTotalCapped = false;
  }

  /// Advances to the next page. Call before fetching, so a response can be
  /// matched against the page it was requested for.
  void advancePage() => _page++;

  /// Marks the result set exhausted without adding anything — used for a
  /// browse type that has no endpoint behind it yet.
  void markExhausted() => _hasMore = false;

  void addSeries(BrowsePage<Series> page) {
    series.addAll(page.items);
    _total = page.total;
    _isTotalCapped = page.isTotalCapped;
    _hasMore = page.hasMore;
  }

  void addPublishers(BrowsePage<Publisher> page) {
    publishers.addAll(page.items);
    _total = page.total;
    _hasMore = page.hasMore;
  }

  /// Staff accumulate by identity rather than by appending: the same person
  /// appears on many series, and a later page can reveal that someone
  /// credited as author is also the artist. The total is therefore the number
  /// of distinct people found, not a server-side count.
  void addStaff(BrowsePage<Staff> page) {
    StaffAggregator.merge(staff, page.items);
    _total = staff.length;
    _hasMore = page.hasMore;
  }
}
