import 'dart:convert';
import 'package:bakahyou/database/database.dart' as db;
import 'package:bakahyou/features/library/models/library_entry.dart' as api;
import 'package:bakahyou/features/series/models/series.dart' as api;

class DbToApiMapper {
  static api.LibraryEntry libraryEntryFromDb(db.LibraryEntryWithSeries dbEntry) {
    return api.LibraryEntry(
      id: dbEntry.libraryEntry.id,
      state: dbEntry.libraryEntry.state,
      note: dbEntry.libraryEntry.note,
      progressChapter: dbEntry.libraryEntry.progressChapter,
      progressVolume: dbEntry.libraryEntry.progressVolume,
      numberOfRereads: dbEntry.libraryEntry.numberOfRereads,
      series: _seriesFromDb(dbEntry.series),
    );
  }

  static api.Series _seriesFromDb(db.SeriesTableData dbSeries) {
    // Helper function to safely decode JSON arrays
    List<String> _decodeStringArray(String? jsonStr) {
      if (jsonStr == null || jsonStr.isEmpty) return [];
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          return decoded.cast<String>();
        }
      } catch (_) {}
      return [];
    }

    // Helper function to safely decode JSON objects
    Map<String, dynamic>? _decodeJsonObject(String? jsonStr) {
      if (jsonStr == null || jsonStr.isEmpty) return null;
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map) {
          return decoded.cast<String, dynamic>();
        }
      } catch (_) {}
      return null;
    }

    // Helper function to safely decode generic lists
    List<dynamic> _decodeList(String? jsonStr) {
      if (jsonStr == null || jsonStr.isEmpty) return [];
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          return decoded;
        }
      } catch (_) {}
      return [];
    }

    return api.Series(
      id: dbSeries.id,
      state: dbSeries.state ?? '',
      mergedWith: dbSeries.mergedWith,
      title: dbSeries.title,
      nativeTitle: dbSeries.nativeTitle ?? '',
      romanizedTitle: dbSeries.romanizedTitle ?? '',
      secondaryTitles: _decodeStringArray(dbSeries.secondaryTitles),
      coverUrl: dbSeries.coverUrl,
      authors: _decodeStringArray(dbSeries.authors),
      artists: _decodeStringArray(dbSeries.artists),
      description: dbSeries.description,
      year: dbSeries.year ?? '',
      published: _decodeJsonObject(dbSeries.published),
      status: dbSeries.status ?? '',
      isLicensed: dbSeries.isLicensed ?? '',
      hasAnime: dbSeries.hasAnime ?? '',
      anime: _decodeJsonObject(dbSeries.anime),
      contentRating: dbSeries.contentRating ?? '',
      type: dbSeries.type ?? '',
      rating: dbSeries.rating ?? '',
      finalVolume: dbSeries.finalVolume ?? '',
      totalChapters: dbSeries.totalChapters ?? '',
      links: _decodeList(dbSeries.links),
      publishers: _decodeStringArray(dbSeries.publishers),
      genres: _decodeStringArray(dbSeries.genres),
      tags: _decodeStringArray(dbSeries.tags),
      lastUpdated: dbSeries.lastUpdated ?? '',
      relationships: _decodeJsonObject(dbSeries.relationships),
      source: _decodeJsonObject(dbSeries.source),
    );
  }
}