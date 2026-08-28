import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/logout_dialog.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_components.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/profile/screens/settings_category_screen.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/general_settings_dialogs.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/content_preferences_dialog.dart';
import 'package:mangabaka_app/features/profile/screens/logs_screen.dart';
import 'package:mangabaka_app/features/profile/screens/translation_credits_screen.dart';
import 'package:mangabaka_app/features/navigation/screens/onboarding_screen.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/list_customization_settings.dart';

// ---------------------------------------------------------------------------
// Shared helper — shows a category as a dialog in landscape, pushes in portrait
// ---------------------------------------------------------------------------

void _showOrNavigate(
  BuildContext context, {
  required String title,
  Listenable? listenable,
  required List<Widget> Function(BuildContext) buildChildren,
}) {
  final isLandscape =
      MediaQuery.of(context).orientation == Orientation.landscape;

  Widget buildInner(BuildContext ctx) {
    final children = buildChildren(ctx);
    return isLandscape
        ? Column(mainAxisSize: MainAxisSize.min, children: children)
        : SettingsCategoryScreen(title: title, children: children);
  }

  final content = listenable != null
      ? ListenableBuilder(
          listenable: listenable,
          builder: (ctx, _) => buildInner(ctx),
        )
      : Builder(builder: buildInner);

  if (isLandscape) {
    final dialogState = context.findAncestorStateOfType<_SettingsDialogState>();
    if (dialogState != null) {
      dialogState.pushCategory(title, content);
      return;
    }

    // Fallback if not inside _SettingsDialog
    Navigator.pop(context);
    // Defer showing the new dialog until after the current one's pop animation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rootCtx = AppConstants.navigatorKey.currentContext;
      if (rootCtx != null) {
        SettingsCategoryScreen.showAsDialog(
          rootCtx,
          title: title,
          content: content,
          onBack: () =>
              SettingsScreen.show(AppConstants.navigatorKey.currentContext!),
        );
      }
    });
  } else {
    Navigator.push(context, MaterialPageRoute(builder: (_) => content));
  }
}

// ---------------------------------------------------------------------------
// Shared settings groups (used by both full-screen and dialog)
// ---------------------------------------------------------------------------

/// Wraps a built settings list so its cards fade and rise in sequence.
/// Spacers are passed through untouched so the rhythm of the list is kept.
List<Widget> _staggered(List<Widget> children) {
  var index = 0;
  return [
    for (final child in children)
      if (child is SizedBox)
        child
      else
        MbEntrance(index: index++, child: child),
  ];
}

List<Widget> _buildSettingsGroups(
  BuildContext context,
  LocalizationService l10n,
  ProfileAuthService auth,
) {
  final isSmallDevice = MediaQuery.of(context).size.width < 600;
  return [
    SettingsGroup(
      children: [
        SettingsItem(
          icon: Icons.settings_outlined,
          title: l10n.translate('general'),
          subtitle: l10n.translate(
            isSmallDevice
                ? 'general_settings_subtitle_mobile'
                : 'general_settings_subtitle',
          ),
          onTap: () => _navigateToGeneral(context, l10n),
          isFirst: true,
          isLast: true,
          iconColor: AppConstants.textColor, // White
        ),
      ],
    ),
    const SizedBox(height: 16),
    SettingsGroup(
      children: [
        SettingsItem(
          icon: Icons.grid_view,
          title: l10n.translate('list_customization'),
          subtitle: l10n.translate('list_customization_subtitle'),
          onTap: () => _navigateToListCustomization(context, l10n),
          isFirst: true,
          isLast: true,
          iconColor: AppConstants.infoColor, // Blue
        ),
      ],
    ),
    const SizedBox(height: 16),
    SettingsGroup(
      children: [
        SettingsItem(
          icon: Icons.library_books_outlined,
          title: l10n.translate('content'),
          subtitle: l10n.translate('library_settings_subtitle'),
          onTap: () => _navigateToContent(context, l10n),
          isFirst: true,
          isLast: true,
          iconColor: AppConstants.starColor, // Yellow
        ),
      ],
    ),
    const SizedBox(height: 16),
    if (auth.isLoggedIn) ...[
      SettingsGroup(
        children: [
          SettingsItem(
            icon: Icons.person_outline,
            title: l10n.translate('account'),
            subtitle: l10n.translate('account_settings_subtitle'),
            onTap: () => _navigateToAccount(context, l10n, auth),
            isFirst: true,
            isLast: true,
            iconColor: AppConstants.accentColor, // Green
          ),
        ],
      ),
      const SizedBox(height: 16),
    ],
    SettingsGroup(
      children: [
        SettingsItem(
          icon: Icons.code,
          title: l10n.translate('advanced_settings'),
          subtitle: l10n.translate('advanced_settings_subtitle'),
          onTap: () => _navigateToAdvanced(context, l10n),
          isFirst: true,
          isLast: true,
          iconColor: AppConstants.errorColor, // Red
        ),
      ],
    ),
    const SizedBox(height: 32),
    SettingsGroup(
      children: [
        SettingsItem(
          icon: Icons.discord,
          title: l10n.translate('discord'),
          onTap: () => launchUrl(
            Uri.parse('https://discord.gg/mangabaka'),
            mode: LaunchMode.externalApplication,
          ),
          trailing: Icon(
            Icons.open_in_new,
            color: AppConstants.textMutedColor,
            size: 18,
          ),
          isFirst: true,
          iconColor: const Color(0xFF5865F2), // Discord Blue
        ),
        const SettingsDivider(),
        SettingsItem(
          icon: Icons.code,
          title: l10n.translate('github'),
          onTap: () => launchUrl(
            Uri.parse('https://github.com/oazzies/MangaBaka-App'),
            mode: LaunchMode.externalApplication,
          ),
          trailing: Icon(
            Icons.open_in_new,
            color: AppConstants.textMutedColor,
            size: 18,
          ),
          iconColor: const Color(0xFFAC4BFF), // GitHub Purple
        ),
        const SettingsDivider(),
        SettingsItem(
          icon: Icons.info_outline,
          title: l10n.translate('translation_credits'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TranslationCreditsScreen(),
            ),
          ),
          isLast: true,
          iconColor: AppConstants.textColor, // White
        ),
      ],
    ),
  ];
}

