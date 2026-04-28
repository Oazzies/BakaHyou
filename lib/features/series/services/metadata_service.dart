import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/services/logging_service.dart';

class MetadataService {
  final _logger = LoggingService.logger;
  Map<String, String> _genreMap = {};
  Map<String, Map<String, dynamic>> _tagMap = {};
  
  List<Map<String, dynamic>> _genresList = [];
  List<Map<String, dynamic>> _tagsList = [];

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await Future.wait([
        fetchGenres(),
        fetchTags(),
      ]);
      _isInitialized = true;
    } catch (e) {
      _logger.severe('Failed to initialize MetadataService: $e');
    }
  }

  Future<void> fetchGenres() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseApiUrl}/genres'),
        headers: {'User-Agent': AppConstants.userAgent},
      ).timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        _genresList = List<Map<String, dynamic>>.from(json['data'] ?? []);
        _genreMap = {
          for (var item in _genresList)
            item['value'].toString(): item['label'].toString()
        };
        _logger.info('Fetched ${_genresList.length} genres');
      }
    } catch (e) {
      _logger.warning('Failed to fetch genres: $e');
    }
  }

  Future<void> fetchTags() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseApiUrl}/tags'),
        headers: {'User-Agent': AppConstants.userAgent},
      ).timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        _tagsList = List<Map<String, dynamic>>.from(json['data'] ?? []);
        _tagMap = {
          for (var item in _tagsList)
            item['name'].toString(): item
        };
        _logger.info('Fetched ${_tagsList.length} tags');
      }
    } catch (e) {
      _logger.warning('Failed to fetch tags: $e');
    }
  }

  String getGenreLabel(String value) {
    if (_genreMap.containsKey(value)) {
      return _genreMap[value]!;
    }
    // Fallback to title case for each word
    if (value.isEmpty) return value;
    return value
        .split('_')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1)
            : '')
        .join(' ');
  }

  String? getTagPath(String tagName) {
    return _tagMap[tagName]?['name_path']?.toString();
  }

  String getTagName(int id) {
    try {
      final tag = _tagsList.firstWhere(
        (t) => int.parse(t['id'].toString()) == id,
      );
      return tag['name'].toString();
    } catch (e) {
      return 'Tag $id';
    }
  }

  List<Map<String, dynamic>> get genres => _genresList;
  List<Map<String, dynamic>> get tags => _tagsList;
  
  bool get isInitialized => _isInitialized;
}
