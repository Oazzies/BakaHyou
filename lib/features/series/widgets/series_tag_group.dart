import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/features/series/models/tag_chip_data.dart';
import 'package:mangabaka_app/features/series/widgets/chip.dart';

class SeriesTagGroup extends StatefulWidget {
  final String header;
  final Map<String, List<TagChipData>> subGroups;
  final Set<String> selectedTagIds;
  final ValueChanged<String> onTagTap;
  final ValueChanged<String> onTagLongPress;
  final VoidCallback? onToggle;

  const SeriesTagGroup({
    super.key,
    required this.header,
    required this.subGroups,
    required this.selectedTagIds,
    required this.onTagTap,
    required this.onTagLongPress,
    this.onToggle,
  });

  @override
  State<SeriesTagGroup> createState() => _SeriesTagGroupState();
}

class _SeriesTagGroupState extends State<SeriesTagGroup> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _isCollapsed = !_isCollapsed;
        });
        widget.onToggle?.call();
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: AppConstants.accentColor.withValues(alpha: 0.5),
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.header.toUpperCase(),
                      style: AppTypography.sans(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppConstants.textMutedColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Icon(
                    _isCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                    size: 16,
                    color: AppConstants.textMutedColor.withValues(alpha: 0.7),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _isCollapsed
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            ...widget.subGroups.entries.map((subEntry) {
                              final subheader = subEntry.key;
                              final tags = subEntry.value;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (subheader.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        subheader,
                                        style: AppTypography.sans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppConstants.textMutedColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: tags.map(_buildTagChip).toList(),
                                  ),
                                  if (subEntry.key != widget.subGroups.keys.last)
                                    const SizedBox(height: 16),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagChip(TagChipData data) {
    final tagParts = data.labelParts;
    final isSelected = widget.selectedTagIds.contains(data.tagId);

    return ChipBase(
      borderRadius: AppConstants.pillRadius,
      backgroundColor: isSelected
          ? AppConstants.accentColor
          : AppConstants.secondaryBackground,
      borderColor: isSelected
          ? AppConstants.accentColor
          : AppConstants.borderColor,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      onTap: () => widget.onTagTap(data.tag),
      onLongPress: () => widget.onTagLongPress(data.tag),
      label: Text.rich(
        TextSpan(
          children: [
            if (tagParts.length > 1) ...[
              TextSpan(
                text: '${tagParts.sublist(0, tagParts.length - 1).join(' > ')} > ',
                style: AppTypography.sans(
                  color: isSelected ? Colors.white70 : AppConstants.textMutedColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
              ),
            ],
            TextSpan(
              text: tagParts.last,
              style: AppTypography.sans(
                color: isSelected ? Colors.white : AppConstants.textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
