import 'package:bakahyou/features/browse/models/series_filter.dart';
import 'package:bakahyou/features/browse/widgets/filter_widgets.dart';
import 'package:bakahyou/features/browse/services/genre_tag_cache.dart';
import 'package:bakahyou/features/browse/models/genre.dart';
import 'package:bakahyou/features/browse/models/tag.dart';
import 'package:flutter/material.dart';

class BrowseSearchScreen extends StatefulWidget {
  const BrowseSearchScreen({super.key});

  @override
  State<BrowseSearchScreen> createState() => _BrowseSearchScreenState();
}

class _BrowseSearchScreenState extends State<BrowseSearchScreen> {
  final _searchController = TextEditingController();
  late SeriesFilter _filter;
  late final GenreTagCache _cache;
  
  List<Genre> _genres = [];
  List<Tag> _tags = [];
  bool _genresLoaded = false;
  bool _tagsLoaded = false;

  @override
  void initState() {
    super.initState();
    _filter = SeriesFilter();
    _cache = GenreTagCache();
    _loadGenresAndTags();
  }

  void _loadGenresAndTags() {
    _cache.getGenres().then((genres) {
      if (mounted) {
        setState(() {
          _genres = genres;
          _genresLoaded = true;
        });
      }
    }).catchError((e) {
      if (mounted) {
        setState(() => _genresLoaded = true);
      }
    });

    _cache.getTags().then((tags) {
      if (mounted) {
        setState(() {
          _tags = tags;
          _tagsLoaded = true;
        });
      }
    }).catchError((e) {
      if (mounted) {
        setState(() => _tagsLoaded = true);
      }
    });
  }

  void _applyFilters() {
    Navigator.pop(context, _filter);
  }

  void _clearAllFilters() {
    setState(() {
      _filter = SeriesFilter();
      _searchController.clear();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18181B),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search series...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            _filter.q = value.isEmpty ? null : value;
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _applyFilters,
          ),
        ],
      ),
      body: _FilterContent(
        filter: _filter,
        onFilterChanged: (newFilter) {
          _filter = newFilter;
        },
        genres: _genres,
        tags: _tags,
        genresLoaded: _genresLoaded,
        tagsLoaded: _tagsLoaded,
        onClearAll: _clearAllFilters,
        onApply: _applyFilters,
      ),
    );
  }
}

class _FilterContent extends StatelessWidget {
  final SeriesFilter filter;
  final ValueChanged<SeriesFilter> onFilterChanged;
  final List<Genre> genres;
  final List<Tag> tags;
  final bool genresLoaded;
  final bool tagsLoaded;
  final VoidCallback onClearAll;
  final VoidCallback onApply;

