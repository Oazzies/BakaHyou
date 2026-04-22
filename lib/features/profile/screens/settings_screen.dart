import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryBackground,
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: AppConstants.primaryBackground,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([ThemeManager(), SettingsManager()]),
        builder: (context, _) {
          return ListView(
            padding: EdgeInsets.all(AppConstants.horizontalPadding),
            children: [
              _buildSectionHeader('Appearance'),
              _buildSettingItem(
                icon: Icons.palette_outlined,
                title: 'App Theme',
                subtitle: _getThemeName(ThemeManager().currentTheme),
                onTap: () => _showThemeSelectionDialog(context),
              ),
              _buildSettingItem(
                icon: Icons.view_list_outlined,
                title: 'List Style',
                subtitle: _getListStyleName(SettingsManager().currentListStyle),
                onTap: () => _showListStyleSelectionDialog(context),
              ),
              _buildSectionHeader('General'),
              _buildSettingItem(
                icon: Icons.info_outline,
                title: 'About',
                onTap: () {
                  // TODO: Implement About dialog
                },
              ),
              // Add more settings here in the future
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppConstants.accentColor,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppConstants.textMutedColor),
      title: Text(
        title,
        style: TextStyle(color: AppConstants.textColor),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: AppConstants.textMutedColor),
            )
          : null,
      trailing: Icon(Icons.chevron_right, color: AppConstants.textMutedColor),
      onTap: onTap,
    );
  }

  String _getThemeName(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return 'Light Mode';
      case AppTheme.monochrome:
        return 'Monochrome';
      case AppTheme.dark:
        return 'Dark Mode';
      case AppTheme.system:
        return 'System Default';
    }
  }

  void _showThemeSelectionDialog(BuildContext context) {
    final currentTheme = ThemeManager().currentTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.tertiaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.cardRadius),
        ),
      ),
      builder: (BuildContext dialogContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Theme',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...AppTheme.values.map((theme) {
                return ListTile(
                  title: Text(
                    _getThemeName(theme),
                    style: TextStyle(color: AppConstants.textColor),
                  ),
                  trailing: theme == currentTheme
                      ? Icon(Icons.check, color: AppConstants.accentColor)
                      : null,
                  onTap: () {
                    ThemeManager().setTheme(theme);
                    Navigator.pop(dialogContext);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _getListStyleName(AppListStyle style) {
    switch (style) {
      case AppListStyle.comfortable:
        return 'Comfortable';
      case AppListStyle.compact:
        return 'Compact';
      case AppListStyle.minimalList:
        return 'Minimal List';
      case AppListStyle.grid:
        return 'Grid';
    }
  }

  void _showListStyleSelectionDialog(BuildContext context) {
    final currentStyle = SettingsManager().currentListStyle;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.tertiaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.cardRadius),
        ),
      ),
      builder: (BuildContext dialogContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select List Style',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...AppListStyle.values.map((style) {
                return ListTile(
                  title: Text(
                    _getListStyleName(style),
                    style: TextStyle(color: AppConstants.textColor),
                  ),
                  trailing: style == currentStyle
                      ? Icon(Icons.check, color: AppConstants.accentColor)
                      : null,
                  onTap: () {
                    SettingsManager().setListStyle(style);
                    Navigator.pop(dialogContext);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
