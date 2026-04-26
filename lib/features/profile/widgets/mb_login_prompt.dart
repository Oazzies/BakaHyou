import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';

class MBLoginPrompt extends StatelessWidget {
  final VoidCallback onLogin;
  final String message;

  const MBLoginPrompt({
    super.key,
    required this.onLogin,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: AppConstants.textColor),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: Text(
              l10n.translate('login_with'),
              style: TextStyle(fontSize: 16, color: AppConstants.textColor),
            ),
          ),
        ],
      ),
    );
  }
}
