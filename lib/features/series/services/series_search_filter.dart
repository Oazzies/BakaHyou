import 'package:mangabaka_app/features/series/models/series.dart';

/// The result filtering the search endpoint cannot do for us.
///
/// Two things have to be re-checked on the client: content ratings, because a
/// stale or partial `content_rating` filter server-side would otherwise leak a
/// rating the user has hidden, and score bounds, because the app displays a
/// *combined* average that the backend does not sort or filter on.
///
/// Extracted from `SeriesSearchService` so the rules are testable on their own
/// and cannot drift from the ones the browse screen applies.
class SeriesSearchFilter {
  /// Ratings the user allows. Empty means "no preference recorded" — which
  /// permits everything rather than nothing.
  final List<String> contentPreferences;

  /// Inclusive score bounds on the app's 0–100 scale, or null for unbounded.
  final double? ratingLower;
  final double? ratingUpper;

  /// The active sort. When sorting by score, unrated series are dropped: a
  /// rating of 0 means "no rating", and letting those sit at one end of the
  /// list reads as a bug.
  final String? sortBy;

  const SeriesSearchFilter({
    this.contentPreferences = const [],
    this.ratingLower,
    this.ratingUpper,
    this.sortBy,
  });

  bool get _hasRatingBounds => ratingLower != null || ratingUpper != null;

  bool get _sortsByScore => sortBy != null && sortBy!.startsWith('score_');

  bool allows(Series series) {
    if (contentPreferences.isNotEmpty &&
        !contentPreferences.contains(series.contentRating.toLowerCase())) {
      return false;
    }

    if (_hasRatingBounds) {
      final rating = normalizedRating(series);
      if (ratingLower != null && rating < ratingLower!) return false;
      if (ratingUpper != null && rating > ratingUpper!) return false;
      return true;
    }

    if (_sortsByScore && normalizedRating(series) == 0) return false;

    return true;
  }

  /// The series' score on a 0–100 scale.
  ///
  /// The API has returned both scales over time; a value at or below 10 is
  /// read as the 0–10 form and scaled up. An unparseable rating counts as
  /// unrated (0) rather than failing the whole result set.
  static double normalizedRating(Series series) {
    final raw = double.tryParse(series.rating) ?? 0.0;
    return raw <= 10.0 ? raw * 10 : raw;
  }
}
