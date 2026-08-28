/// Translates the `/series/mix` series shape into the one `Series.fromJson`
/// and `AutocompleteSeriesResult.fromJson` already understand.
///
/// The mix endpoint returns the v2 shape — `genres_v2` / `tags_v2` as arrays
/// of objects discriminated by `is_genre`, and the year nested under
/// `published.start_date` — where the search endpoints return flat `genres`,
/// `tags` and `year`. Normalising here means the rest of the app keeps a
/// single [Series] model instead of a parallel mix-only one.
///
/// Lives apart from `MixService` because it is pure data mapping: no network,
/// no state, and directly testable.
Map<String, dynamic> normalizeMixSeriesJson(Map<String, dynamic> json) {
  final normalized = Map<String, dynamic>.from(json);

  normalized['genres'] ??= _namesFrom(json['genres_v2'], isGenre: true);
  normalized['tags'] ??= _namesFrom(json['tags_v2'], isGenre: false);
  normalized['year'] ??= _yearFrom(json['published']);

  // Cover is already the same structure in both shapes; the key just has to
  // exist so the model's own fallback logic runs.
  normalized.putIfAbsent('cover', () => null);

  return normalized;
}

/// Pulls the names out of a `*_v2` array, keeping only entries on the wanted
/// side of the `is_genre` discriminator.
///
/// Returns null — rather than an empty list — when the source array is absent,
/// so `??=` above leaves an existing flat `genres`/`tags` value untouched.
List<String>? _namesFrom(dynamic v2List, {required bool isGenre}) {
  if (v2List is! List) return null;
  return v2List
      .whereType<Map>()
      .where((e) => (e['is_genre'] == true) == isGenre)
      .map((e) => e['name']?.toString() ?? '')
      .where((name) => name.isNotEmpty)
      .toList();
}

/// Reads the publication year from the leading four characters of
/// `published.start_date`, which the API formats as `YYYY-MM-DD`.
int? _yearFrom(dynamic published) {
  if (published is! Map) return null;
  final startDate = published['start_date']?.toString() ?? '';
  if (startDate.length < 4) return null;
  return int.tryParse(startDate.substring(0, 4));
}
