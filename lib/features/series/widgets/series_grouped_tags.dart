import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/models/tag_chip_data.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/series/widgets/series_tag_group.dart';
import 'package:mangabaka_app/features/series/widgets/mb_card.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';

/// One resolved tag header, with its tags bucketed by subheader.
class _TagGroup {
  final String header;
  final Map<String, List<TagChipData>> subGroups;

  const _TagGroup(this.header, this.subGroups);
}

/// The tags card on the series detail page.
///
/// Tags are the heaviest part of that page — a well-tagged series carries a
/// couple of hundred chips, each of which has to be resolved through
/// [MetadataService] and laid out as rich text. Doing that in the same frame as
/// the rest of the page is what made opening a series feel like a stall of up
/// to a second, while untagged series opened instantly.
///
/// So this widget draws in two passes: the first frame gets a cheap placeholder
/// card, and the tags themselves are resolved and built on the following frame.
/// The page is on screen before any tag work starts.
class SeriesGroupedTags extends StatefulWidget {
  final Series series;
  final LocalizationService l10n;

  const SeriesGroupedTags({
    super.key,
    required this.series,
    required this.l10n,
  });

  @override
  State<SeriesGroupedTags> createState() => _SeriesGroupedTagsState();
}

class _SeriesGroupedTagsState extends State<SeriesGroupedTags> {
  /// How many chips the collapsed card is allowed to build.
  ///
  /// Collapsed, the card clips to 400px — roughly a dozen rows, so three or
  /// four dozen chips. Everything past that was still being built, laid out
  /// and measured, only to be thrown away behind the `ClipRect`: a series with
  /// 250 tags paid for 250 chips to show about 35. This budget is comfortably
  /// more than fills the clip, and bounds the cost of opening a series no
  /// matter how heavily tagged it is. Expanding builds the rest.
  static const int _collapsedChipBudget = 60;

  bool _tagsExpanded = false;

  /// Resolved tag data. Null until the deferred second pass has run.
  List<_TagGroup>? _groups;
  int _totalChips = 0;
  List<Widget>? _cachedContent;
  bool _cachedExpanded = false;

  final GlobalKey _contentKey = GlobalKey();
  bool _needsShowMore = false;
  double _contentHeight = 0.0;
  SearchFilters? _lastDrawerFilters;

  /// True when the collapsed card cannot show everything — either because the
  /// budget trimmed it, or because what did fit still overflows the clip.
  bool get _hasMore => _totalChips > _collapsedChipBudget || _needsShowMore;

  @override
  void initState() {
    super.initState();
    _scheduleResolve();
  }

