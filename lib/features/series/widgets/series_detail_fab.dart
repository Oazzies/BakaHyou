import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_starburst_button.dart';

class SeriesDetailFAB extends StatelessWidget {
  final Stream<LibraryEntry?>? entryStream;
  final bool isAdding;
  final VoidCallback onAdd;

  const SeriesDetailFAB({
    super.key,
    required this.entryStream,
    required this.isAdding,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = getIt<ProfileAuthService>().isLoggedIn;
    if (!isLoggedIn) return const SizedBox.shrink();
    
    return StreamBuilder<LibraryEntry?>(
      stream: entryStream,
      builder: (context, snapshot) {
        if (snapshot.data == null) {
          return WidgetUtils.tooltip(
            message: LocalizationService().translate('add_to_library'),
            child: MbStarburstButton(
              key: const Key('add_to_library_fab'),
              label: LocalizationService().translate('add_to_library'),
              onPressed: isAdding ? null : onAdd,
              trailingIcon: isAdding ? null : Icons.add_rounded,
              padding: const EdgeInsets.symmetric(
                horizontal: 34,
                vertical: 24,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