  const _FilterContent({
    required this.filter,
    required this.onFilterChanged,
    required this.genres,
    required this.tags,
    required this.genresLoaded,
    required this.tagsLoaded,
    required this.onClearAll,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: onClearAll,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _TypeFilterSection(filter: filter, onFilterChanged: onFilterChanged),
            _ExcludeTypeFilterSection(filter: filter, onFilterChanged: onFilterChanged),
            _StatusFilterSection(filter: filter, onFilterChanged: onFilterChanged),
            _ExcludeStatusFilterSection(filter: filter, onFilterChanged: onFilterChanged),
            _ContentRatingFilterSection(filter: filter, onFilterChanged: onFilterChanged),
            _ExcludeContentRatingFilterSection(filter: filter, onFilterChanged: onFilterChanged),
            if (genresLoaded)
              _GenreFilterSection(filter: filter, onFilterChanged: onFilterChanged, genres: genres)
            else
              const _LoadingPlaceholder(height: 100),
            if (genresLoaded)
              _ExcludeGenreFilterSection(filter: filter, onFilterChanged: onFilterChanged, genres: genres)
            else
              const _LoadingPlaceholder(height: 100),
            if (tagsLoaded && tags.isNotEmpty)
              _TagFilterSection(filter: filter, onFilterChanged: onFilterChanged, tags: tags)
            else if (tagsLoaded)
              const SizedBox.shrink()
            else
              const _LoadingPlaceholder(height: 100),
            if (tagsLoaded && tags.isNotEmpty)
              _ExcludeTagFilterSection(filter: filter, onFilterChanged: onFilterChanged, tags: tags),
            _TagModeFilterSection(filter: filter, onFilterChanged: onFilterChanged),
            _LicensedFilterSection(filter: filter, onFilterChanged: onFilterChanged),
            _RatingRangeFilterSection(filter: filter, onFilterChanged: onFilterChanged),
            _PublishedStartDateFilterSection(filter: filter, onFilterChanged: onFilterChanged),
            _PublishedEndDateFilterSection(filter: filter, onFilterChanged: onFilterChanged),
            _SortByFilterSection(filter: filter, onFilterChanged: onFilterChanged),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onApply,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF1b9f70),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  final double height;

  const _LoadingPlaceholder({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _TypeFilterSection extends StatelessWidget {
  final SeriesFilter filter;
  final ValueChanged<SeriesFilter> onFilterChanged;

  const _TypeFilterSection({
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MultiSelectFilterSection(
      title: 'Type',
      options: const ['manga', 'novel', 'oel'],
      selectedOptions: filter.type ?? [],
      onSelectionChanged: (selected) {
        filter.type = selected.isEmpty ? null : selected;
        onFilterChanged(filter);
      },
    );
  }
}

class _ExcludeTypeFilterSection extends StatelessWidget {
  final SeriesFilter filter;
  final ValueChanged<SeriesFilter> onFilterChanged;

  const _ExcludeTypeFilterSection({
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MultiSelectFilterSection(
      title: 'Exclude Type',
      options: const ['manga', 'novel', 'oel'],
      selectedOptions: filter.typeNot ?? [],
      onSelectionChanged: (selected) {
        filter.typeNot = selected.isEmpty ? null : selected;
        onFilterChanged(filter);
      },
    );
  }
}

class _StatusFilterSection extends StatelessWidget {
  final SeriesFilter filter;
  final ValueChanged<SeriesFilter> onFilterChanged;

  const _StatusFilterSection({
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MultiSelectFilterSection(
      title: 'Status',
      options: const ['ongoing', 'completed', 'cancelled', 'hiatus'],
      selectedOptions: filter.status ?? [],
      onSelectionChanged: (selected) {
        filter.status = selected.isEmpty ? null : selected;
        onFilterChanged(filter);
      },
    );
  }
}

class _ExcludeStatusFilterSection extends StatelessWidget {
  final SeriesFilter filter;
  final ValueChanged<SeriesFilter> onFilterChanged;

  const _ExcludeStatusFilterSection({
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MultiSelectFilterSection(
      title: 'Exclude Status',
      options: const ['ongoing', 'completed', 'cancelled', 'hiatus'],
      selectedOptions: filter.statusNot ?? [],
      onSelectionChanged: (selected) {
        filter.statusNot = selected.isEmpty ? null : selected;
        onFilterChanged(filter);
      },
    );
  }
}

class _ContentRatingFilterSection extends StatelessWidget {
  final SeriesFilter filter;
  final ValueChanged<SeriesFilter> onFilterChanged;

  const _ContentRatingFilterSection({
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MultiSelectFilterSection(
      title: 'Content Rating',
      options: const ['safe', 'suggestive', 'erotica', 'pornographic'],
      selectedOptions: filter.contentRating ?? [],
      onSelectionChanged: (selected) {
        filter.contentRating = selected.isEmpty ? null : selected;
        onFilterChanged(filter);
      },
      description: 'Select content ratings you want to see',
    );
  }
}

class _ExcludeContentRatingFilterSection extends StatelessWidget {
  final SeriesFilter filter;
  final ValueChanged<SeriesFilter> onFilterChanged;

  const _ExcludeContentRatingFilterSection({
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MultiSelectFilterSection(
      title: 'Exclude Content Rating',
      options: const ['safe', 'suggestive', 'erotica', 'pornographic'],
      selectedOptions: filter.notContentRating ?? [],
      onSelectionChanged: (selected) {
        filter.notContentRating = selected.isEmpty ? null : selected;
        onFilterChanged(filter);
      },
    );
  }
}

class _GenreFilterSection extends StatelessWidget {
  final SeriesFilter filter;
  final ValueChanged<SeriesFilter> onFilterChanged;
  final List<Genre> genres;

  const _GenreFilterSection({
    required this.filter,
    required this.onFilterChanged,
    required this.genres,
  });

  @override
  Widget build(BuildContext context) {
    return MultiSelectFilterSection(
      title: 'Genres',
      options: genres.map((g) => g.value).toList(),
      selectedOptions: filter.genre ?? [],
      onSelectionChanged: (selected) {
        filter.genre = selected.isEmpty ? null : selected;
        onFilterChanged(filter);
      },
    );
  }
}

class _ExcludeGenreFilterSection extends StatelessWidget {
  final SeriesFilter filter;
  final ValueChanged<SeriesFilter> onFilterChanged;
  final List<Genre> genres;

  const _ExcludeGenreFilterSection({
    required this.filter,
    required this.onFilterChanged,
    required this.genres,
  });

  @override
  Widget build(BuildContext context) {
    return MultiSelectFilterSection(
      title: 'Exclude Genres',
      options: genres.map((g) => g.value).toList(),
      selectedOptions: filter.genreNot ?? [],
      onSelectionChanged: (selected) {
        filter.genreNot = selected.isEmpty ? null : selected;
        onFilterChanged(filter);
      },
    );
  }
}

class _TagFilterSection extends StatelessWidget {
  final SeriesFilter filter;
  final ValueChanged<SeriesFilter> onFilterChanged;
  final List<Tag> tags;

  const _TagFilterSection({
    required this.filter,
    required this.onFilterChanged,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return MultiSelectFilterSection(
      title: 'Tags',
      options: tags.map((t) => t.name).toList(),
      selectedOptions: filter.tag ?? [],
      onSelectionChanged: (selected) {
        filter.tag = selected.isEmpty ? null : selected;
        onFilterChanged(filter);
      },
    );
  }
}

class _ExcludeTagFilterSection extends StatelessWidget {
  final SeriesFilter filter;
  final ValueChanged<SeriesFilter> onFilterChanged;
  final List<Tag> tags;

  const _ExcludeTagFilterSection({
    required this.filter,
    required this.onFilterChanged,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return MultiSelectFilterSection(
      title: 'Exclude Tags',
      options: tags.map((t) => t.name).toList(),
      selectedOptions: filter.tagNot ?? [],
      onSelectionChanged: (selected) {
        filter.tagNot = selected.isEmpty ? null : selected;
        onFilterChanged(filter);
      },
    );
  }
}

class _TagModeFilterSection extends StatelessWidget {
  final SeriesFilter filter;
  final ValueChanged<SeriesFilter> onFilterChanged;

  const _TagModeFilterSection({
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleSelectFilterSection(
      title: 'Tag Mode',
      options: const ['and', 'or'],
      selectedOption: filter.tagMode,
      onSelectionChanged: (value) {
        filter.tagMode = value;
        onFilterChanged(filter);
      },
    );
  }
}

class _LicensedFilterSection extends StatelessWidget {
  final SeriesFilter filter;
  final ValueChanged<SeriesFilter> onFilterChanged;

  const _LicensedFilterSection({
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Licensed',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            children: [
              FilterOptionChip(
                label: 'All',
                isSelected: filter.isLicensed == null,
                onSelected: (_) {
                  filter.isLicensed = null;
                  onFilterChanged(filter);
                },
              ),
              FilterOptionChip(
                label: 'Licensed Only',
                isSelected: filter.isLicensed == true,
                onSelected: (selected) {
                  filter.isLicensed = selected ? true : null;
                  onFilterChanged(filter);
                },
              ),
              FilterOptionChip(
                label: 'Unlicensed Only',
                isSelected: filter.isLicensed == false,
                onSelected: (selected) {
                  filter.isLicensed = selected ? false : null;
                  onFilterChanged(filter);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingRangeFilterSection extends StatelessWidget {
  final SeriesFilter filter;
  final ValueChanged<SeriesFilter> onFilterChanged;

  const _RatingRangeFilterSection({
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RangeFilterSection(
      title: 'Rating Range',
      min: 0,
      max: 100,
      currentMin: filter.ratingLower ?? 0,
      currentMax: filter.ratingUpper ?? 100,
      onRangeChanged: (values) {
        filter.ratingLower = values.start;
        filter.ratingUpper = values.end;
        onFilterChanged(filter);
      },
    );
  }
}

class _PublishedStartDateFilterSection extends StatelessWidget {
  final SeriesFilter filter;
  final ValueChanged<SeriesFilter> onFilterChanged;

  const _PublishedStartDateFilterSection({
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DateRangeFilterSection(
      title: 'Published Start Date',
      startDate: filter.publishedStartDateLower,
      endDate: filter.publishedStartDateUpper,
      onDateRangeChanged: (dates) {
        filter.publishedStartDateLower = dates.start;
        filter.publishedStartDateUpper = dates.end;
        onFilterChanged(filter);
      },
    );
  }
}

class _PublishedEndDateFilterSection extends StatelessWidget {
  final SeriesFilter filter;
  final ValueChanged<SeriesFilter> onFilterChanged;

  const _PublishedEndDateFilterSection({
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DateRangeFilterSection(
      title: 'Published End Date',
      startDate: filter.publishedEndDateLower,
      endDate: filter.publishedEndDateUpper,
      onDateRangeChanged: (dates) {
        filter.publishedEndDateLower = dates.start;
        filter.publishedEndDateUpper = dates.end;
        onFilterChanged(filter);
      },
    );
  }
}

class _SortByFilterSection extends StatelessWidget {
  final SeriesFilter filter;
  final ValueChanged<SeriesFilter> onFilterChanged;

  const _SortByFilterSection({
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleSelectFilterSection(
      title: 'Sort By',
      options: const [
        'name_asc',
        'name_desc',
        'popularity_asc',
        'popularity_desc',
        'random',
        'relevance_asc',
        'relevance_desc',
        'score_asc',
        'score_desc',
        'chapters_asc',
        'chapters_desc',
        'volumes_asc',
        'volumes_desc',
        'published_year_asc',
        'published_year_desc',
        'published_start_date_asc',
        'published_start_date_desc',
        'published_end_date_asc',
        'published_end_date_desc',
        'latest'
      ],
      selectedOption: filter.sortBy,
      onSelectionChanged: (value) {
        filter.sortBy = value;
        onFilterChanged(filter);
      },
    );
  }
}

