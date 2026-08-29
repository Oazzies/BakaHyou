import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/browse/screens/barcode_scanner_screen.dart';
import 'package:permission_handler/permission_handler.dart';

/// Opens the barcode scanner, dealing with the camera permission first.
///
/// Separate from the Browse screen because it is all platform plumbing —
/// permission states, the settings deep link, and the scanner route — and none
/// of it touches browse state.
class CameraScanLauncher {
  CameraScanLauncher._();

  static final _logger = LoggingService.logger;

  /// Scans a barcode, returning the code or null if it did not happen.
  ///
  /// Null covers every non-result: permission refused, the scanner cancelled,
  /// or nothing recognised. The caller has already been told why through a
  /// snack bar where there was something to say.
  static Future<String?> scan(BuildContext context) async {
    _logger.info('Requested barcode scan');

    if (!await _ensurePermission(context)) return null;

    _logger.fine('Camera permission granted, opening scanner');
    if (!context.mounted) return null;

    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (code == null || code.isEmpty) {
      _logger.fine('Barcode scan cancelled or empty');
      return null;
    }
    _logger.info('Scanned ISBN: $code');
    return code;
  }

  /// Requests the camera permission, explaining a refusal in a snack bar.
  ///
  /// permission_handler is not supported on macOS, and desktop platforms show
  /// their own system dialog on first camera access — so only mobile asks
  /// here.
  static Future<bool> _ensurePermission(BuildContext context) async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    final status = await Permission.camera.request();
    if (status.isGranted) return true;
    if (!context.mounted) return false;

    // Permanently denied can only be undone in system settings, so that case
    // gets a way to get there; an ordinary denial can just be retried.
    final permanent = status.isPermanentlyDenied;
    _logger.warning(
      permanent
          ? 'Camera permission permanently denied'
          : 'Camera permission denied (status: $status)',
    );
    _showDeniedSnackBar(context, offerSettings: permanent);
    return false;
  }

  static void _showDeniedSnackBar(
    BuildContext context, {
    required bool offerSettings,
  }) {
    final l10n = LocalizationService();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.translate('camera_permission_denied')),
        action: offerSettings
            ? SnackBarAction(
                label: l10n.translate('settings'),
                onPressed: openAppSettings,
              )
            : null,
      ),
    );
  }
}
