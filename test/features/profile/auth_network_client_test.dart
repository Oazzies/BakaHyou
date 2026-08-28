import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/profile/services/auth/auth_network_client.dart';

void main() {
  setUp(() async {
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());
  });

  group('AuthNetworkClient.fetchProfile', () {
    test('parses /userinfo response on 200', () async {
      Uri? captured;
      Map<String, String>? capturedHeaders;
      final mockClient = MockClient((req) async {
        captured = req.url;
        capturedHeaders = req.headers;
        return http.Response(
          jsonEncode({
            'sub': 'user-1',
            'preferred_username': 'oazzie',
            'nickname': 'Oazzie',
            'scope': 'openid profile',
          }),
          200,
        );
      });

      final profile = await http.runWithClient(
        () => AuthNetworkClient().fetchProfile('access-tok'),
        () => mockClient,
      );

      expect(profile.id, 'user-1');
      expect(profile.preferredUsername, 'oazzie');
      expect(profile.nickname, 'Oazzie');
      expect(profile.scopes, ['openid', 'profile']);

      expect(captured!.path, endsWith('/userinfo'));
      expect(capturedHeaders!['Authorization'], 'Bearer access-tok');
    });

    test('falls back to /my/profile when /userinfo fails', () async {
      final calls = <String>[];
      final mockClient = MockClient((req) async {
        calls.add(req.url.path);
        if (req.url.path.endsWith('/userinfo')) {
          return http.Response('not found', 404);
        }
        return http.Response(
          jsonEncode({
            'data': {
              'id': 'user-2',
              'role': 'admin',
              'scopes': ['admin', 'user'],
              'preferred_username': 'meuser',
            },
          }),
          200,
        );
      });

      final profile = await http.runWithClient(
        () => AuthNetworkClient().fetchProfile('tok'),
        () => mockClient,
      );

      expect(profile.id, 'user-2');
      expect(profile.role, 'admin');
      expect(profile.scopes, ['admin', 'user']);
      expect(calls.any((p) => p.endsWith('/userinfo')), isTrue);
      expect(calls.any((p) => p.endsWith('/my/profile')), isTrue);
    });

    test('throws AuthException when both endpoints fail', () async {
      final mockClient = MockClient((_) async => http.Response('nope', 500));
      await expectLater(
        http.runWithClient(
          () => AuthNetworkClient().fetchProfile('tok'),
          () => mockClient,
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('throws AuthException when network fails', () async {
      final mockClient = MockClient((_) async {
        throw Exception('boom');
      });
      await expectLater(
        http.runWithClient(
          () => AuthNetworkClient().fetchProfile('tok'),
          () => mockClient,
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
