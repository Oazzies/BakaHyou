import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/network/api_client.dart';
import 'package:mangabaka_app/core/network/api_envelope.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';

/// Reads the `/publishers` endpoints.
///
/// Request plumbing — timeout, User-Agent, status handling, backend-health
/// reporting and failure translation — lives in [ApiClient]; what remains here
/// is the parameter shaping and JSON mapping specific to publishers.
class PublisherSearchService {
  static final String _searchUrl = '${AppConstants.baseApiUrl}/publishers/search';

  /// Parameters the search endpoint understands. Anything else in a caller's
  /// map is dropped rather than forwarded, so a stray UI-only key cannot turn
  /// into a 400.
  static const Set<String> _allowedSearchKeys = {
    'q',
    'page',
    'limit',
    'type',
    'closed',
    'year_lower',
    'year_upper',
    'sort_by',
  };

  final ApiClient _api;

  PublisherSearchService({http.Client? client, ApiClient? api})
      : _api = api ??
            ApiClient(healthContext: 'publisher-search', client: client);

  Future<List<Publisher>> searchPublishers({
    String? query,
    String? type,
    bool? closed,
    int? yearLower,
    int? yearUpper,
    int? page,
    int? limit,
    String? sortBy,
  }) async {
    final result = await search({
      'q': query,
      'type': type,
      'closed': closed,
      'year_lower': yearLower,
      'year_upper': yearUpper,
      'page': page,
      'limit': limit,
      'sort_by': sortBy,
    });
    return result.publishers;
  }

  Future<PublisherSearchResult> search(Map<String, dynamic> params) {
    final cleaned = <String, dynamic>{
      for (final entry in params.entries)
        if (_allowedSearchKeys.contains(entry.key)) entry.key: entry.value,
    };

    return _api.getJson(
      ApiClient.uri(_searchUrl, cleaned),
      operation: 'search publishers',
      parse: (json) => PublisherSearchResult(
        publishers: parseDataList(json, Publisher.fromJson),
        total: totalCount(json),
      ),
    );
  }

  Future<Publisher> getPublisherFull(String id) {
    return _api.getJson(
      ApiClient.uri('${AppConstants.baseApiUrl}/publishers/$id/full'),
      operation: 'fetch publisher details',
      parse: (json) {
        final data = dataObject(json);
        if (data == null) {
          throw const FormatException('publisher response has no data object');
        }
        return Publisher.fromJson(data);
      },
    );
  }

  void dispose() => _api.close();
}

class PublisherSearchResult {
  final List<Publisher> publishers;
  final int total;

  PublisherSearchResult({required this.publishers, required this.total});
}
