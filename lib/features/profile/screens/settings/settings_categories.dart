import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/navigation/screens/onboarding_screen.dart';
import 'package:mangabaka_app/features/profile/screens/logs_screen.dart';
import 'package:mangabaka_app/features/profile/screens/settings/settings_navigation.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/content_preferences_dialog.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/general_settings_dialogs.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/logout_dialog.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/list_customization_settings.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_components.dart';
import 'package:url_launcher/url_launcher.dart';

/// The contents of each settings category.
///
/// Every entry point here hands its rows to [showOrNavigate], which decides
/// between pushing a screen and pushing a page onto the landscape dialog. The
/// categories are grouped in this one file because they are all the same kind
/// of thing — a list of [SettingsItem]s — and splitting them further would
/// leave five files of a dozen lines each.
class SettingsCategories {
  SettingsCategories._();

  /// Below this width the general category hides the tooltip toggle: tooltips
  /// are a pointer affordance and there is no hover on a phone.
  static const double _smallDeviceWidth = 600;

  static void general(BuildContext context, LocalizationService l10n) {
    showOrNavigate(
      context,
      title: l10n.translate('general'),
      listenable: Listenable.merge([LocalizationService(), SettingsManager()]),
      buildChildren: (ctx) {
        final l10n = LocalizationService();
        final settings = SettingsManager();
        final isSmallDevice =
            MediaQuery.sizeOf(ctx).width < _smallDeviceWidth;

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
                iconColor: AppConstants.infoColor,
              ),
              const SettingsDivider(),
              SettingsItem(
                icon: Icons.start,
                title: l10n.translate('start_page'),
                subtitle: GeneralSettingsDialogs.getAppStartPageName(
                  settings.defaultStartPage,
                ),
                onTap: () =>
                    GeneralSettingsDialogs.showAppStartPageSelectionDialog(ctx),
                iconColor: AppConstants.accentColor,
              ),
              const SettingsDivider(),
              SettingsItem(
                icon: Icons.stay_primary_landscape_outlined,
                title: l10n.translate('landscape_appbar_position'),
                subtitle: GeneralSettingsDialogs.getLandscapeAppBarPositionName(
                  settings.landscapeAppBarPosition,
                ),
                onTap: () => GeneralSettingsDialogs
                    .showLandscapeAppBarPositionDialog(ctx),
                iconColor: const Color(0xFFAC4BFF),
              ),
              const SettingsDivider(),
              SettingsItem(
                icon: Icons.translate,
                title: l10n.translate('title_language'),
                subtitle: GeneralSettingsDialogs.getTitleLanguageName(
                  settings.defaultTitleLanguage,
                ),
                onTap: () => GeneralSettingsDialogs
                    .showTitleLanguageSelectionDialog(ctx),
                iconColor: const Color(0xFFD71F75),
              ),
              if (!isSmallDevice) ...[
                const SettingsDivider(),
                SettingsSwitchItem(
                  icon: Icons.help_outline,
                  title: l10n.translate('show_tooltips'),
                  subtitle: l10n.translate('show_tooltips_subtext'),
                  value: settings.showTooltips,
                  onChanged: settings.setShowTooltips,
                  iconColor: AppConstants.starColor,
                ),
              ],
              const SettingsDivider(),
              SettingsSwitchItem(
                icon: Icons.search,
                title: l10n.translate('auto_suggest_browse'),
                subtitle: l10n.translate('auto_suggest_browse_subtitle'),
                value: settings.autoSuggestBrowse,
                onChanged: settings.setAutoSuggestBrowse,
                isLast: true,
                iconColor: const Color(0xFF4FBEC4),
              ),
            ],
          ),
        ];
      },
    );
  }

  static void listCustomization(
    BuildContext context,
    LocalizationService l10n,
  ) {
    showOrNavigate(
      context,
      title: l10n.translate('list_customization'),
      listenable: SettingsManager(),
      buildChildren: (_) => [ListCustomizationSettings(l10n: l10n)],
    );
  }

  static void content(BuildContext context, LocalizationService l10n) {
    showOrNavigate(
      context,
      title: l10n.translate('content'),
      listenable: SettingsManager(),
      buildChildren: (ctx) {
        final settings = SettingsManager();
        return [
          SettingsGroup(
            children: [
              SettingsItem(
                icon: Icons.star_outline,
                title: l10n.translate('rating_step'),
                subtitle: GeneralSettingsDialogs.getRatingSliderStepName(
                  settings.ratingSliderStep,
                ),
                onTap: () => GeneralSettingsDialogs
                    .showRatingSliderStepSelectionDialog(ctx),
                isFirst: true,
                iconColor: AppConstants.starColor,
              ),
              const SettingsDivider(),
              SettingsItem(
                icon: Icons.tab,
                title: l10n.translate('library_default'),
                subtitle: GeneralSettingsDialogs.getLibraryTabName(
                  settings.addLibraryDefaultTab,
                ),
                onTap: () => GeneralSettingsDialogs
                    .showAddLibraryDefaultTabSelectionDialog(ctx),
                iconColor: AppConstants.infoColor,
              ),
              const SettingsDivider(),
              SettingsItem(
                icon: Icons.filter_alt_outlined,
                title: l10n.translate('content_preferences'),
                subtitle: ContentPreferencesDialogs.getContentPreferencesText(
                  settings.contentPreferences,
                ),
                onTap: () =>
                    ContentPreferencesDialogs.showContentPreferencesDialog(ctx),
                iconColor: AppConstants.errorColor,
              ),
              const SettingsDivider(),
              SettingsSwitchItem(
                icon: Icons.visibility_off_outlined,
                title: l10n.translate('hide_library'),
                subtitle: l10n.translate('hide_library_subtext'),
                value: settings.hideLibrarySeriesInBrowse,
                onChanged: settings.setHideLibrarySeriesInBrowse,
                isLast: true,
                iconColor: const Color(0xFFAC4BFF),
              ),
            ],
          ),
        ];
      },
    );
  }

  static void account(
    BuildContext context,
    LocalizationService l10n,
    ProfileAuthService auth,
  ) {
    showOrNavigate(
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
              iconColor: AppConstants.accentColor,
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.logout_outlined,
              title: l10n.translate('logout'),
              subtitle: l10n.translate('logout_subtext'),
              iconColor: AppConstants.errorColor,
              onTap: () => _confirmAndLogout(ctx, auth),
              isLast: true,
            ),
          ],
        ),
      ],
    );
  }

  /// Logs out after confirmation, then unwinds both the account category and
  /// the settings root — staying on an account screen that no longer has an
  /// account behind it would show stale rows.
  ///
  /// A failed logout keeps the user where they are and reports why: the
  /// session is still valid, so silently returning them to the app would
  /// suggest it had worked.
  static Future<void> _confirmAndLogout(
    BuildContext context,
    ProfileAuthService auth,
  ) async {
    final confirmed = await LogoutDialog.showLogoutConfirmationDialog(context);
    if (confirmed != true) return;

    try {
      await auth.logout();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    Navigator.pop(context); // Close the account category.
    Navigator.pop(context); // Close the settings root.
  }

  static void advanced(BuildContext context, LocalizationService l10n) {
    showOrNavigate(
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
                  builder: (_) => const OnboardingScreen(isRedoing: true),
                ),
              ),
              isFirst: true,
              iconColor: const Color(0xFFF98F3A),
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.list_alt,
              title: l10n.translate('logs'),
              subtitle: l10n.translate('view_logs_subtitle'),
              onTap: () => Navigator.push(
                ctx,
                MaterialPageRoute(builder: (_) => const LogsScreen()),
              ),
              isLast: true,
              iconColor: AppConstants.errorColor,
            ),
          ],
        ),
      ],
    );
  }
}
