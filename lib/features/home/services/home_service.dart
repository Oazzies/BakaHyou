import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/backend_health_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';

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

/// Backs the Home feed's discovery rails.
///
/// Every rail here reads from v2 (`discover/*` and `series/search`), which
/// returns the "lean" series shape: titles as an array, `type`/`year` present,
/// covers as a sized map. [Series.fromSimilarJson] already normalises that
/// shape, so the rails reuse the app's normal [Series] model rather than
/// introducing a parallel one.
class HomeService {
  static final _logger = LoggingService.logger;

  static const String _v2Base = 'https://api.mangabaka.org/v2';

  final http.Client _client;

  HomeService({http.Client? client}) : _client = client ?? http.Client();

  static const Duration _timeout =
      Duration(seconds: AppConstants.networkTimeoutSeconds);

  Map<String, String> get _headers => {
        'User-Agent': AppConstants.userAgent,
      };

  /// Content-rating preferences apply to every discovery rail, so an unwanted
  /// rating never reaches the Home screen in the first place.
  ///
  /// [SettingsManager.contentPreferences] is an allow-list (the ratings the
  /// user wants to see), which maps onto the API's `content_rating` filter —
  /// the same mapping `MixController` uses.
  Map<String, dynamic> _contentParams() {
    final allowed = SettingsManager()
        .contentPreferences
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    if (allowed.isEmpty) return {};
    return {'content_rating': allowed};
  }

  Uri _v2Uri(String path, Map<String, dynamic> params) {
    final query = <String, dynamic>{...params, ..._contentParams()};
    final normalized = <String, dynamic>{};
    query.forEach((key, value) {
      if (value is List) {
        normalized[key] = value.map((e) => e.toString()).toList();
      } else if (value != null) {
        normalized[key] = value.toString();
      }
    });
    return Uri.parse('$_v2Base$path').replace(queryParameters: normalized);
  }

  List<Series> _parseSeriesList(String body) {
    final decoded = json.decode(body) as Map<String, dynamic>;
    final data = decoded['data'] as List? ?? const [];
    return data
        .whereType<Map>()
        .map((e) => Series.fromSimilarJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// Series gaining the most library adds recently. Public and CDN-cached.
  Future<List<Series>> fetchRising({int limit = 20, int windowDays = 7}) async {
    final uri = _v2Uri('/series/discover/rising', {
      'limit': limit,
      'window_days': windowDays,
    });
    return _fetchRail(uri, 'rising');
  }

  /// Highly rated series that comparatively few readers have found.
  Future<List<Series>> fetchHiddenGems({int limit = 20}) async {
    final uri = _v2Uri('/series/discover/hidden-gems', {'limit': limit});
    return _fetchRail(uri, 'hidden gems');
  }

  /// Series gaining popularity the fastest. [windowDays] is 7 or 30; [type] is
  /// one of manga|manhwa|manhua|novel, or null for every type.
  ///
  /// There is no `discover/trending` endpoint — the web surface builds this off
  /// the `trending_7d` / `trending_30d` search sorts, so the app does the same.
  Future<List<Series>> fetchTrending({
    String? type,
    int windowDays = 7,
    int limit = 20,
  }) async {
    final uri = _v2Uri('/series/search', {
      'sort_by': windowDays == 30 ? 'trending_30d' : 'trending_7d',
      'limit': limit,
      if (type != null && type.isNotEmpty) 'type': type,
    });
    return _fetchRail(uri, 'trending');
  }

  /// Series that started publishing within the last year, with at least a
  /// minimal rating so unrated stubs don't crowd the rail.
  Future<List<Series>> fetchNewReleases({int limit = 20}) async {
    final lower = DateTime.now().toUtc().subtract(const Duration(days: 365));
    final lowerStr = '${lower.year.toString().padLeft(4, '0')}-'
        '${lower.month.toString().padLeft(2, '0')}-'
        '${lower.day.toString().padLeft(2, '0')}';
    final uri = _v2Uri('/series/search', {
      'sort_by': 'published_start_date_desc',
      'published_start_date_lower': lowerStr,
      'rating_lower': 1,
      'limit': limit,
    });
    return _fetchRail(uri, 'new releases');
  }

  Future<List<Series>> _fetchRail(Uri uri, String label) async {
    _logger.info('HomeService fetching $label: $uri');
    try {
      final response =
          await _client.get(uri, headers: _headers).timeout(_timeout);
      reportApiOutcome(
        ok: !isServerErrorStatus(response.statusCode),
        context: 'home:$label',
        statusCode: response.statusCode,
      );
      if (response.statusCode != 200) {
        _logger.warning(
          'HomeService $label returned ${response.statusCode}',
        );
        return const [];
      }
      final parsed = _parseSeriesList(response.body);
      _logger.info('HomeService $label returned ${parsed.length} series');
      return parsed;
    } catch (e) {
      // A dead rail should never take the whole Home screen down with it.
      _logger.warning('HomeService failed to fetch $label: $e');
      reportApiOutcome(ok: false, context: 'home:$label', error: e);
      return const [];
    }
  }

  /// Cheap probe for whether the taste profile behind "For You" is warm.
  Future<ForYouReadiness?> fetchForYouReadiness() async {
    final auth = getIt<ProfileAuthService>();
    if (!auth.isLoggedIn) return null;
    try {
      final token = await auth.getValidAccessToken();
      final uri =
          Uri.parse('${AppConstants.baseApiUrl}/my/series/recommendations/status');
      final response = await _client.get(uri, headers: {
        ..._headers,
        'Authorization': 'Bearer $token',
      }).timeout(_timeout);
      if (response.statusCode != 200) {
        _logger.warning(
          'For-You readiness returned ${response.statusCode}',
        );
        return null;
      }
      final readiness = ForYouReadiness.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
      _logger.info(
        'For-You readiness: coldStart=${readiness.coldStart} '
        'stale=${readiness.profileStale} library=${readiness.libraryCount}',
      );
      return readiness;
    } catch (e) {
      _logger.warning('For-You readiness probe failed: $e');
      return null;
    }
  }

  /// Personalised recommendations. Returns an empty list when logged out or
  /// when the profile is not warm enough to rank against.
  Future<List<Series>> fetchForYou({int limit = 20}) async {
    final auth = getIt<ProfileAuthService>();
    if (!auth.isLoggedIn) return const [];
    try {
      final token = await auth.getValidAccessToken();
      // No `exclude_user_library` here: despite the name it takes a 32-char
      // user id (and is flagged alpha), and recommendations already leave the
      // caller's own library out.
      final params = <String, dynamic>{
        'limit': limit.toString(),
        ..._contentParams(),
      };
      final normalized = <String, dynamic>{};
      params.forEach((key, value) {
        normalized[key] =
            value is List ? value.map((e) => e.toString()).toList() : value;
      });
      final uri = Uri.parse('${AppConstants.baseApiUrl}/my/series/recommendations')
          .replace(queryParameters: normalized);
      _logger.info('HomeService fetching for-you: $uri');
      final response = await _client.get(uri, headers: {
        ..._headers,
        'Authorization': 'Bearer $token',
      }).timeout(_timeout);
      if (response.statusCode != 200) {
        _logger.warning('For-You returned ${response.statusCode}');
        return const [];
      }
      final parsed = _parseSeriesList(response.body);
      _logger.info('HomeService for-you returned ${parsed.length} series');
      return parsed;
    } catch (e) {
      _logger.warning('HomeService failed to fetch for-you: $e');
      return const [];
    }
  }
}
