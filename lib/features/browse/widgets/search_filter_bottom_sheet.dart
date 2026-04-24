import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/browse/models/search_filters.dart';
import 'package:bakahyou/features/series/services/series_search_service.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';
import 'package:bakahyou/features/browse/widgets/tri_state_group.dart';
import 'package:bakahyou/features/browse/widgets/filter_list_dialog.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';

class SearchFilterBottomSheet extends StatefulWidget {
  final SearchFilters initialFilters;
  final ValueChanged<SearchFilters> onApply;

  const SearchFilterBottomSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<SearchFilterBottomSheet> createState() =>
      _SearchFilterBottomSheetState();
}

class _SearchFilterBottomSheetState extends State<SearchFilterBottomSheet> {
  late SearchFilters _filters;
  late final SeriesSearchService _searchService;

  final List<String> _types = ['manga', 'manhwa', 'manhua', 'novel', 'oel'];
  final List<String> _statuses = [
    'ongoing',
    'releasing',
    'completed',
    'hiatus',
    'cancelled',
  ];

  Map<String, String> _getSortOptions(LocalizationService l10n) {
    return {
      'name_asc': l10n.translate('title_asc'),
      'name_desc': l10n.translate('title_desc'),
      'popularity_asc': l10n.translate('popularity_asc'),
      'popularity_desc': l10n.translate('popularity_desc'),
      'random': l10n.translate('random_sort'),
    };
  }

  List<Map<String, dynamic>> _genres = [];
  List<Map<String, dynamic>> _tags = [];
  bool _isLoadingMetadata = true;

