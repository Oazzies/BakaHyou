import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class IdChip extends StatelessWidget {
  final String id;
  const IdChip({required this.id, super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Click to copy ID',
      child: GestureDetector(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: id));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ID copied to clipboard: $id'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                width: 250,
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppConstants.secondaryBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppConstants.borderColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            'ID: $id',
            style: TextStyle(
              fontSize: 11,
              color: AppConstants.textMutedColor,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
}
