import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';

/// The app's single dark theme — "Ink & Amber": near-black surfaces with one
/// accent colour, used as the "on" state wherever a control has one.
///
/// There is deliberately no light variant and no theme switching; the palette
/// lives in [AppConstants] and the type scale in [AppTypography].
class AppTheme {
  AppTheme._();

  /// Overlay style for the status and navigation bars.
  ///
  /// Applied both at startup (before any widget exists) and by an
  /// `AnnotatedRegion` around the app, which is what keeps it after a route
  /// or platform change resets it. Shared so the two cannot disagree.
  static const SystemUiOverlayStyle systemOverlay = SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  );

  static void applySystemOverlay() =>
      SystemChrome.setSystemUIOverlayStyle(systemOverlay);

  /// Builds the theme.
  ///
  /// [showTooltips] is baked in rather than read at each call site: Flutter
  /// has no "off" for tooltips, so disabling them means switching every
  /// tooltip to manual triggering — a theme-level change, and the reason the
  /// caller caches the result and rebuilds it only when the setting changes.
  static ThemeData build({required bool showTooltips}) {
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
      scaffoldBackgroundColor: AppConstants.primaryBackground,
      cardColor: AppConstants.secondaryBackground,
      // Dividers are drawn deliberately where they are wanted; the implicit
      // ones Material adds inside tab bars and dialogs are noise here.
      dividerColor: Colors.transparent,
      tooltipTheme: _tooltip(showTooltips),
      dialogTheme: _dialog(),
      bottomSheetTheme: _bottomSheet(),
      appBarTheme: _appBar(),
      inputDecorationTheme: _inputDecoration(),
      chipTheme: _chip(),
      cardTheme: _card(),
      textButtonTheme: _textButton(),
      elevatedButtonTheme: _elevatedButton(),
      outlinedButtonTheme: _outlinedButton(),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppConstants.textColor),
      ),
      switchTheme: _switch(),
      checkboxTheme: _checkbox(),
      radioTheme: _radio(),
      sliderTheme: _slider(),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppConstants.accentColor,
        linearTrackColor: AppConstants.tertiaryBackground,
        circularTrackColor: Colors.transparent,
      ),
      tabBarTheme: _tabBar(),
      snackBarTheme: _snackBar(),
      popupMenuTheme: _popupMenu(),
      listTileTheme: _listTile(),
      pageTransitionsTheme: _pageTransitions,
    );
  }

  /// Flutter cannot disable tooltips outright, so "off" is manual triggering
  /// plus a wait long enough never to elapse.
  static TooltipThemeData _tooltip(bool showTooltips) => TooltipThemeData(
        triggerMode: showTooltips ? null : TooltipTriggerMode.manual,
        waitDuration: showTooltips ? null : const Duration(days: 365),
      );

  static DialogThemeData _dialog() => DialogThemeData(
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
      );

  static BottomSheetThemeData _bottomSheet() => BottomSheetThemeData(
        backgroundColor: AppConstants.secondaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.largeRadius),
          ),
        ),
      );

  static AppBarTheme _appBar() => AppBarTheme(
        backgroundColor: AppConstants.primaryBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        // Material tints the bar as content scrolls under it; on a near-black
        // surface that reads as the bar changing colour at random.
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppConstants.textColor),
        titleTextStyle: AppTypography.display(
          color: AppConstants.textColor,
          fontSize: 20,
        ),
      );

  static InputDecorationTheme _inputDecoration() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      borderSide: BorderSide.none,
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: AppConstants.tertiaryBackground,
      border: border,
      enabledBorder: border,
      focusedBorder: border,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );
  }

  static ChipThemeData _chip() => ChipThemeData(
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
      );

  static CardThemeData _card() => CardThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        ),
        color: AppConstants.secondaryBackground,
      );

  // Buttons: amber caps for affirmative actions, muted caps for the rest.

  static TextButtonThemeData _textButton() => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.accentColor,
          textStyle: AppTypography.display(fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      );

  static ElevatedButtonThemeData _elevatedButton() => ElevatedButtonThemeData(
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
      );

  static OutlinedButtonThemeData _outlinedButton() => OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.textColor,
          side: BorderSide(color: AppConstants.borderColor),
          textStyle: AppTypography.display(fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        ),
      );

  // Amber is the "on" state everywhere a control has one.

  static WidgetStateProperty<Color> _whenSelected(Color on, Color off) =>
      WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? on : off,
      );

  static SwitchThemeData _switch() => SwitchThemeData(
        thumbColor: _whenSelected(
          AppConstants.onAccent,
          AppConstants.textMutedColor,
        ),
        trackColor: _whenSelected(
          AppConstants.accentColor,
          AppConstants.tertiaryBackground,
        ),
        trackOutlineColor: WidgetStateProperty.all(AppConstants.borderColor),
      );

  static CheckboxThemeData _checkbox() => CheckboxThemeData(
        fillColor:
            _whenSelected(AppConstants.accentColor, Colors.transparent),
        checkColor: WidgetStateProperty.all(AppConstants.onAccent),
        side: BorderSide(color: AppConstants.borderColor, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      );

  static RadioThemeData _radio() => RadioThemeData(
        fillColor: _whenSelected(
          AppConstants.accentColor,
          AppConstants.textMutedColor,
        ),
      );

  static SliderThemeData _slider() => SliderThemeData(
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
      );

  static TabBarThemeData _tabBar() => TabBarThemeData(
        labelColor: AppConstants.textColor,
        unselectedLabelColor: AppConstants.textMutedColor,
        labelStyle: AppTypography.display(fontSize: 13),
        unselectedLabelStyle: AppTypography.display(fontSize: 13),
        indicatorColor: AppConstants.accentColor,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      );

  static SnackBarThemeData _snackBar() => SnackBarThemeData(
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
      );

  static PopupMenuThemeData _popupMenu() => PopupMenuThemeData(
        color: AppConstants.secondaryBackground,
        surfaceTintColor: Colors.transparent,
        textStyle: AppTypography.sans(
          color: AppConstants.textColor,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.denseRadius),
        ),
      );

  static ListTileThemeData _listTile() => ListTileThemeData(
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
      );

  /// Page transitions match `AppTransitions` so system-pushed routes agree
  /// with the ones the app pushes itself.
  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
    },
  );
}
