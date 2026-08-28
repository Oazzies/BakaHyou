class JsonUtils {
  static T? getField<T>(Map? map, List<String> path) {
    dynamic value = map;
    for (final key in path) {
      if (value is Map && value.containsKey(key)) {
        value = value[key];
      } else {
        return null;
      }
    }
    return value as T?;
  }

  /// v1 nests each cover size as `{x1, x2}` and the original as
  /// `raw: {url, ...}`; the v2 endpoints (discover, v2 search) flatten both to
  /// plain URL strings. Both shapes are accepted so a series parsed from
  /// either API version still renders a cover.
  static String getCover(Map<String, dynamic> map) {
    final cover = map['cover'];
    if (cover is! Map) return '';
    final sized = cover['x350'];
    if (sized is Map && sized['x1'] is String) return sized['x1'] as String;
    if (sized is String) return sized;
    final fallback = cover['x250'] ?? cover['x150'];
    if (fallback is String) return fallback;
    return getRawCover(map);
  }

  static String getRawCover(Map<String, dynamic> map) {
    final cover = map['cover'];
    if (cover is! Map) return '';
    final raw = cover['raw'];
    if (raw is Map && raw['url'] is String) return raw['url'] as String;
    if (raw is String) return raw;
    return '';
  }
}
