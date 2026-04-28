import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/models/series.dart';

class SeriesHeroCover extends StatelessWidget {
  final Series series;
  final double height;
  final double width;

  const SeriesHeroCover({
    super.key,
    required this.series,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'series_cover_${series.id}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            series.coverUrl,
            height: height,
            width: width,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            cacheWidth: 400,
          ),
        ),
      ),
    );
  }
}
