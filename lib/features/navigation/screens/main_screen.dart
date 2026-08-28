import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/home/screens/home_screen.dart';
import 'package:mangabaka_app/features/browse/screens/browse_screen.dart';
import 'package:mangabaka_app/features/library/screens/library_screen.dart';
import 'package:mangabaka_app/features/news/screens/news_screen.dart';
import 'package:mangabaka_app/features/profile/screens/profile_screen.dart';
import 'package:mangabaka_app/features/library/widgets/sync_progress_overlay.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/profile/screens/settings_screen.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/features/library/widgets/library_search_bar.dart';
import 'package:mangabaka_app/features/browse/widgets/search/mb_search_bar.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/widgets/design/mb_nav.dart';
import 'package:mangabaka_app/core/widgets/design/mb_icons.dart';

// ---------------------------------------------------------------------------
// Nav destination data
// ---------------------------------------------------------------------------

@immutable
class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String labelKey;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.labelKey,
  });
}

// Phosphor rather than Material: the reference's nav is a thin, rounded,
// geometric family with a matched solid weight for the active state, which
// Material's icons do not provide. Compass and user match the reference
// directly; the bookmark stands in for the library. See [MbIcons].
const _navItems = [
  _NavItem(
    icon: MbIcons.house,
    selectedIcon: MbIcons.houseFill,
    labelKey: 'home',
  ),
  _NavItem(
    icon: MbIcons.bookmark,
    selectedIcon: MbIcons.bookmarkFill,
    labelKey: 'library',
  ),
  _NavItem(
    icon: MbIcons.compass,
    selectedIcon: MbIcons.compassFill,
    labelKey: 'browse',
  ),
  _NavItem(
    icon: MbIcons.newspaper,
    selectedIcon: MbIcons.newspaperFill,
    labelKey: 'news',
  ),
  _NavItem(
    icon: MbIcons.user,
    selectedIcon: MbIcons.userFill,
    labelKey: 'profile',
  ),
];

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class MainScreen extends StatefulWidget {
  static final GlobalKey<MainScreenState> mainScreenKey =
      GlobalKey<MainScreenState>();

  MainScreen({Key? key}) : super(key: key ?? mainScreenKey);

  static void setTabIndex(int index) {
    mainScreenKey.currentState?._onItemTapped(index);
  }

  static bool showSearchBarInTopNavBar(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final position = SettingsManager().landscapeAppBarPosition;
    final isTopNavBar = isLandscape && position == LandscapeAppBarPosition.top;
    if (!isTopNavBar) return false;
    return MediaQuery.of(context).size.width >= 1050;
  }

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  static final _logger = LoggingService.logger;
  late int _selectedIndex;

  // Cached once so IndexedStack never recreates its children.
  late final List<Widget> _pages;

  // Nested navigator for non-bottom landscape layouts so the navbar stays
  // visible while series detail (or any pushed route) is open.
  final GlobalKey<NavigatorState> _contentNavigatorKey = GlobalKey<NavigatorState>();
  late final ValueNotifier<int> _selectedIndexNotifier;

  void updateTopNavBar() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _selectedIndexNotifier.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = SettingsManager().defaultStartPage.index;
    _selectedIndexNotifier = ValueNotifier<int>(_selectedIndex);
    // BrowseScreen needs ExcludeSemantics on Windows to suppress a platform
    // accessibility warning triggered by the web-view component.
    _pages = [
      const HomeScreen(),
      LibraryScreen(key: LibraryScreen.libraryScreenKey),
      Platform.isWindows
          ? ExcludeSemantics(
              child: BrowseScreen(key: BrowseScreen.browseScreenKey),
            )
          : BrowseScreen(key: BrowseScreen.browseScreenKey),
      const NewsScreen(),
      const ProfileScreen(),
    ];
    _logger.info('MainScreen initialized with tab index: $_selectedIndex');
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      _logger.info('Tab switched to: $index');
      setState(() => _selectedIndex = index);
      _selectedIndexNotifier.value = index;
      // Pop series-detail (or any nested route) so switching tabs always
      // returns to the tab root within the nested navigator.
      _contentNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), SettingsManager()]),
      builder: (context, _) {
        final isTablet = MediaQuery.of(context).size.width >= 600;
        final l10n = LocalizationService();
        final landscapePosition = SettingsManager().landscapeAppBarPosition;

        final content = Stack(
          children: [
            IndexedStack(index: _selectedIndex, children: _pages),
            const SyncProgressOverlay(),
          ],
        );

        if (isTablet) {
          return _buildTabletLayout(context, content, l10n, landscapePosition);
        }
        return _buildPhoneLayout(content, l10n);
      },
    );
  }

  // Wraps pages in a nested Navigator so routes pushed from within (e.g.
  // series detail) stay inside the content area and the navbar remains visible.
  List<MbNavDestination> _destinations(LocalizationService l10n) => [
        for (final item in _navItems)
          MbNavDestination(
            icon: item.icon,
            selectedIcon: item.selectedIcon,
            label: l10n.translate(item.labelKey),
          ),
      ];

  Widget _settingsRailButton(BuildContext context, LocalizationService l10n) {
    return WidgetUtils.tooltip(
      message: l10n.translate('settings'),
      child: IconButton(
        icon: const Icon(Icons.settings_outlined),
        onPressed: () => SettingsScreen.show(context),
        color: AppConstants.textMutedColor,
      ),
    );
  }

  Widget _railLogo() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppConstants.denseRadius),
          ),
          child: Image.asset('assets/mangabaka512.png', width: 36, height: 36),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildContentWithNestedNav() {
    return Stack(
      children: [
        Navigator(
          key: _contentNavigatorKey,
          onGenerateInitialRoutes: (_, __) => [
            PageRouteBuilder<void>(
              opaque: true,
              pageBuilder: (ctx, __, ___) => ValueListenableBuilder<int>(
                valueListenable: _selectedIndexNotifier,
                builder: (_, idx, __) => IndexedStack(
                  index: idx,
                  children: _pages,
                ),
              ),
              transitionsBuilder: (_, __, ___, child) => child,
            ),
          ],
        ),
        const SyncProgressOverlay(),
      ],
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    Widget content,
    LocalizationService l10n,
    LandscapeAppBarPosition position,
  ) {
    // Non-bottom positions: use nested navigator so the navbar stays visible
    // while series detail is open. Bottom uses full-screen push (content as-is).
    final nestedContent = _buildContentWithNestedNav();

    if (position == LandscapeAppBarPosition.top) {
      return Scaffold(
        backgroundColor: AppConstants.primaryBackground,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: _buildTopNavBar(context, l10n),
        ),
        body: nestedContent,
      );
    }

    if (position == LandscapeAppBarPosition.bottom) {
      return Scaffold(
        backgroundColor: AppConstants.primaryBackground,
        body: content,
        bottomNavigationBar: MbBottomNav(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          destinations: _destinations(l10n),
        ),
      );
    }

    if (position == LandscapeAppBarPosition.right) {
      return Scaffold(
        backgroundColor: AppConstants.primaryBackground,
        body: Row(
          children: [
            Expanded(child: nestedContent),
            Container(
              width: 1,
              color: AppConstants.borderColor,
            ),
            Container(
              width: 88,
              color: AppConstants.primaryBackground,
              child: SafeArea(
                left: false,
                child: MbNavRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  destinations: _destinations(l10n),
                  leading: _railLogo(),
                  trailing: _settingsRailButton(context, l10n),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Default: left rail
    return Scaffold(
      backgroundColor: AppConstants.primaryBackground,
      body: Row(
        children: [
          Container(
            width: 88,
            color: AppConstants.primaryBackground,
            child: SafeArea(
              right: false,
              child: MbNavRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onItemTapped,
                destinations: _destinations(l10n),
                leading: _railLogo(),
                trailing: _settingsRailButton(context, l10n),
              ),
            ),
          ),
          Container(
            width: 1,
            color: AppConstants.borderColor,
          ),
          Expanded(child: nestedContent),
        ],
      ),
    );
  }

  Widget _buildTopNavBar(BuildContext context, LocalizationService l10n) {
    Widget? searchBarWidget;
    if (MainScreen.showSearchBarInTopNavBar(context)) {
      if (_selectedIndex == 1) { // Library
        final libState = LibraryScreen.libraryScreenKey.currentState;
        if (libState != null) {
          searchBarWidget = LibrarySearchBar(
            focusNode: libState.searchFocusNode,
            entriesStream: libState.entriesStream,
            onResultSelected: libState.handleResultSelected,
            onChanged: libState.updateQuery,
            initialFilters: libState.filters,
            onFilterApplied: libState.updateFilters,
          );
        }
      } else if (_selectedIndex == 2) { // Browse
        final browseState = BrowseScreen.browseScreenKey.currentState;
        if (browseState != null) {
          searchBarWidget = MBSearchBar(
            focusNode: browseState.searchFocusNode,
            controller: browseState.controller.searchController,
            initialFilters: browseState.controller.currentFilters,
            onScanTap: browseState.handleBarcodeScan,
            onResultSelected: browseState.handleResultSelected,
            onChanged: browseState.controller.updateSearchQuery,
            onSubmitted: (_) => browseState.controller.searchSeries(),
            onFilterApplied: browseState.controller.updateFilters,
          );
        }
      }
    }

    return Container(
      height: 72,
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
              // Logo + app name
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
              const SizedBox(width: 32),
              // Nav items
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_navItems.length, (i) {
                  final item = _navItems[i];
                  final isSelected = _selectedIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 22),
                    child: InkWell(
                      onTap: () => _onItemTapped(i),
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
                              color: isSelected
                                  ? AppConstants.textColor
                                  : AppConstants.textMutedColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.translate(item.labelKey).toUpperCase(),
                              style: AppTypography.display(
                                fontSize: 13,
                                color: isSelected
                                    ? AppConstants.textColor
                                    : AppConstants.textMutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const Spacer(),
              if (searchBarWidget != null) ...[
                SizedBox(
                  width: 320,
                  child: searchBarWidget,
                ),
                const SizedBox(width: 24),
              ],
              // Settings button on the right
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

  Widget _buildPhoneLayout(Widget content, LocalizationService l10n) {
    return Scaffold(
      backgroundColor: AppConstants.primaryBackground,
      body: content,
      bottomNavigationBar: MbBottomNav(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: _destinations(l10n),
      ),
    );
  }
}
