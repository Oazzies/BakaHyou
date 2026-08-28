import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/api_client.dart';
import 'package:mangabaka_app/core/network/api_envelope.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/home/models/for_you_readiness.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';

export 'package:mangabaka_app/features/home/models/for_you_readiness.dart';

/// Backs the Home feed's discovery rails.
///
/// Every rail here reads from v2 (`discover/*` and `series/search`), which
/// returns the "lean" series shape: titles as an array, `type`/`year` present,
/// covers as a sized map. [Series.fromSimilarJson] already normalises that
/// shape, so the rails reuse the app's normal [Series] model rather than
/// introducing a parallel one.
///
/// **Every method degrades to empty rather than throwing.** Home is a wall of
/// independent rails; one that cannot load should render as absent while the
/// others fill in, so a failure here is logged and swallowed by design.
class HomeService {
  static final _logger = LoggingService.logger;

  static const String _v2Base = 'https://api.mangabaka.org/v2';

  final ApiClient _api;

  HomeService({http.Client? client, ApiClient? api})
      : _api = api ?? ApiClient(healthContext: 'home', client: client);

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
    if (allowed.isEmpty) return const {};
    return {'content_rating': allowed};
  }

  Uri _v2Uri(String path, Map<String, dynamic> params) =>
      ApiClient.uri('$_v2Base$path', {...params, ..._contentParams()});

  /// Series gaining the most library adds recently. Public and CDN-cached.
  Future<List<Series>> fetchRising({int limit = 20, int windowDays = 7}) {
    return _fetchRail(
      _v2Uri('/series/discover/rising', {
        'limit': limit,
        'window_days': windowDays,
      }),
      'rising',
    );
  }

  /// Highly rated series that comparatively few readers have found.
  Future<List<Series>> fetchHiddenGems({int limit = 20}) {
    return _fetchRail(
      _v2Uri('/series/discover/hidden-gems', {'limit': limit}),
      'hidden gems',
    );
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
  }) {
    return _fetchRail(
      _v2Uri('/series/search', {
        'sort_by': windowDays == 30 ? 'trending_30d' : 'trending_7d',
        'limit': limit,
        'type': type,
      }),
      'trending',
    );
  }

  /// Series that started publishing within the last year, with at least a
  /// minimal rating so unrated stubs don't crowd the rail.
  Future<List<Series>> fetchNewReleases({int limit = 20}) {
    final lower = DateTime.now().toUtc().subtract(const Duration(days: 365));
    return _fetchRail(
      _v2Uri('/series/search', {
        'sort_by': 'published_start_date_desc',
        'published_start_date_lower': _isoDate(lower),
        'rating_lower': 1,
        'limit': limit,
      }),
      'new releases',
    );
  }

  /// Personalised recommendations. Returns an empty list when logged out or
  /// when the profile is not warm enough to rank against.
  Future<List<Series>> fetchForYou({int limit = 20}) async {
    final headers = await _authHeaders();
    if (headers == null) return const [];

    // No `exclude_user_library` here: despite the name it takes a 32-char
    // user id (and is flagged alpha), and recommendations already leave the
    // caller's own library out.
    return _fetchRail(
      ApiClient.uri(
        '${AppConstants.baseApiUrl}/my/series/recommendations',
        {'limit': limit, ..._contentParams()},
      ),
      'for-you',
      headers: headers,
    );
  }

  /// Cheap probe for whether the taste profile behind "For You" is warm.
  ///
  /// Null means "don't show the rail and don't explain why" — logged out, or
  /// the probe itself failed.
  Future<ForYouReadiness?> fetchForYouReadiness() async {
    final headers = await _authHeaders();
    if (headers == null) return null;

    try {
      final readiness = await _api.getJson(
        ApiClient.uri(
          '${AppConstants.baseApiUrl}/my/series/recommendations/status',
        ),
        operation: 'probe For-You readiness',
        parse: (json) => ForYouReadiness.fromJson(
          (json as Map).cast<String, dynamic>(),
        ),
        headers: headers,
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

  /// The bearer header for the signed-in user, or null when logged out or the
  /// token could not be refreshed — in which case the caller shows nothing
  /// rather than an error, since the rail is only meaningful when signed in.
  Future<Map<String, String>?> _authHeaders() async {
    final auth = getIt<ProfileAuthService>();
    if (!auth.isLoggedIn) return null;
    try {
      final token = await auth.getValidAccessToken();
      return {'Authorization': 'Bearer $token'};
    } catch (e) {
      _logger.warning('Could not obtain access token for Home rail: $e');
      return null;
    }
  }

  /// Fetches one rail. A dead rail never takes the whole Home screen down
  /// with it: any failure logs and yields an empty list, which the Home screen
  /// renders as an absent section.
  Future<List<Series>> _fetchRail(
    Uri uri,
    String label, {
    Map<String, String>? headers,
  }) async {
    try {
      final series = await _api.withContext('home:$label').getJson(
            uri,
            operation: 'fetch $label',
            parse: (json) => parseDataList(json, Series.fromSimilarJson),
            headers: headers,
          );
      _logger.info('HomeService $label returned ${series.length} series');
      return series;
    } catch (e) {
      _logger.warning('HomeService failed to fetch $label: $e');
      return const [];
    }
  }

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  void dispose() => _api.close();
}
