import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';

/// Which list the customization panel is currently editing.
enum ListScopeTab {
  library,
  browse;

  bool get isLibrary => this == ListScopeTab.library;
}

/// Resolves "what does the active tab actually read and write?".
///
/// Library and Browse can each keep their own list style and grid column
/// count, or share one of each — and the two are separate switches, so a user
/// can have separate styles but a shared column count. That produced the same
/// nested ternary in half a dozen places (once per read, once per write, once
/// per label), and a missed branch showed up as a control that edited the
/// wrong list.
///
/// This resolves it once. It holds no state: build one per frame from the
/// current [SettingsManager] and tab.
class ListCustomizationScope {
  final SettingsManager settings;
  final ListScopeTab tab;

  const ListCustomizationScope({required this.settings, required this.tab});

  /// True when either switch is on, which is the only time the tab selector
  /// and the copy-across button mean anything.
  bool get hasAnySeparation =>
      settings.separateListStyles || settings.separateGridColumnCounts;

  // ─── List style ──────────────────────────────────────────────────────────

  AppListStyle get style {
    if (!settings.separateListStyles) return settings.currentListStyle;
    return tab.isLibrary ? settings.libraryListStyle : settings.browseListStyle;
  }

  void setStyle(AppListStyle style) {
    if (!settings.separateListStyles) {
      settings.setListStyle(style);
    } else if (tab.isLibrary) {
      settings.setLibraryListStyle(style);
    } else {
      settings.setBrowseListStyle(style);
    }
  }

  String styleLabel(LocalizationService l10n) {
    if (!settings.separateListStyles) return l10n.translate('list_style');
    return l10n.translate(
      tab.isLibrary ? 'library_list_style' : 'browse_list_style',
    );
  }

  // ─── Grid columns ────────────────────────────────────────────────────────

  /// The column count, where 0 means "auto — fit as many as the width allows".
  int get gridColumns {
    if (!settings.separateGridColumnCounts) return settings.gridColumnCount;
    return tab.isLibrary
        ? settings.libraryGridColumnCount
        : settings.browseGridColumnCount;
  }

  void setGridColumns(int count) {
    if (!settings.separateGridColumnCounts) {
      settings.setGridColumnCount(count);
    } else if (tab.isLibrary) {
      settings.setLibraryGridColumnCount(count);
    } else {
      settings.setBrowseGridColumnCount(count);
    }
  }

  String gridColumnsLabel(LocalizationService l10n) {
    if (!settings.separateGridColumnCounts) {
      return l10n.translate('grid_columns');
    }
    return l10n.translate(
      tab.isLibrary ? 'library_grid_columns' : 'browse_grid_columns',
    );
  }

  /// Only the grid styles have a column count to configure.
  bool get showsGridColumns =>
      style == AppListStyle.coverOnlyGrid || style == AppListStyle.compactGrid;

  // ─── Switching the separation on and off ─────────────────────────────────

  /// Turning separation on seeds both lists with the style already in use, and
  /// turning it off adopts the active tab's — so the toggle itself never
  /// changes how anything looks.
  void setSeparateStyles(bool separate) {
    if (separate) {
      final shared = settings.currentListStyle;
      settings.setLibraryListStyle(shared);
      settings.setBrowseListStyle(shared);
    } else {
      settings.setListStyle(
        tab.isLibrary ? settings.libraryListStyle : settings.browseListStyle,
      );
    }
    settings.setSeparateListStyles(separate);
  }

  /// The column-count counterpart of [setSeparateStyles], with the same
  /// carry-the-current-value-across behaviour.
  void setSeparateGridColumns(bool separate) {
    if (separate) {
      final shared = settings.gridColumnCount;
      settings.setLibraryGridColumnCount(shared);
      settings.setBrowseGridColumnCount(shared);
    } else {
      settings.setGridColumnCount(
        tab.isLibrary
            ? settings.libraryGridColumnCount
            : settings.browseGridColumnCount,
      );
    }
    settings.setSeparateGridColumnCounts(separate);
  }

  /// Copies whatever is configured independently from the active tab's list to
  /// the other one. Shared settings are left alone — there is nothing to copy.
  void copyToOtherTab() {
    final toBrowse = tab.isLibrary;
    if (settings.separateListStyles) {
      if (toBrowse) {
        settings.setBrowseListStyle(settings.libraryListStyle);
      } else {
        settings.setLibraryListStyle(settings.browseListStyle);
      }
    }
    if (settings.separateGridColumnCounts) {
      if (toBrowse) {
        settings.setBrowseGridColumnCount(settings.libraryGridColumnCount);
      } else {
        settings.setLibraryGridColumnCount(settings.browseGridColumnCount);
      }
    }
  }
}
