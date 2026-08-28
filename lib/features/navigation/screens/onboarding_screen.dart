import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';

import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/navigation/widgets/onboarding/welcome_page.dart';
import 'package:mangabaka_app/features/navigation/widgets/onboarding/language_page.dart';
import 'package:mangabaka_app/features/navigation/widgets/onboarding/camera_permission_page.dart';
import 'package:mangabaka_app/features/navigation/widgets/onboarding/content_preferences_page.dart';
import 'package:mangabaka_app/features/navigation/widgets/onboarding/login_page.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isRedoing;

  const OnboardingScreen({super.key, this.isRedoing = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static final _logger = LoggingService.logger;
  final PageController _pageController = PageController();
  late final ProfileAuthService _authService;
  int _currentPage = 0;
  bool _isLoggingIn = false;
  bool _isLoggedIn = false;

  static const int _totalPages = 5;

  @override
  void initState() {
    super.initState();
    _logger.info('Onboarding started (isRedoing: ${widget.isRedoing})');
    _authService = getIt<ProfileAuthService>();
    _isLoggedIn = _authService.isLoggedIn;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _logger.fine('Moving to onboarding page ${_currentPage + 2}');
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _logger.fine('Moving back to onboarding page $_currentPage');
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _finishOnboarding() async {
    _logger.info('Finishing onboarding');
    await SettingsManager().setHasCompletedOnboarding(true);
    if (!mounted) return;

    if (widget.isRedoing) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _requestCameraPermission() async {
    _logger.info('Requesting camera permission during onboarding');
    // permission_handler does not support macOS — camera access is controlled
    // via the entitlements file and system dialog on first use.
    if (!Platform.isAndroid && !Platform.isIOS) {
      _logger.info('Platform does not use permission_handler; skipping request');
      _nextPage();
      return;
    }
    final status = await Permission.camera.request();
    _logger.info('Camera permission status: $status');
    if (!mounted) return;
    _nextPage();
  }

  Future<void> _login() async {
    _logger.info('Starting login attempt during onboarding');
    setState(() => _isLoggingIn = true);
    try {
      await _authService.login();
      if (!mounted) return;
      _logger.info('Login successful during onboarding');
      setState(() => _isLoggedIn = true);
      _nextPage();
    } catch (e) {
      if (e is AuthCancelledException) {
        _logger.info('Login cancelled by user');
        return;
      }
      _logger.severe('Login failed during onboarding: $e');
      if (mounted) {
        final localization = LocalizationService();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localization.translate('onboarding_login_failed'), style: AppTypography.sans(color: AppConstants.errorColor)),
            backgroundColor: AppConstants.secondaryBackground,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppConstants.primaryBackground,
          body: WidgetUtils.responsiveConstraint(
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: [
                        const WelcomePage(),
                        const LanguagePage(),
                        const ContentPreferencesPage(),
                        CameraPermissionPage(
                          onRequestPermission: _requestCameraPermission,
                        ),
                        LoginPage(
                          isLoggingIn: _isLoggingIn,
                          isLoggedIn: _isLoggedIn,
                          onLogin: _login,
                        ),
                      ],
                    ),
                  ),
                  _buildBottomControls(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomControls() {
    final isLastPage = _currentPage == _totalPages - 1;
    final localization = LocalizationService();
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Scale down spacing if height is small
    final isShort = screenHeight < 600;
    final bottomPadding = isShort ? 16.0 : 32.0;
    final spacingHeight = isShort ? 16.0 : 32.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _totalPages,
              (index) {
                final isSelected = _currentPage == index;
                return AnimatedContainer(
                  duration: AppMotion.base,
                  curve: AppMotion.emphasized,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isSelected
                        ? AppConstants.accentColor
                        : AppConstants.tertiaryBackground,
                  ),
                );
              },
            ),
          ),
          SizedBox(height: spacingHeight),
          Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: TextButton(
                    onPressed: _previousPage,
                    style: TextButton.styleFrom(
                      foregroundColor: AppConstants.textMutedColor,
                      padding: EdgeInsets.symmetric(vertical: isShort ? 12 : 16),
                    ),
                    child: Text(localization.translate('onboarding_back')),
                  ),
                )
              else
                Expanded(
                  child: TextButton(
                    onPressed: _finishOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: AppConstants.textMutedColor,
                      padding: EdgeInsets.symmetric(vertical: isShort ? 12 : 16),
                    ),
                    child: Text(localization.translate('onboarding_skip')),
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: MbPrimaryButton(
                  label: isLastPage
                      ? localization.translate('onboarding_finish')
                      : localization.translate('onboarding_next'),
                  onPressed: _nextPage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