// ---------------------------------------------------------------------------
// Navigation helpers
// ---------------------------------------------------------------------------

void _navigateToGeneral(BuildContext context, LocalizationService l10n) {
  _showOrNavigate(
    context,
    title: l10n.translate('general'),
    listenable: Listenable.merge([LocalizationService(), SettingsManager()]),
    buildChildren: (ctx) {
      final l10n = LocalizationService();
      final isSmallDevice = MediaQuery.of(ctx).size.width < 600;
      return [
        SettingsGroup(
          children: [
            SettingsItem(
              icon: Icons.language,
              title: l10n.translate('language'),
              subtitle: GeneralSettingsDialogs.getLanguageName(
                l10n.currentLanguage,
              ),
              onTap: () =>
                  GeneralSettingsDialogs.showLanguageSelectionDialog(ctx),
              isFirst: true,
              iconColor: AppConstants.infoColor, // Blue
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.start,
              title: l10n.translate('start_page'),
              subtitle: GeneralSettingsDialogs.getAppStartPageName(
                SettingsManager().defaultStartPage,
              ),
              onTap: () =>
                  GeneralSettingsDialogs.showAppStartPageSelectionDialog(ctx),
              iconColor: AppConstants.accentColor, // Green
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.stay_primary_landscape_outlined,
              title: l10n.translate('landscape_appbar_position'),
              subtitle: GeneralSettingsDialogs.getLandscapeAppBarPositionName(
                SettingsManager().landscapeAppBarPosition,
              ),
              onTap: () =>
                  GeneralSettingsDialogs.showLandscapeAppBarPositionDialog(ctx),
              iconColor: const Color(0xFFAC4BFF), // Purple
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.translate,
              title: l10n.translate('title_language'),
              subtitle: GeneralSettingsDialogs.getTitleLanguageName(
                SettingsManager().defaultTitleLanguage,
              ),
              onTap: () =>
                  GeneralSettingsDialogs.showTitleLanguageSelectionDialog(ctx),
              iconColor: const Color(0xFFD71F75), // Pink
            ),
            if (!isSmallDevice) ...[
              const SettingsDivider(),
              SettingsSwitchItem(
                icon: Icons.help_outline,
                title: l10n.translate('show_tooltips'),
                subtitle: l10n.translate('show_tooltips_subtext'),
                value: SettingsManager().showTooltips,
                onChanged: (val) => SettingsManager().setShowTooltips(val),
                iconColor: AppConstants.starColor, // Yellow
              ),
            ],
            const SettingsDivider(),
            SettingsSwitchItem(
              icon: Icons.search,
              title: l10n.translate('auto_suggest_browse'),
              subtitle: l10n.translate('auto_suggest_browse_subtitle'),
              value: SettingsManager().autoSuggestBrowse,
              onChanged: (val) => SettingsManager().setAutoSuggestBrowse(val),
              isLast: true,
              iconColor: const Color(0xFF4FBEC4), // Teal
            ),
          ],
        ),
      ];
    },
  );
}

