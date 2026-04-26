import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/features/series/widgets/chips/type_chip.dart';
import 'package:bakahyou/features/series/widgets/chips/status_chip.dart';
import 'package:bakahyou/features/series/widgets/chips/licensed_chip.dart';
import 'package:bakahyou/features/series/widgets/chips/volume_chip.dart';
import 'package:bakahyou/features/series/widgets/chips/chapters_chip.dart';
import 'package:bakahyou/features/series/widgets/chips/date_range_chip.dart';
import 'package:bakahyou/features/series/widgets/chips/has_anime_chip.dart';
import 'package:bakahyou/features/series/widgets/chips/rating_chip.dart';
import 'package:bakahyou/features/series/widgets/chips/content_rating_chip.dart';
import 'package:bakahyou/features/series/widgets/id_chip.dart';

import 'package:bakahyou/utils/settings/settings_manager.dart';

class SeriesDetailHeader extends StatelessWidget {
  final Series series;
  final int? progressChapter;
  final int? progressVolume;
  final bool inLibrary;

  const SeriesDetailHeader({
    super.key,
    required this.series,
    this.progressChapter,
    this.progressVolume,
    this.inLibrary = false,
  });

  @override
  Widget build(BuildContext context) {
    final settings = SettingsManager();
    final preferredTitle = series.getDisplayTitle(settings.defaultTitleLanguage);
    
    // Determine which other titles to show
    final otherTitles = <String>[];
    if (series.title.isNotEmpty && series.title != preferredTitle) {
      otherTitles.add(series.title);
    }
    if (series.nativeTitle.isNotEmpty && 
        series.nativeTitle != preferredTitle && 
        !otherTitles.contains(series.nativeTitle)) {
      otherTitles.add(series.nativeTitle);
    }
    if (series.romanizedTitle.isNotEmpty && 
        series.romanizedTitle != preferredTitle && 
        !otherTitles.contains(series.romanizedTitle)) {
      otherTitles.add(series.romanizedTitle);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (series.coverUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              series.coverUrl,
              height: 160,
              width: 110,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          Clipboard.setData(ClipboardData(text: preferredTitle)),
                      child: Text(
                        preferredTitle,
                        style: Theme.of(context).textTheme.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IdChip(id: series.id),
                ],
              ),
              ...otherTitles.map((t) => Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: GestureDetector(
                  onTap: () => Clipboard.setData(ClipboardData(text: t)),
                  child: Text(
                    t,
                    style: t == otherTitles.first 
                      ? Theme.of(context).textTheme.bodyMedium
                      : Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              )),

              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TypeChip(type: series.type),
                  StatusChip(status: series.status),
                  if (series.isLicensed == 'true') LicensedChip(),
                  if (series.finalVolume.isNotEmpty &&
                      series.finalVolume != 'null')
                    VolumeChip(
                      volume: series.finalVolume,
                      progress: progressVolume,
                      inLibrary: inLibrary,
                    ),
                  if (series.totalChapters.isNotEmpty &&
                      series.totalChapters != 'null')
                    ChaptersChip(
                      chapters: series.totalChapters,
                      progress: progressChapter,
                      inLibrary: inLibrary,
                    ),
                  if ((series.published?['start_date']?.toString().isNotEmpty ??
                          false) ||
                      (series.published?['end_date']?.toString().isNotEmpty ??
                          false))
                    DateRangeChip(
                      start: series.published?['start_date']?.toString() ?? '',
                      end: series.published?['end_date']?.toString() ?? '',
                    ),
                  if (series.hasAnime == 'true') HasAnimeChip(),
                  RatingChip(sources: (series.source?.values.toList() ?? [])),
                  if ([
                    'suggestive',
                    'erotica',
                    'pornographic',
                  ].contains(series.contentRating.toLowerCase()))
                    ContentRatingChip(rating: series.contentRating),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
