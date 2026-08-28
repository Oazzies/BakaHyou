import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mangabaka_app/features/navigation/screens/main_screen.dart';
import 'package:mangabaka_app/features/navigation/screens/onboarding_screen.dart';
import 'package:mangabaka_app/features/navigation/screens/animated_splash_screen.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/shared/widgets/app_shortcuts.dart';
import 'package:mangabaka_app/features/updates/services/update_service.dart';
import 'package:mangabaka_app/features/updates/widgets/update_dialog.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    windowManager.waitUntilReadyToShow(null, () async {
      await windowManager.setMinimumSize(const Size(500, 700));
    });
  }

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await LoggingService.setup();

  // Handle Flutter framework errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    LoggingService.logger.severe(
      'Flutter Error: ${details.exceptionAsString()}',
      details.exception,
      details.stack,
    );
  };

  // Handle platform/async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    LoggingService.logger.severe('Unhandled Platform Error', error, stack);
    return true; // Error has been handled
  };

  await dotenv.load();
  setupServiceLocator();

  await getIt<ProfileAuthService>().init();
  await getIt<MetadataService>().init();

  await Future.wait([
    SettingsManager().init(),
    LocalizationService().init(),
  ]);

  _updateSystemUI();

  runApp(const MangaBakaApp());
}

void _updateSystemUI() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
}

class MangaBakaApp extends StatefulWidget {
  const MangaBakaApp({super.key});

  @override
  State<MangaBakaApp> createState() => _MangaBakaAppState();
}

class _MangaBakaAppState extends State<MangaBakaApp> {
  ThemeData? _cachedTheme;
  bool? _lastShowTooltips;
  bool _showSplash = true;

