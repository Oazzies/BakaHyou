import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';

class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.palette_outlined,
            size: 80,
            color: AppConstants.accentColor,
          ),
          const SizedBox(height: 32),
          Text(
            'Choose Your Theme',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Pick the look that suits you best.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppConstants.textMutedColor,
            ),
          ),
          const SizedBox(height: 32),
          ListenableBuilder(
            listenable: ThemeManager(),
            builder: (context, _) {
              final currentTheme = ThemeManager().currentTheme;
              return Column(
                children: AppTheme.values.map((theme) {
                  return RadioListTile<AppTheme>(
                    title: Text(
                      _getThemeName(theme),
                      style: TextStyle(color: AppConstants.textColor),
                    ),
                    value: theme,
                    groupValue: currentTheme,
                    activeColor: AppConstants.accentColor,
                    onChanged: (AppTheme? value) {
                      if (value != null) {
                        ThemeManager().setTheme(value);
                      }
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
