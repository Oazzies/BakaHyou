import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bakahyou/features/library/models/library_entry.dart';
import 'package:bakahyou/features/profile/services/profile_auth_service.dart';

class LibraryService {
  static const String _baseUrl = 'https://api.mangabaka.dev/v1/my/library';
  static const int _pageLimit = 50; // API max

  final ProfileAuthService _auth;

  LibraryService({ProfileAuthService? auth})
    : _auth = auth ?? ProfileAuthService();

  Future<List<LibraryEntry>> fetchAllEntries() async {
    final token = await _auth.getValidAccessToken();
    final allEntries = <LibraryEntry>[];
    var page = 1;

    while (true) {
      final uri = Uri.parse('$_baseUrl?page=$page&limit=$_pageLimit');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'User-Agent': 'BakaHyou/0.0 (oazziesmail@gmail.com)',
        },
      );

      print("!!! LIBRARY API CALL MADE!!!");

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch library: ${response.statusCode} ${response.body}',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (body['data'] as List<dynamic>? ?? const []);

      allEntries.addAll(
        data.map((item) => LibraryEntry.fromJson(item as Map<String, dynamic>)),
      );

      // Check if there are more pages
      final pagination = body['pagination'] as Map<String, dynamic>?;
      final hasNext = pagination != null && pagination['next'] != null;

      if (!hasNext || data.isEmpty) {
        break;
      }

      page++;
    }

    return allEntries;
  }
}