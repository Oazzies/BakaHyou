import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/profile/widgets/mb_login_button.dart';

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
          MBLoginButton(onPressed: onLogin),
        ],
      ),
    );
  }
}