void _navigateToListCustomization(BuildContext context, LocalizationService l10n) {
  _showOrNavigate(
    context,
    title: l10n.translate('list_customization'),
    listenable: SettingsManager(),
    buildChildren: (ctx) => [
      ListCustomizationSettings(l10n: l10n),
    ],
  );
}

void _navigateToContent(BuildContext context, LocalizationService l10n) {
  _showOrNavigate(
    context,
    title: l10n.translate('content'),
    listenable: SettingsManager(),
    buildChildren: (ctx) => [
      SettingsGroup(
        children: [
          SettingsItem(
            icon: Icons.star_outline,
            title: l10n.translate('rating_step'),
            subtitle: GeneralSettingsDialogs.getRatingSliderStepName(
              SettingsManager().ratingSliderStep,
            ),
            onTap: () =>
                GeneralSettingsDialogs.showRatingSliderStepSelectionDialog(ctx),
            isFirst: true,
            iconColor: AppConstants.starColor, // Yellow
          ),
          const SettingsDivider(),
          SettingsItem(
            icon: Icons.tab,
            title: l10n.translate('library_default'),
            subtitle: GeneralSettingsDialogs.getLibraryTabName(
              SettingsManager().addLibraryDefaultTab,
            ),
            onTap: () =>
                GeneralSettingsDialogs.showAddLibraryDefaultTabSelectionDialog(
                  ctx,
                ),
            iconColor: AppConstants.infoColor, // Blue
          ),
          const SettingsDivider(),
          SettingsItem(
            icon: Icons.filter_alt_outlined,
            title: l10n.translate('content_preferences'),
            subtitle: ContentPreferencesDialogs.getContentPreferencesText(
              SettingsManager().contentPreferences,
            ),
            onTap: () =>
                ContentPreferencesDialogs.showContentPreferencesDialog(ctx),
            iconColor: AppConstants.errorColor, // Red
          ),
          const SettingsDivider(),
          SettingsSwitchItem(
            icon: Icons.visibility_off_outlined,
            title: l10n.translate('hide_library'),
            subtitle: l10n.translate('hide_library_subtext'),
            value: SettingsManager().hideLibrarySeriesInBrowse,
            onChanged: (val) =>
                SettingsManager().setHideLibrarySeriesInBrowse(val),
            isLast: true,
            iconColor: const Color(0xFFAC4BFF), // Purple
          ),
        ],
      ),
    ],
  );
}

void _navigateToAccount(
  BuildContext context,
  LocalizationService l10n,
  ProfileAuthService auth,
) {
  _showOrNavigate(
    context,
    title: l10n.translate('account'),
    buildChildren: (ctx) => [
      SettingsGroup(
        children: [
          SettingsItem(
            icon: Icons.manage_accounts_outlined,
            title: l10n.translate('account_settings'),
            subtitle: l10n.translate('account_settings_subtext'),
            onTap: () => launchUrl(
              Uri.parse('https://mangabaka.org/my/settings/profile'),
              mode: LaunchMode.externalApplication,
            ),
            trailing: Icon(
              Icons.open_in_new,
              color: AppConstants.textMutedColor,
              size: 20,
            ),
            isFirst: true,
            iconColor: AppConstants.accentColor, // Green
          ),
          const SettingsDivider(),
          SettingsItem(
            icon: Icons.logout_outlined,
            title: l10n.translate('logout'),
            subtitle: l10n.translate('logout_subtext'),
            iconColor: AppConstants.errorColor, // Red
            onTap: () async {
              final shouldLogout =
                  await LogoutDialog.showLogoutConfirmationDialog(ctx);
              if (shouldLogout == true) {
                try {
                  await auth.logout();
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Logout failed: $e')),
                    );
                  }
                  return;
                }
                if (ctx.mounted) {
                  Navigator.pop(ctx); // Close account dialog/screen
                  Navigator.pop(ctx); // Close main settings dialog/screen
                }
              }
            },
            isLast: true,
          ),
        ],
      ),
    ],
  );
}

