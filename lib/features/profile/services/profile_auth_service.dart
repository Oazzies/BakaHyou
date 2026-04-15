import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/mb_profile.dart';

class ProfileAuthService {
  static const _authorizationEndpoint = 'https://mangabaka.org/auth/oauth2/authorize';
  static const _tokenEndpoint = 'https://mangabaka.org/auth/oauth2/token';
  static const _endSessionEndpoint = 'https://mangabaka.org/auth/oauth2/end-session';
  static const _meEndpoint = 'https://api.mangabaka.dev/v1/me';
  static const _userInfoEndpoint = 'https://mangabaka.org/auth/oauth2/userinfo';

  static const _kAccessToken = 'mb_access_token';
  static const _kRefreshToken = 'mb_refresh_token';
  static const _kIdToken = 'mb_id_token';
  static const _kAccessTokenExp = 'mb_access_token_exp';

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String get _clientId => dotenv.env['BAKAHYOU_CLIENT_ID'] ?? '';
  String get _redirectUri => dotenv.env['BAKAHYOU_REDIRECT_URI'] ?? '';

  AuthorizationServiceConfiguration get _serviceConfig =>
      const AuthorizationServiceConfiguration(
        authorizationEndpoint: _authorizationEndpoint,
        tokenEndpoint: _tokenEndpoint,
        endSessionEndpoint: _endSessionEndpoint,
      );

  Future<bool> hasSession() async {
    final token = await _storage.read(key: _kAccessToken);
    return token != null && token.isNotEmpty;
  }

  Future<void> login() async {
    if (_clientId.isEmpty || _redirectUri.isEmpty) {
      throw Exception('Missing BAKAHYOU_CLIENT_ID or BAKAHYOU_REDIRECT_URI in .env');
    }

    final response = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        _clientId,
        _redirectUri,
        serviceConfiguration: _serviceConfig,
        scopes: const [
          'openid',
          'profile',
          'library.read',
          'library.write',
          'offline_access',
        ],
        promptValues: const ['consent'],
      ),
    );

    if (response == null || response.accessToken == null) {
      throw Exception('OAuth login failed: no access token returned');
    }

    await _persistTokens(response);
  }

  Future<void> _persistTokens(TokenResponse response) async {
    await _storage.write(key: _kAccessToken, value: response.accessToken);
    await _storage.write(key: _kRefreshToken, value: response.refreshToken);
    await _storage.write(key: _kIdToken, value: response.idToken);
    final exp = response.accessTokenExpirationDateTime?.toUtc().toIso8601String();
    if (exp != null) {
      await _storage.write(key: _kAccessTokenExp, value: exp);
    }
  }

  Future<void> _refreshIfNeeded() async {
    final expRaw = await _storage.read(key: _kAccessTokenExp);
    if (expRaw == null) return;

    final exp = DateTime.tryParse(expRaw);
    if (exp == null) return;

    if (DateTime.now().toUtc().isBefore(exp.subtract(const Duration(minutes: 1)))) {
      return;
    }

    final refreshToken = await _storage.read(key: _kRefreshToken);
    if (refreshToken == null || refreshToken.isEmpty) return;

    final response = await _appAuth.token(
      TokenRequest(
        _clientId,
        _redirectUri,
        serviceConfiguration: _serviceConfig,
        refreshToken: refreshToken,
        scopes: const ['openid', 'profile', 'library.read', 'library.write', 'offline_access'],
      ),
    );

    if (response != null && response.accessToken != null) {
      await _persistTokens(response);
    }
  }

  Future<MbProfile> fetchProfile() async {
    await _refreshIfNeeded();
    final accessToken = await _storage.read(key: _kAccessToken);

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Not logged in');
    }

    // Try /v1/me first
    final res = await http.get(
      Uri.parse(_meEndpoint),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'User-Agent': 'BakaHyou/0.0 (oazziesmail@gmail.com)',
      },
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return MbProfile.fromMeResponse(body);
    } else if (res.statusCode == 404) {
      // Fallback to OIDC userinfo endpoint
      final userinfoRes = await http.get(
        Uri.parse(_userInfoEndpoint),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'User-Agent': 'BakaHyou/0.0 (oazziesmail@gmail.com)',
        },
      );
      if (userinfoRes.statusCode == 200) {
        final body = jsonDecode(userinfoRes.body) as Map<String, dynamic>;
        return MbProfile.fromUserInfo(body);
      } else {
        throw Exception('Failed to fetch profile: ${userinfoRes.statusCode} ${userinfoRes.body}');
      }
    } else {
      throw Exception('Failed to fetch profile: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kIdToken);
    await _storage.delete(key: _kAccessTokenExp);
  }
}