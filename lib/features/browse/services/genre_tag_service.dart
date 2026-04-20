import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bakahyou/features/browse/models/genre.dart';
import 'package:bakahyou/features/browse/models/tag.dart';

class GenreTagService {
  static const String _baseUrl = 'https://api.mangabaka.dev/v1';
  static const String _genresCacheKey = 'cached_genres';
  static const String _tagsCacheKey = 'cached_tags';
  static const String _genresTimestampKey = 'genres_cache_timestamp';
  static const String _tagsTimestampKey = 'tags_cache_timestamp';
  static const int _cacheDurationHours = 24;

  Future<List<Genre>> getGenres({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we should use cache
    if (!forceRefresh) {
      final cachedGenres = prefs.getString(_genresCacheKey);
      if (cachedGenres != null) {
        final timestamp = prefs.getInt(_genresTimestampKey) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - timestamp < (_cacheDurationHours * 60 * 60 * 1000)) {
          return (jsonDecode(cachedGenres) as List)
              .map((e) => Genre.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    }

    // Fetch from API
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/genres'),
        headers: {'User-Agent': 'BakaHyou/0.0 (oazziesmail@gmail.com)'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];
        final genres = data
            .map((e) => Genre.fromJson(e as Map<String, dynamic>))
            .toList();

        // Cache the genres
        await prefs.setString(_genresCacheKey, jsonEncode(data));
        await prefs.setInt(
          _genresTimestampKey,
          DateTime.now().millisecondsSinceEpoch,
        );

        return genres;
      } else {
        throw Exception('Failed to fetch genres');
      }
    } catch (e) {
      // Fall back to cache if available
      final cachedGenres = prefs.getString(_genresCacheKey);
      if (cachedGenres != null) {
        return (jsonDecode(cachedGenres) as List)
            .map((e) => Genre.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    }
  }

  Future<List<Tag>> getTags({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we should use cache
    if (!forceRefresh) {
      final cachedTags = prefs.getString(_tagsCacheKey);
      if (cachedTags != null) {
        final timestamp = prefs.getInt(_tagsTimestampKey) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - timestamp < (_cacheDurationHours * 60 * 60 * 1000)) {
          return (jsonDecode(cachedTags) as List)
              .map((e) => Tag.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    }

    // Fetch from API
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tags'),
        headers: {'User-Agent': 'BakaHyou/0.0 (oazziesmail@gmail.com)'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];
        final tags = data
            .map((e) => Tag.fromJson(e as Map<String, dynamic>))
            .toList();

        // Cache the tags
        await prefs.setString(_tagsCacheKey, jsonEncode(data));
        await prefs.setInt(
          _tagsTimestampKey,
          DateTime.now().millisecondsSinceEpoch,
        );

        return tags;
      } else {
        throw Exception('Failed to fetch tags');
      }
    } catch (e) {
      // Fall back to cache if available
      final cachedTags = prefs.getString(_tagsCacheKey);
      if (cachedTags != null) {
        return (jsonDecode(cachedTags) as List)
            .map((e) => Tag.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    }
  }

  Future<void> syncGenresAndTags() async {
    try {
      await Future.wait([
        getGenres(forceRefresh: true),
        getTags(forceRefresh: true),
      ]);
    } catch (e) {
      print('Failed to sync genres and tags: $e');
    }
  }
}
