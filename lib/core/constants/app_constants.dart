import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'MangaBaka';
  static const String appVersion = '3.1.0';
  static const String baseApiUrl = 'https://api.mangabaka.org/v1';

  // GitHub repository used by the in-app update system.
  static const String githubOwner = 'Oazzies';
  static const String githubRepo = 'MangaBaka-App';
  static const String githubReleasesApi =
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases';
  static const String authBaseUrl = 'https://mangabaka.org/auth/oauth2';
  static const String userAgent =
      '$appName/$appVersion (oazziesmail@gmail.com)';
  static const int networkTimeoutSeconds = 30;
  static const int maxRetries = 3;
  static const int rateLimitRetryDelaySeconds = 5;

  static const int defaultPageLimit = 20;
  static const int libraryPageLimit = 100; // entries per page (API max)
  static const int libraryMaxPages = 10000; // API max pages
  static const double scrollThresholdPx = 100;

  // ---------------------------------------------------------------------------
  // Palette — "Ink & Emerald". Single dark theme: near-black canvas, green
  // accent. These are read in ~114 files; the names are kept from the old
  // theme system so call sites did not have to churn.
  // ---------------------------------------------------------------------------
  static const Color primaryBackground = Color(0xFF0B0B0B);
  static const Color secondaryBackground = Color(0xFF151515);
  static const Color tertiaryBackground = Color(0xFF1F1F1F);
  static const Color accentColor = Color(0xFF5BBD74);
  static const Color primaryAccent = Color(0xFF007835);

  /// Ink used on top of [accentColor] fills (buttons, active nav, badges).
  static const Color onAccent = Color(0xFF0B140D);
  static const Color starColor = Color(0xFFFBD24B);

  static const Color borderColor = Color(0xFF262626);
  static const Color successColor = Color(0xFF4ADE80);
  static const Color warningColor = Color(0xFFFBD24B);
  static const Color errorColor = Color(0xFFF87171);
  static const Color infoColor = Color(0xFF60A5FA);
  static const Color textColor = Color(0xFFFFFFFF);
  static const Color textMutedColor = Color(0xFF8E8E8E);

  static const double horizontalPadding = 16.0;
  static const double verticalPadding = 16.0;
  static const double cardRadius = 20.0;
  static const double largeRadius = 24.0;
  static const double denseRadius = 14.0;
  static const double pillRadius = 999.0;

  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x66000000), blurRadius: 32, offset: Offset(0, 8)),
  ];

  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);

  static const Set<String> libraryStates = {
    'reading',
    'paused',
    'completed',
    'plan_to_read',
    'dropped',
    'rereading',
    'considering',
  };

  static const List<String> oauthScopes = [
    'openid',
    'profile',
    'library.read',
    'library.write',
    'offline_access',
  ];

  static const String prefixStorageKey = 'mangabaka_app_';
  static const String lastSyncKey = '${prefixStorageKey}last_sync';
  static const String userPreferencesKey = '${prefixStorageKey}preferences';

  static const Duration debounceDelay = Duration(milliseconds: 500);

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Color getColorForState(String state) {
    switch (state) {
      case 'reading':
      case 'rereading':
        return successColor;
      case 'completed':
        return textColor;
      case 'paused':
        return warningColor;
      case 'dropped':
        return errorColor;
      case 'plan_to_read':
        return infoColor;
      case 'considering':
        return accentColor;
      default:
        return textMutedColor;
    }
  }

  static Color getOnColorForState(String state) {
    switch (state) {
      case 'reading':
      case 'rereading':
      case 'considering':
        return onAccent;
      case 'completed':
      case 'paused':
        return primaryBackground;
      case 'dropped':
      case 'plan_to_read':
        return textColor;
      default:
        return textColor;
    }
  }
}
