class SeriesFilter {
  String? q;
  List<String>? type;
  List<String>? typeNot;
  List<String>? status;
  List<String>? statusNot;
  List<String>? contentRating;
  List<String>? notContentRating;
  List<String>? genre;
  List<String>? genreNot;
  List<String>? tag;
  List<String>? tagNot;
  String? tagMode;
  String? publisher;
  String? publishedStartDateLower;
  String? publishedStartDateUpper;
  String? publishedEndDateLower;
  String? publishedEndDateUpper;
  double? ratingLower;
  double? ratingUpper;
  bool? withBoosts;
  bool? isLicensed;
  String? excludeUserLibrary;
  int? page;
  int? limit;
  String? sortBy;
  int? randomSeed;
  bool? withIgnoreContentRatingCount;

  SeriesFilter({
    this.q,
    this.type,
    this.typeNot,
    this.status,
    this.statusNot,
    this.contentRating,
    this.notContentRating,
    this.genre,
    this.genreNot,
    this.tag,
    this.tagNot,
    this.tagMode,
    this.publisher,
    this.publishedStartDateLower,
    this.publishedStartDateUpper,
    this.publishedEndDateLower,
    this.publishedEndDateUpper,
    this.ratingLower,
    this.ratingUpper,
    this.withBoosts,
    this.isLicensed,
    this.excludeUserLibrary,
    this.page = 1,
    this.limit = 20,
    this.sortBy,
    this.randomSeed,
    this.withIgnoreContentRatingCount,
  });

  Map<String, dynamic> toQueryParameters() {
    final Map<String, dynamic> params = {};
    if (q != null && q!.isNotEmpty) params['q'] = q;
    if (type != null && type!.isNotEmpty) params['type'] = type;
    if (typeNot != null && typeNot!.isNotEmpty) params['type_not'] = typeNot;
    if (status != null && status!.isNotEmpty) params['status'] = status;
    if (statusNot != null && statusNot!.isNotEmpty) params['status_not'] = statusNot;
    if (contentRating != null && contentRating!.isNotEmpty) params['content_rating'] = contentRating;
    if (notContentRating != null && notContentRating!.isNotEmpty) params['not_content_rating'] = notContentRating;
    if (genre != null && genre!.isNotEmpty) params['genre'] = genre;
    if (genreNot != null && genreNot!.isNotEmpty) params['genre_not'] = genreNot;
    if (tag != null && tag!.isNotEmpty) params['tag'] = tag;
    if (tagNot != null && tagNot!.isNotEmpty) params['tag_not'] = tagNot;
    if (tagMode != null) params['tag_mode'] = tagMode;
    if (publisher != null) params['publisher'] = publisher;
    if (publishedStartDateLower != null) params['published_start_date_lower'] = publishedStartDateLower;
    if (publishedStartDateUpper != null) params['published_start_date_upper'] = publishedStartDateUpper;
    if (publishedEndDateLower != null) params['published_end_date_lower'] = publishedEndDateLower;
    if (publishedEndDateUpper != null) params['published_end_date_upper'] = publishedEndDateUpper;
    if (ratingLower != null) params['rating_lower'] = ratingLower;
    if (ratingUpper != null) params['rating_upper'] = ratingUpper;
    if (withBoosts != null) params['with_boosts'] = withBoosts;
    if (isLicensed != null) params['is_licensed'] = isLicensed;
    if (excludeUserLibrary != null) params['exclude_user_library'] = excludeUserLibrary;
    if (page != null) params['page'] = page;
    if (limit != null) params['limit'] = limit;
    if (sortBy != null) params['sort_by'] = sortBy;
    if (randomSeed != null) params['random_seed'] = randomSeed;
    if (withIgnoreContentRatingCount != null) params['with_ignore_content_rating_count'] = withIgnoreContentRatingCount;
    return params;
  }
}
