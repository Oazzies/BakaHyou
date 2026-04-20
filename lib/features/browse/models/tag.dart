class Tag {
  final int id;
  final int? parentId;
  final int? mergedWith;
  final String name;
  final String namePath;
  final String description;
  final bool isSpoiler;
  final bool isGenre;
  final String contentRating;
  final int seriesCount;
  final int level;

  Tag({
    required this.id,
    this.parentId,
    this.mergedWith,
    required this.name,
    required this.namePath,
    required this.description,
    required this.isSpoiler,
    required this.isGenre,
    required this.contentRating,
    required this.seriesCount,
    required this.level,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as int,
      parentId: json['parent_id'] as int?,
      mergedWith: json['merged_with'] as int?,
      name: json['name'] as String,
      namePath: json['name_path'] as String,
      description: json['description'] as String? ?? '',
      isSpoiler: json['is_spoiler'] as bool? ?? false,
      isGenre: json['is_genre'] as bool? ?? false,
      contentRating: json['content_rating'] as String? ?? 'safe',
      seriesCount: json['series_count'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'parent_id': parentId,
    'merged_with': mergedWith,
    'name': name,
    'name_path': namePath,
    'description': description,
    'is_spoiler': isSpoiler,
    'is_genre': isGenre,
    'content_rating': contentRating,
    'series_count': seriesCount,
    'level': level,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
