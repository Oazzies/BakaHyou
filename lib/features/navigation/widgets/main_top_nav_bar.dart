import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/features/navigation/models/nav_destinations.dart';
import 'package:mangabaka_app/features/navigation/widgets/top_nav_search_field.dart';
import 'package:mangabaka_app/features/profile/screens/settings_screen.dart';

/// The horizontal navigation bar used on wide landscape windows: brand, tabs,
/// the current tab's search field, and settings.
///
/// A desktop-shaped chrome rather than a rail — at this width a row of labelled
/// tabs costs no content space and leaves room for a persistent search field,
/// which the rail layouts have nowhere to put.
class MainTopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final LocalizationService l10n;

  /// Whether this window is wide enough to host the current tab's search
  /// field. When false the slot is left out entirely and the screen draws its
  /// own field.
  final bool showSearchField;

  static const double _height = 72;

  /// Fixed width for the search slot: letting it flex would make the tabs
  /// shift sideways as the field appeared and disappeared between tabs.
  static const double _searchWidth = 320;

  const MainTopNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.l10n,
    required this.showSearchField,
  });

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final searchField =
        showSearchField ? TopNavSearchField.build(selectedIndex) : null;

    return Container(
      height: _height,
      decoration: BoxDecoration(
        color: AppConstants.primaryBackground,
        border: Border(
          bottom: BorderSide(color: AppConstants.borderColor, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const _Brand(),
              const SizedBox(width: 32),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < navItems.length; i++)
                    _NavTab(
                      item: navItems[i],
                      label: l10n.translate(navItems[i].labelKey),
                      isSelected: selectedIndex == i,
                      onTap: () => onDestinationSelected(i),
                    ),
                ],
              ),
              const Spacer(),
              if (searchField != null) ...[
                SizedBox(width: _searchWidth, child: searchField),
                const SizedBox(width: 24),
              ],
              WidgetUtils.tooltip(
                message: l10n.translate('settings'),
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  iconSize: 20,
                  onPressed: () => SettingsScreen.show(context),
                  color: AppConstants.textMutedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppConstants.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.denseRadius),
          ),
          child: Image.asset(
            'assets/mangabaka512.png',
            width: 28,
            height: 28,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'MANGABAKA',
          style: AppTypography.display(
            color: AppConstants.textColor,
            fontSize: 17,
          ),
        ),
      ],
    );
  }
}

/// One tab: icon, label, and an underline that animates in when selected.
class _NavTab extends StatelessWidget {
  final NavItem item;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTab({
    required this.item,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isSelected ? AppConstants.textColor : AppConstants.textMutedColor;

    return Padding(
      padding: const EdgeInsets.only(right: 22),
      child: InkWell(
        onTap: onTap,
        // Square: the underline is the selection cue, and a rounded hover
        // shape would fight it.
        borderRadius: BorderRadius.zero,
        child: AnimatedContainer(
          duration: AppConstants.shortAnimationDuration,
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? AppConstants.accentColor
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? item.selectedIcon : item.icon,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: AppTypography.display(fontSize: 13, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
