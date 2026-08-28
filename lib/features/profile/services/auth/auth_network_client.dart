import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/profile/models/mb_profile.dart';

class AuthNetworkClient {
  final _logger = LoggingService.logger;
  static const _meEndpoint = '${AppConstants.baseApiUrl}/my/profile';
  static const _userInfoEndpoint = '${AppConstants.authBaseUrl}/userinfo';

  Future<MbProfile> fetchProfile(String accessToken) async {
    _logger.info('Fetching profile from API. Endpoint: $_userInfoEndpoint');
    try {
      final res = await http.get(
        Uri.parse(_userInfoEndpoint),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'User-Agent': AppConstants.userAgent,
        },
      ).timeout(const Duration(seconds: AppConstants.networkTimeoutSeconds));

      _logger.fine('Profile fetch (userinfo) status: ${res.statusCode}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        _logger.info('Successfully fetched profile from /userinfo');
        return MbProfile.fromUserInfo(body);
      } else {
        _logger.warning('Profile not found at /userinfo. Falling back to /me. Endpoint: $_meEndpoint');
        final meRes = await http.get(
          Uri.parse(_meEndpoint),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'User-Agent': AppConstants.userAgent,
          },
        ).timeout(const Duration(seconds: AppConstants.networkTimeoutSeconds));

        _logger.fine('Profile fetch (me) status: ${meRes.statusCode}');

        if (meRes.statusCode == 200) {
          final body = jsonDecode(meRes.body) as Map<String, dynamic>;
          _logger.info('Successfully fetched profile from /me');
          return MbProfile.fromMeResponse(body);
        } else {
          _logger.severe('Failed to fetch profile from /me. Status: ${meRes.statusCode}, Body: ${meRes.body}');
          throw AuthException(
            message: 'Failed to fetch profile from API',
            code: '${meRes.statusCode}',
          );
        }
      }
    } catch (e, st) {
      _logger.severe('Network error during profile fetch: $e\n$st');
      if (e is AppException) rethrow;
      throw AuthException(message: 'Network fetch profile failed', originalError: e, stackTrace: st);
    }
  }
}
