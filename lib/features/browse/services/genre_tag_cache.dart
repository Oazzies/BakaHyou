import 'package:bakahyou/features/browse/models/genre.dart';
import 'package:bakahyou/features/browse/models/tag.dart';
import 'package:bakahyou/features/browse/services/genre_tag_service.dart';

/// Singleton cache for genres and tags to avoid repeated fetches
class GenreTagCache {
  static final GenreTagCache _instance = GenreTagCache._internal();
  
  factory GenreTagCache() {
    return _instance;
  }
  
  GenreTagCache._internal();

  List<Genre>? _cachedGenres;
  List<Tag>? _cachedTags;
  Future<List<Genre>>? _genresFuture;
  Future<List<Tag>>? _tagsFuture;
  final GenreTagService _service = GenreTagService();

  Future<List<Genre>> getGenres() {
    if (_cachedGenres != null) {
      return Future.value(_cachedGenres);
    }
    
    _genresFuture ??= _service.getGenres().then((genres) {
      _cachedGenres = genres;
      return genres;
    });
    
    return _genresFuture!;
  }

  Future<List<Tag>> getTags() {
    if (_cachedTags != null) {
      return Future.value(_cachedTags);
    }
    
    _tagsFuture ??= _service.getTags().then((tags) {
      _cachedTags = tags;
      return tags;
    });
    
    return _tagsFuture!;
  }

  void clearCache() {
    _cachedGenres = null;
    _cachedTags = null;
    _genresFuture = null;
    _tagsFuture = null;
  }
}
