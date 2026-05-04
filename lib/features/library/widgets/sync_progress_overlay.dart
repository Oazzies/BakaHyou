import 'package:flutter/material.dart';
import 'package:bakahyou/features/library/models/library_sync_status.dart';
import 'package:bakahyou/features/library/services/library_service.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _buildCard(context, status),
          ),
        )
            .animate(target: status.isSyncing ? 1 : 0)
            .slideY(begin: 1, end: 0, curve: Curves.easeOutBack, duration: 400.ms)
            .fadeIn(duration: 400.ms);
      },
    );
  }

  Widget _buildCard(BuildContext context, LibrarySyncStatus status) {
    final hasError = status.error != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppConstants.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.borderColor),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryBackground.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon / spinner
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppConstants.tertiaryBackground,
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 20,
              height: 20,
              child: hasError
                  ? Icon(Icons.warning_amber_rounded,
                      color: AppConstants.errorColor, size: 20)
                  : CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppConstants.accentColor),
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Text
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasError ? 'Sync Interrupted' : 'Syncing Library',
                  style: TextStyle(
                    color: hasError
                        ? AppConstants.errorColor
                        : AppConstants.textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasError
                      ? (status.error ?? 'An error occurred.')
                      : '${status.currentEntries} entries synced',
                  style: TextStyle(
                    color: hasError
                        ? AppConstants.errorColor.withOpacity(0.85)
                        : AppConstants.textMutedColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