void _navigateToAdvanced(BuildContext context, LocalizationService l10n) {
  _showOrNavigate(
    context,
    title: l10n.translate('advanced_settings'),
    listenable: SettingsManager(),
    buildChildren: (ctx) => [
      SettingsGroup(
        children: [
          SettingsItem(
            icon: Icons.restart_alt,
            title: l10n.translate('redo_onboarding'),
            subtitle: l10n.translate('redo_onboarding_subtitle'),
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (context) => const OnboardingScreen(isRedoing: true),
              ),
            ),
            isFirst: true,
            iconColor: const Color(0xFFF98F3A), // Orange
          ),
          const SettingsDivider(),
          SettingsItem(
            icon: Icons.list_alt,
            title: l10n.translate('logs'),
            subtitle: l10n.translate('view_logs_subtitle'),
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (context) => const LogsScreen()),
            ),
            isLast: true,
            iconColor: AppConstants.errorColor, // Red
          ),
        ],
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Full-screen settings screen
// ---------------------------------------------------------------------------

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static void show(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    if (isLandscape) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => const _SettingsDialog(),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
                SettingsManager(),
        LocalizationService(),
        getIt<ProfileAuthService>(),
      ]),
      builder: (context, _) {
        final l10n = LocalizationService();
        final auth = getIt<ProfileAuthService>();

        return Scaffold(
          backgroundColor: AppConstants.primaryBackground,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              l10n.translate('settings').toUpperCase(),
              style: AppTypography.display(
            color: AppConstants.textColor,
            fontSize: 20,
          ),
            ),
            centerTitle: true,
          ),
          body: WidgetUtils.responsiveConstraint(
            ListView(
              padding: EdgeInsets.only(
                left: AppConstants.horizontalPadding,
                right: AppConstants.horizontalPadding,
                top: 8,
                bottom: 80,
              ),
              children: [
                // Brand block: a horizontal lockup rather than a centred
                // stack, so the eye starts at the same left edge as every
                // settings row beneath it.
                MbEntrance(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 28),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppConstants.accentColor
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              AppConstants.cardRadius,
                            ),
                          ),
                          child: Image.asset(
                            'assets/mangabaka512.png',
                            width: 44,
                            height: 44,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppConstants.appName.toUpperCase(),
                              style: AppTypography.display(
                                color: AppConstants.textColor,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'v${AppConstants.appVersion}',
                              style: AppTypography.sans(
                                color: AppConstants.textMutedColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                ..._staggered(_buildSettingsGroups(context, l10n, auth)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Landscape dialog
// ---------------------------------------------------------------------------

class _SettingsDialogPage {
  final String title;
  final Widget content;
  _SettingsDialogPage({required this.title, required this.content});
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog();

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  final List<_SettingsDialogPage> _stack = [];
  bool _isPushing = true;

  void pushCategory(String title, Widget content) {
    setState(() {
      _isPushing = true;
      _stack.add(_SettingsDialogPage(title: title, content: content));
    });
  }

  void popCategory() {
    if (_stack.isNotEmpty) {
      setState(() {
        _isPushing = false;
        _stack.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
                SettingsManager(),
        LocalizationService(),
        getIt<ProfileAuthService>(),
      ]),
      builder: (context, _) {
        final l10n = LocalizationService();
        final auth = getIt<ProfileAuthService>();
        final maxHeight = MediaQuery.of(context).size.height - 64;

        final currentKey = _stack.isEmpty
            ? const ValueKey('main_settings')
            : ValueKey(_stack.last.title);

        return PopScope(
          canPop: _stack.isEmpty,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            popCategory();
          },
          child: Dialog(
            backgroundColor: AppConstants.primaryBackground,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.largeRadius),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 480, maxHeight: maxHeight),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeInOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final isEntering = child.key == currentKey;
                  Offset beginOffset;
                  if (_isPushing) {
                    beginOffset = isEntering
                        ? const Offset(0.0, 1.0)
                        : const Offset(0.0, -1.0);
                  } else {
                    beginOffset = isEntering
                        ? const Offset(0.0, -1.0)
                        : const Offset(0.0, 1.0);
                  }

                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: beginOffset,
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: currentKey,
                  child: _stack.isEmpty
                      ? _buildMainSettings(context, l10n, auth)
                      : _buildCategorySettings(context, l10n, _stack.last),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainSettings(
    BuildContext context,
    LocalizationService l10n,
    ProfileAuthService auth,
  ) {
    return Column(
      key: const ValueKey('main_settings_column'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Text(
                l10n.translate('settings').toUpperCase(),
                style: AppTypography.display(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                color: AppConstants.textMutedColor,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        Divider(height: 1, color: AppConstants.borderColor),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: AppConstants.horizontalPadding,
              right: AppConstants.horizontalPadding,
              top: 16,
              bottom: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildSettingsGroups(context, l10n, auth),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySettings(
    BuildContext context,
    LocalizationService l10n,
    _SettingsDialogPage page,
  ) {
    return Column(
      key: ValueKey('category_column_${page.title}'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: popCategory,
                color: AppConstants.textMutedColor,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  page.title.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(
                    color: AppConstants.textColor,
                    fontSize: 19,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                color: AppConstants.textMutedColor,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        Divider(height: 1, color: AppConstants.borderColor),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: AppConstants.horizontalPadding,
              right: AppConstants.horizontalPadding,
              top: 16,
              bottom: 24,
            ),
            child: page.content,
          ),
        ),
      ],
    );
  }
}
