import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/widgets/chip.dart';

class VolumeChip extends StatelessWidget {
  final String volume;
  final int? progress;
  final bool inLibrary;

  const VolumeChip({
    required this.volume,
    this.progress,
    this.inLibrary = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (volume.isEmpty || volume == 'null') return SizedBox.shrink();

    if (inLibrary) {
      final progressValue = progress ?? 0;
      return ChipBase(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shelves, size: 18, color: Colors.white),
            const SizedBox(width: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$progressValue',
                    style: TextStyle(
                      color: Color(0xFF16d492),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: ' of $volume Vol.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ChipBase(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shelves, size: 18, color: Colors.white),
          const SizedBox(width: 4),
          Text('$volume Vol.'),
        ],
      ),
    );
  }
}
