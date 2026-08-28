/// Whether the personalised "For You" rail has anything worth showing yet.
///
/// The API reports `cold_start` / `profile_stale` from a cheap probe so the
/// client can hide the rail instead of rendering an empty one.
class ForYouReadiness {
  final bool coldStart;
  final bool profileStale;
  final int libraryCount;

  const ForYouReadiness({
    required this.coldStart,
    required this.profileStale,
    required this.libraryCount,
  });

  bool get isReady => !coldStart;

  factory ForYouReadiness.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    return ForYouReadiness(
      coldStart: data['cold_start'] == true,
      profileStale: data['profile_stale'] == true,
      libraryCount: (data['library_count'] as num?)?.toInt() ?? 0,
    );
  }
}
