import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/features/library/models/library_entry.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/series/widgets/series_hero_cover.dart';

class SeriesDetailAppBar extends StatelessWidget {
  final Series series;
  final String title;
  final LibraryEntry? entry;
  final bool isWide;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final Function(String) onCopy;

  const SeriesDetailAppBar({
    super.key,
    required this.series,
    required this.title,
    this.entry,
    required this.isWide,
    required this.onBack,
    required this.onShare,
    required this.onDelete,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: isWide ? 400 : 320,
      pinned: true,
      backgroundColor: AppConstants.primaryBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black26,
          foregroundColor: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: onShare,
          style: IconButton.styleFrom(
            backgroundColor: Colors.black26,
            foregroundColor: Colors.white,
          ),
        ),
        if (entry != null)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black26,
              foregroundColor: Colors.white,
            ),
          ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 16),
        centerTitle: false,
        title: LayoutBuilder(
          builder: (context, constraints) {
            final double top = constraints.biggest.height;
            final bool collapsed = top < (MediaQuery.of(context).padding.top + kToolbarHeight + 20);
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: collapsed ? 1.0 : 0.0,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 600 : 200),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (series.coverUrl.isNotEmpty)
              Image.network(
                series.coverUrl,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                cacheWidth: isWide ? 1200 : 800,
              ),
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppConstants.primaryBackground.withValues(alpha: 0.8),
                    AppConstants.primaryBackground,
                  ],
                  stops: const [0.4, 0.8, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SeriesHeroCover(
                    series: series,
                    height: isWide ? 220 : 180,
                    width: isWide ? 150 : 125,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMainInfo(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfo(BuildContext context) {
    final otherTitles = <String>[];
    if (series.title.isNotEmpty && series.title != title) {
      otherTitles.add(series.title);
    }
    if (series.nativeTitle.isNotEmpty && 
        series.nativeTitle != title && 
        !otherTitles.contains(series.nativeTitle)) {
      otherTitles.add(series.nativeTitle);
    }
    if (series.romanizedTitle.isNotEmpty && 
        series.romanizedTitle != title && 
        !otherTitles.contains(series.romanizedTitle)) {
      otherTitles.add(series.romanizedTitle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => onCopy(title),
          borderRadius: BorderRadius.circular(4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: isWide ? 32 : 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (otherTitles.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...otherTitles.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: InkWell(
              onTap: () => onCopy(t),
              borderRadius: BorderRadius.circular(4),
              child: Text(
                t,
                style: TextStyle(
                  fontSize: isWide ? 15 : 13,
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )),
        ],
      ],
    );
  }
}