  final int _minYear = 1950;
  final int _maxYear = DateTime.now().year + 1;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
    _searchService = getIt<SeriesSearchService>();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    try {
      final results = await Future.wait([
        _searchService.getGenres(),
        _searchService.getTags(),
      ]);
      if (mounted) {
        setState(() {
          _genres = results[0];
          _tags = results[1];
          _isLoadingMetadata = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMetadata = false);
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: TextStyle(
          color: AppConstants.textColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showFilterDialog({
    required String title,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    required List<String> includes,
    required List<String> excludes,
    required Function(List<String>, List<String>) onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.tertiaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.cardRadius),
        ),
      ),
      builder: (context) {
        return FilterListDialog(
          title: title,
          items: items,
          idKey: idKey,
          nameKey: nameKey,
          initialIncludes: includes,
          initialExcludes: excludes,
          onApply: onApply,
        );
      },
    );
  }

  Widget _buildFilterRow(
    String title,
    List<String> includes,
    List<String> excludes,
    VoidCallback onTap,
    LocalizationService l10n,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppConstants.borderColor),
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                includes.isEmpty && excludes.isEmpty
                    ? '${l10n.translate('select')} $title...'
                    : '${includes.length} ${l10n.translate('included')}, ${excludes.length} ${l10n.translate('excluded')}',
                style: TextStyle(color: AppConstants.textMutedColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppConstants.textMutedColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  int _getDivisions() {
    final step = SettingsManager().ratingSliderStep;
    switch (step) {
      case RatingSliderStep.step5: return 20;
      case RatingSliderStep.step10: return 10;
      case RatingSliderStep.step20: return 5;
      case RatingSliderStep.step25: return 4;
      case RatingSliderStep.step1: return 100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) {
        final l10n = LocalizationService();
        final sortOptions = _getSortOptions(l10n);
        
        return SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppConstants.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _filters = SearchFilters()),
                      child: Text(
                        l10n.translate('reset'),
                        style: TextStyle(color: AppConstants.textMutedColor),
                      ),
                    ),
                    Text(
                      l10n.translate('filters'),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.onApply(_filters);
                        Navigator.pop(context);
                      },
                      child: Text(
                        l10n.translate('apply'),
                        style: TextStyle(
                          color: AppConstants.accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: AppConstants.borderColor, height: 1),
              Expanded(
                child: _isLoadingMetadata
                    ? Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: EdgeInsets.all(16.0),
                        children: [
                          _buildSectionTitle(l10n.translate('sort_by')),
                          DropdownButtonFormField<String>(
                            value: _filters.sortBy,
                            dropdownColor: AppConstants.tertiaryBackground,
                            style: TextStyle(color: AppConstants.textColor),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.cardRadius,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.cardRadius,
                                ),
                                borderSide: BorderSide(color: AppConstants.borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.cardRadius,
                                ),
                                borderSide: BorderSide(
                                  color: AppConstants.accentColor,
                                ),
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text(l10n.translate('default')),
                              ),
                              ...sortOptions.entries.map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              ),
                            ],
                            onChanged: (val) => setState(
                              () => _filters = _filters.copyWith(sortBy: val),
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildSectionTitle(l10n.translate('genres')),
                          _buildFilterRow(
                            l10n.translate('genres'),
                            _filters.genre,
                            _filters.genreNot,
                            () {
                              _showFilterDialog(
                                title: l10n.translate('genres'),
                                items: _genres,
                                idKey: 'value',
                                nameKey: 'label',
                                includes: _filters.genre,
                                excludes: _filters.genreNot,
                                onApply: (inc, exc) => setState(
                                  () => _filters = _filters.copyWith(
                                    genre: inc,
                                    genreNot: exc,
                                  ),
                                ),
                              );
                            },
                            l10n,
                          ),
                          const SizedBox(height: 16),

                          _buildSectionTitle(l10n.translate('tags')),
                          _buildFilterRow(
                            l10n.translate('tags'),
                            _filters.tag,
                            _filters.tagNot,
                            () {
                              _showFilterDialog(
                                title: l10n.translate('tags'),
                                items: _tags,
                                idKey: 'id',
                                nameKey: 'name',
                                includes: _filters.tag,
                                excludes: _filters.tagNot,
                                onApply: (inc, exc) => setState(
                                  () => _filters = _filters.copyWith(
                                    tag: inc,
                                    tagNot: exc,
                                  ),
                                ),
                              );
                            },
                            l10n,
                          ),
                          const SizedBox(height: 16),

                          TriStateGroup(
                            title: l10n.translate('type'),
                            options: _types
                                .map(
                                  (t) => {
                                    'value': t,
                                    'label': l10n.translate('type_$t'),
                                  },
                                )
                                .toList(),
                            includes: _filters.type,
                            excludes: _filters.typeNot,
                            onUpdate: (inc, exc) => setState(
                              () => _filters = _filters.copyWith(
                                type: inc,
                                typeNot: exc,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TriStateGroup(
                            title: l10n.translate('status'),
                            options: _statuses
                                .map(
                                  (s) => {
                                    'value': s,
                                    'label': l10n.translate('status_$s'),
                                  },
                                )
                                .toList(),
                            includes: _filters.status,
                            excludes: _filters.statusNot,
                            onUpdate: (inc, exc) => setState(
                              () => _filters = _filters.copyWith(
                                status: inc,
                                statusNot: exc,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildSectionTitle(l10n.translate('licensed_status')),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: Text(l10n.translate('any')),
                                selected: _filters.isLicensed == null,
                                onSelected: (val) => setState(
                                  () =>
                                      _filters = _filters.copyWithIsLicensed(null),
                                ),
                                selectedColor: AppConstants.accentColor.withValues(
                                  alpha: 0.3,
                                ),
                                labelStyle: TextStyle(
                                  color: _filters.isLicensed == null
                                      ? AppConstants.accentColor
                                      : AppConstants.textColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.cardRadius,
                                  ),
                                ),
                              ),
                              ChoiceChip(
                                label: Text(l10n.translate('yes')),
                                selected: _filters.isLicensed == true,
                                onSelected: (val) => setState(
                                  () =>
                                      _filters = _filters.copyWithIsLicensed(true),
                                ),
                                selectedColor: AppConstants.accentColor.withValues(
                                  alpha: 0.3,
                                ),
                                labelStyle: TextStyle(
                                  color: _filters.isLicensed == true
                                      ? AppConstants.accentColor
                                      : AppConstants.textColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.cardRadius,
                                  ),
                                ),
                              ),
                              ChoiceChip(
                                label: Text(l10n.translate('no')),
                                selected: _filters.isLicensed == false,
                                onSelected: (val) => setState(
                                  () =>
                                      _filters = _filters.copyWithIsLicensed(false),
                                ),
                                selectedColor: AppConstants.accentColor.withValues(
                                  alpha: 0.3,
                                ),
                                labelStyle: TextStyle(
                                  color: _filters.isLicensed == false
                                      ? AppConstants.accentColor
                                      : AppConstants.textColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.cardRadius,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildSectionTitle(
                            '${l10n.translate('rating_range')} (${_filters.ratingLower.toInt()} - ${_filters.ratingUpper.toInt()})',
                          ),
                          RangeSlider(
                            values: RangeValues(
                              _filters.ratingLower,
                              _filters.ratingUpper,
                            ),
                            min: 0,
                            max: 100,
                            divisions: _getDivisions(),
                            activeColor: AppConstants.accentColor,
                            inactiveColor: AppConstants.borderColor,
                            labels: RangeLabels(
                              '${_filters.ratingLower.toInt()}',
                              '${_filters.ratingUpper.toInt()}',
                            ),
                            onChanged: (values) => setState(
                              () => _filters = _filters.copyWith(
                                ratingLower: values.start,
                                ratingUpper: values.end,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildSectionTitle(
                            '${l10n.translate('publication_year')} (${_filters.publishedYearLower ?? l10n.translate('any')} - ${_filters.publishedYearUpper ?? l10n.translate('any')})',
                          ),
                          RangeSlider(
                            values: RangeValues(
                              (_filters.publishedYearLower ?? _minYear).toDouble(),
                              (_filters.publishedYearUpper ?? _maxYear).toDouble(),
                            ),
                            min: _minYear.toDouble(),
                            max: _maxYear.toDouble(),
                            divisions: _maxYear - _minYear,
                            activeColor: AppConstants.accentColor,
                            inactiveColor: AppConstants.borderColor,
                            labels: RangeLabels(
                              _filters.publishedYearLower == null
                                  ? l10n.translate('any')
                                  : '${_filters.publishedYearLower}',
                              _filters.publishedYearUpper == null
                                  ? l10n.translate('any')
                                  : '${_filters.publishedYearUpper}',
                            ),
                            onChanged: (values) => setState(
                              () => _filters = _filters.copyWith(
                                publishedYearLower: values.start.toInt() == _minYear
                                    ? null
                                    : values.start.toInt(),
                                publishedYearUpper: values.end.toInt() == _maxYear
                                    ? null
                                    : values.end.toInt(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