  /// Hands the current frame back to the framework, then resolves the tags.
  ///
  /// On a phone this card starts below the fold, so it also waits out the push
  /// transition: the page is fully readable while it slides, and the tag build
  /// lands on a frame where nothing is animating.
  void _scheduleResolve() {
    if (widget.series.tags.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _groups != null) return;
      await SeriesDetailScreen.of(context)?.transitionSettled;
      if (!mounted || _groups != null) return;
      setState(() {
        _groups = _resolveGroups();
        _cachedContent = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureContent());
    });
  }

  void _measureContent() {
    if (!mounted) return;
    final renderBox = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final height = renderBox.size.height;
      final needsShowMore = height > 400.0;
      if (needsShowMore != _needsShowMore || height != _contentHeight) {
        setState(() {
          _needsShowMore = needsShowMore;
          _contentHeight = height;
        });
      }
    }
  }

  /// Resolves every tag through [MetadataService] exactly once: its path drives
  /// both the grouping and the chip's display label, and its id drives the
  /// selected state, so none of that is redone per rebuild.
  List<_TagGroup> _resolveGroups() {
    final metadataService = getIt<MetadataService>();
    final Map<String, Map<String, List<TagChipData>>> grouped = {};

    for (final tag in widget.series.tags) {
      final path = metadataService.getTagPath(tag) ?? tag;
      final parts = path.split(' > ');

      String header = 'Other';
      String subheader = '';

      if (parts.length >= 2) {
        header = parts[0];
        if (parts.length >= 3) {
          subheader = parts[1];
        }
      }

      List<String> labelParts = <String>[tag];
      if (parts.length == 2) {
        labelParts = <String>[parts[1]];
      } else if (parts.length >= 3) {
        labelParts = parts.sublist(2);
      }

      grouped.putIfAbsent(header, () => {});
      grouped[header]!.putIfAbsent(subheader, () => []);
      grouped[header]![subheader]!.add(TagChipData(
        tag: tag,
        tagId: metadataService.getTagId(tag) ?? tag,
        labelParts: labelParts,
      ));
    }

    _totalChips = widget.series.tags.length;
    final sortedHeaders = grouped.keys.toList()..sort();
    return [
      for (final header in sortedHeaders) _TagGroup(header, grouped[header]!),
    ];
  }

  /// The groups to actually build. Collapsed, this is a prefix of the tags that
  /// fills the clip and no more; expanded, it is everything.
  List<_TagGroup> _groupsToBuild() {
    if (_tagsExpanded || _totalChips <= _collapsedChipBudget) return _groups!;

    final trimmed = <_TagGroup>[];
    var remaining = _collapsedChipBudget;

    for (final group in _groups!) {
      if (remaining <= 0) break;
      final subGroups = <String, List<TagChipData>>{};
      for (final entry in group.subGroups.entries) {
        if (remaining <= 0) break;
        subGroups[entry.key] = entry.value.length <= remaining
            ? entry.value
            : entry.value.sublist(0, remaining);
        remaining -= subGroups[entry.key]!.length;
      }
      trimmed.add(_TagGroup(group.header, subGroups));
    }
    return trimmed;
  }

  void _handleTagTap(String tag) {
    final detailState = SeriesDetailScreen.of(context);
    if (detailState?.drawerFilters != null) {
      detailState?.handleTagLongPress(tag);
    } else {
      detailState?.handleTagTap(tag);
    }
  }

  void _handleTagLongPress(String tag) =>
      SeriesDetailScreen.of(context)?.handleTagLongPress(tag);

  void _ensureContent() {
    final detailState = SeriesDetailScreen.of(context);
    final currentFilters = detailState?.drawerFilters;
    if (currentFilters != _lastDrawerFilters || _cachedExpanded != _tagsExpanded) {
      _cachedContent = null;
      _lastDrawerFilters = currentFilters;
      _cachedExpanded = _tagsExpanded;
    }

    if (_cachedContent != null) return;

    final selectedTagIds = currentFilters?.tag.toSet() ?? const <String>{};

    _cachedContent = _groupsToBuild().map((group) {
      return SeriesTagGroup(
        header: group.header,
        subGroups: group.subGroups,
        selectedTagIds: selectedTagIds,
        onTagTap: _handleTagTap,
        onTagLongPress: _handleTagLongPress,
        onToggle: () {
          WidgetsBinding.instance.addPostFrameCallback((_) => _measureContent());
        },
      );
    }).toList();
  }

  @override
  void didUpdateWidget(SeriesGroupedTags oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Compare contents, not list identity: the network `fullSeries` swaps in a
    // fresh Series a moment after open, and its tags are almost always the same
    // ones we already resolved.
    if (!listEquals(widget.series.tags, oldWidget.series.tags)) {
      _groups = null;
      _totalChips = 0;
      _cachedContent = null;
      _needsShowMore = false;
      _contentHeight = 0.0;
      _scheduleResolve();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.series.tags.isEmpty) return const SizedBox.shrink();

    // First pass: the page draws without paying for any tag work.
    if (_groups == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: MbCard(
          label: widget.l10n.translate('tags'),
          child: const _TagsPlaceholder(),
        ),
      );
    }

    _ensureContent();

    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _measureContent());
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: MbCard(
            label: widget.l10n.translate('tags'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: _needsShowMore && !_tagsExpanded
                        ? const BoxConstraints(maxHeight: 400)
                        : const BoxConstraints(),
                    child: ClipRect(
                      child: Stack(
                        children: [
                          SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              key: _contentKey,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _cachedContent!,
                            ),
                          ),
                          if (!_tagsExpanded && _needsShowMore)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppConstants.secondaryBackground.withValues(alpha: 0),
                                      AppConstants.secondaryBackground,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_hasMore) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: InkWell(
                      onTap: () => setState(() => _tagsExpanded = !_tagsExpanded),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _tagsExpanded ? widget.l10n.translate('show_less') : widget.l10n.translate('show_all_tags'),
                              style: AppTypography.sans(
                                color: AppConstants.accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _tagsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: AppConstants.accentColor,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Cheap stand-in shown for the one frame before the real tags are built — a
/// couple of rows of pill outlines so the card doesn't pop in from nothing.
class _TagsPlaceholder extends StatelessWidget {
  const _TagsPlaceholder();

  static const _rows = <List<double>>[
    [90, 130, 70],
    [110, 80, 150],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in _rows) ...[
          Row(
            children: [
              for (final width in row) ...[
                Container(
                  width: width,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppConstants.tertiaryBackground.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppConstants.pillRadius),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          if (row != _rows.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}
