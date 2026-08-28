import 'package:mangabaka_app/features/profile/widgets/statistics/statistics_data_mixin.dart';
import 'package:mangabaka_app/features/profile/widgets/statistics/standout_pick_card.dart';
import 'package:mangabaka_app/features/profile/widgets/statistics/statistic_card.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/library/services/mappers/db_to_api_mapper.dart';
import 'package:mangabaka_app/core/database/database.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with StatisticsDataMixin {
  @override
  void initState() {
    super.initState();
    initStatistics();
  }

  void _openSeriesDetail(LibraryEntryWithSeries entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeriesDetailScreen(
          series: DbToApiMapper.seriesFromDb(entry.series),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) {
        final l10n = LocalizationService();

        return Scaffold(
          backgroundColor: AppConstants.primaryBackground,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            centerTitle: true,
            title: Text(
              l10n.translate('statistics').toUpperCase(),
              style: AppTypography.display(
            color: AppConstants.textColor,
            fontSize: 20,
          ),
            ),
          ),
          body: WidgetUtils.responsiveConstraint(
            loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('reading_stats').toUpperCase(),
                          style: AppTypography.display(
                            color: AppConstants.textColor,
                            fontSize: 20,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow([
                          _StatData(Icons.book, l10n.translate('total_series'), '$totalSeries', iconColor: AppConstants.accentColor),
                          _StatData(Icons.article, l10n.translate('chapters_read'), '$chaptersRead', iconColor: AppConstants.infoColor),
                        ]),
                        const SizedBox(height: 16),
                        _buildStatRow([
                          _StatData(Icons.library_books, l10n.translate('volumes_read'), '$volumesRead', iconColor: const Color(0xFFAC4BFF)),
                          _StatData(Icons.check_circle, l10n.translate('completion'), '${completionRate.toStringAsFixed(1)}%', iconColor: const Color(0xFF4FBEC4)),
                        ]),
                        const SizedBox(height: 16),
                        _buildStatRow([
                          _StatData(Icons.replay, l10n.translate('total_rereads'), '$totalRereads', iconColor: const Color(0xFFF98F3A)),
                          _StatData(Icons.star, l10n.translate('mean_score'), meanScore.toStringAsFixed(1), iconColor: AppConstants.starColor),
                        ]),
                        const SizedBox(height: 16),
                        _buildStatRow([
                          _StatData(Icons.flag, l10n.translate('finish_rate'), '${finishRate.toStringAsFixed(1)}%', iconColor: const Color(0xFFD71F75)),
                        ]),
                        const SizedBox(height: 32),
                        Text(
                          l10n.translate('standout_picks').toUpperCase(),
                          style: AppTypography.display(
                            color: AppConstants.textColor,
                            fontSize: 20,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (highestRated != null)
                          StandoutPickCard(
                            icon: Icons.star_rounded,
                            label: l10n.translate('highest_rated'),
                            title: highestRated!.series.title,
                            value: '${l10n.translate('score')}: ${highestRated!.libraryEntry.rating ?? 0}',
                            onTap: () => _openSeriesDetail(highestRated!),
                          ),
                        if (mostReread != null) ...[
                          const SizedBox(height: 16),
                          StandoutPickCard(
                            icon: Icons.replay_rounded,
                            label: l10n.translate('most_reread'),
                            title: mostReread!.series.title,
                            value: '${mostReread!.libraryEntry.numberOfRereads} ${l10n.translate('rereads')}',
                            onTap: () => _openSeriesDetail(mostReread!),
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildStatRow(List<_StatData> stats) {
    return Row(
      children: [
        for (int i = 0; i < stats.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < stats.length - 1 ? 16 : 0),
              child: StatisticCard(
                icon: stats[i].icon,
                label: stats[i].label,
                value: stats[i].value,
                iconColor: stats[i].iconColor,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatData {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const _StatData(this.icon, this.label, this.value, {this.iconColor});
}