  ThemeData _buildTheme(bool showTooltips) {
    final base = ThemeData.dark(useMaterial3: true);
    final textBase =
        Typography.material2021(platform: TargetPlatform.android).white;

    return base.copyWith(
      textTheme: AppTypography.textTheme(textBase),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryAccent,
        brightness: Brightness.dark,
        surface: AppConstants.primaryBackground,
        primary: AppConstants.accentColor,
        error: AppConstants.errorColor,
      ),
      tooltipTheme: TooltipThemeData(
        triggerMode: showTooltips ? null : TooltipTriggerMode.manual,
        waitDuration: showTooltips ? null : const Duration(days: 365),
      ),
      scaffoldBackgroundColor: AppConstants.primaryBackground,
      cardColor: AppConstants.secondaryBackground,
      dialogTheme: DialogThemeData(
        backgroundColor: AppConstants.secondaryBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        ),
        titleTextStyle: AppTypography.display(
          color: AppConstants.textColor,
          fontSize: 18,
        ),
        contentTextStyle: AppTypography.sans(
          color: AppConstants.textMutedColor,
          fontSize: 15,
          height: 1.45,
        ),
      ),
      dividerColor: Colors.transparent,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppConstants.secondaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.largeRadius),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppConstants.primaryBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppConstants.textColor),
        titleTextStyle: AppTypography.display(
          color: AppConstants.textColor,
          fontSize: 20,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.tertiaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppConstants.tertiaryBackground,
        selectedColor: AppConstants.accentColor,
        side: BorderSide.none,
        labelStyle: AppTypography.display(
          color: AppConstants.textColor,
          fontSize: 12,
        ),
        secondaryLabelStyle: AppTypography.display(
          color: AppConstants.onAccent,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        ),
        color: AppConstants.secondaryBackground,
      ),
      // Buttons: amber caps for affirmative actions, muted caps for the rest.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.accentColor,
          textStyle: AppTypography.display(fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.accentColor,
          foregroundColor: AppConstants.onAccent,
          elevation: 0,
          textStyle: AppTypography.display(fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.textColor,
          side: BorderSide(color: AppConstants.borderColor),
          textStyle: AppTypography.display(fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppConstants.textColor),
      ),
      // Amber is the "on" state everywhere a control has one.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppConstants.onAccent
                : AppConstants.textMutedColor),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppConstants.accentColor
                : AppConstants.tertiaryBackground),
        trackOutlineColor:
            WidgetStateProperty.all(AppConstants.borderColor),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppConstants.accentColor
                : Colors.transparent),
        checkColor: WidgetStateProperty.all(AppConstants.onAccent),
        side: BorderSide(color: AppConstants.borderColor, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppConstants.accentColor
                : AppConstants.textMutedColor),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppConstants.accentColor,
        inactiveTrackColor: AppConstants.tertiaryBackground,
        thumbColor: AppConstants.accentColor,
        overlayColor: AppConstants.accentColor.withValues(alpha: 0.16),
        valueIndicatorColor: AppConstants.accentColor,
        valueIndicatorTextStyle: AppTypography.display(
          color: AppConstants.onAccent,
          fontSize: 13,
        ),
        trackHeight: 4,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppConstants.accentColor,
        linearTrackColor: AppConstants.tertiaryBackground,
        circularTrackColor: Colors.transparent,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppConstants.textColor,
        unselectedLabelColor: AppConstants.textMutedColor,
        labelStyle: AppTypography.display(fontSize: 13),
        unselectedLabelStyle: AppTypography.display(fontSize: 13),
        indicatorColor: AppConstants.accentColor,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppConstants.tertiaryBackground,
        contentTextStyle: AppTypography.sans(
          color: AppConstants.textColor,
          fontSize: 14,
        ),
        actionTextColor: AppConstants.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.denseRadius),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppConstants.secondaryBackground,
        surfaceTintColor: Colors.transparent,
        textStyle: AppTypography.sans(
          color: AppConstants.textColor,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.denseRadius),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppConstants.textMutedColor,
        textColor: AppConstants.textColor,
        titleTextStyle: AppTypography.sans(
          color: AppConstants.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: AppTypography.sans(
          color: AppConstants.textMutedColor,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.denseRadius),
        ),
      ),
      // Page transitions match AppTransitions so system-pushed routes agree
      // with the ones the app pushes itself.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Checks GitHub for a newer release and, if found, shows the update dialog.
  /// Runs at most once per app launch.
  Future<void> _checkForAppUpdate() async {
    final service = getIt<UpdateService>();
    if (!service.shouldPrompt()) return;
    final release = await service.checkForUpdate();
    if (release == null) return;
    final ctx = AppConstants.navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    await UpdateDialog.show(ctx, release);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
                SettingsManager(),
        getIt<ProfileAuthService>(),
      ]),
      builder: (context, _) {
        final hasCompletedOnboarding = SettingsManager().hasCompletedOnboarding;
        final isLoggedIn = getIt<ProfileAuthService>().isLoggedIn;
        final showTooltips = SettingsManager().showTooltips;

        if (_cachedTheme == null || _lastShowTooltips != showTooltips) {
          _lastShowTooltips = showTooltips;
          _cachedTheme = _buildTheme(showTooltips);
        }

        final Widget content = (hasCompletedOnboarding || isLoggedIn)
            ? MainScreen()
            : const OnboardingScreen();

        return ExcludeSemantics(
          excluding: Platform.isWindows,
          child: MaterialApp(
            navigatorKey: AppConstants.navigatorKey,
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return AppShortcuts(child: child!);
            },
            theme: _cachedTheme,
            home: AnnotatedRegion<SystemUiOverlayStyle>(
              value: const SystemUiOverlayStyle(
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarContrastEnforced: false,
                systemNavigationBarIconBrightness: Brightness.light,
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              ),
              child: Stack(
                children: [
                  content,
                  if (_showSplash)
                    AnimatedSplashOverlay(
                      onComplete: () {
                        setState(() {
                          _showSplash = false;
                        });
                        // Once the splash clears (and the user is past
                        // onboarding), check GitHub for a newer release.
                        if (hasCompletedOnboarding || isLoggedIn) {
                          _checkForAppUpdate();
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
