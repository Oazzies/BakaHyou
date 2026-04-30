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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppConstants.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.tertiaryBackground,
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 20,
              height: 20,
              child: status.error != null
                  ? Icon(Icons.warning_amber_rounded, color: AppConstants.errorColor, size: 20)
                  : CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppConstants.accentColor),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.error != null ? 'Sync Interrupted' : 'Syncing Library',
                  style: TextStyle(
                    color: status.error != null ? AppConstants.errorColor : AppConstants.textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${status.currentEntries} series processed',
                  style: TextStyle(
                    color: AppConstants.textMutedColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (status.infoMessage != null && status.error == null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: AppConstants.accentColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          status.infoMessage!,
                          style: TextStyle(
                            color: AppConstants.accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (status.error != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    status.error!,
                    style: TextStyle(
                      color: AppConstants.errorColor.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
