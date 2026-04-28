import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:bakahyou/features/library/models/library_sync_status.dart';
import 'package:bakahyou/features/library/services/library_service.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class SyncProgressOverlay extends StatelessWidget {
  const SyncProgressOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryService = getIt<LibraryService>();

    return ValueListenableBuilder<LibrarySyncStatus>(
      valueListenable: libraryService.syncStatus,
      builder: (context, status, child) {
        if (!status.isSyncing && status.currentEntries == 0) {
          return const SizedBox.shrink();
        }

        return AnimatedSlide(
          duration: AppConstants.shortAnimationDuration,
          offset: status.isSyncing ? Offset.zero : const Offset(0, 1),
          child: AnimatedOpacity(
            duration: AppConstants.shortAnimationDuration,
            opacity: status.isSyncing ? 1.0 : 0.0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _buildProgressBar(context, status),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(BuildContext context, LibrarySyncStatus status) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppConstants.borderColor.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppConstants.accentColor),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Importing Library...',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${status.currentEntries} series imported',
                    style: TextStyle(
                      color: AppConstants.textMutedColor,
                      fontSize: 12,
                    ),
                  ),
                  if (status.error != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      status.error!,
                      style: TextStyle(
                        color: AppConstants.errorColor.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              if (status.error != null) ...[
                const SizedBox(width: 16),
                Icon(Icons.wifi_off_outlined, color: AppConstants.errorColor, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
