import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/browse/widgets/search/autocomplete_ranking.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';

AutocompleteSeriesResult _result(String title, {List<String>? allTitles}) =>
    AutocompleteSeriesResult(
      id: title.hashCode,
      title: title,
      thumbnailUrl: '',
      allTitles: allTitles ?? [title],
    );

void main() {
  group('AutocompleteRanking.sort', () {
    test('puts an exact title match first', () {
      final results = [
        _result('Attack on Titan: Junior High'),
        _result('Attack'),
        _result('Attack on Titan'),
      ];
      AutocompleteRanking.sort(results, 'attack');
      expect(results.first.title, 'Attack');
    });

    test('prefers prefix matches over mere containment', () {
      final results = [
        _result('The Great Titan'),
        _result('Titan Rising'),
      ];
      AutocompleteRanking.sort(results, 'titan');
      expect(results.first.title, 'Titan Rising');
    });

    test('falls back to the shorter title', () {
      final results = [
        _result('Berserk of Gluttony'),
        _result('Berserk'),
      ];
      AutocompleteRanking.sort(results, 'berserk');
      expect(results.first.title, 'Berserk');
    });

    test('preferPrefixMatches:false stops promoting prefix matches', () {
      List<AutocompleteSeriesResult> results() => [
            _result('The Titan'),
            _result('Titan Rising Extended'),
          ];

      final promoted = results();
      AutocompleteRanking.sort(promoted, 'titan');
      expect(promoted.first.title, 'Titan Rising Extended');

      final plain = results();
      AutocompleteRanking.sort(plain, 'titan', preferPrefixMatches: false);
      // Without the prefix tier only length decides, so the shorter wins.
      expect(plain.first.title, 'The Titan');
    });
  });

  group('AutocompleteRanking.ghostSuffix', () {
    test('completes the remainder of a matching title', () {
      final results = [_result('Attack on Titan')];
      expect(AutocompleteRanking.ghostSuffix(results, 'Attack'), ' on Titan');
    });

    test('matches case-insensitively', () {
      final results = [_result('Attack on Titan')];
      expect(AutocompleteRanking.ghostSuffix(results, 'attack'), ' on Titan');
    });

    test('completes against an alternate title', () {
      final results = [
        _result('Attack on Titan', allTitles: ['Attack on Titan', 'Shingeki']),
      ];
      expect(AutocompleteRanking.ghostSuffix(results, 'Shing'), 'eki');
    });

    test('is empty when the query already spans the whole title', () {
      final results = [_result('Berserk')];
      expect(AutocompleteRanking.ghostSuffix(results, 'Berserk'), '');
    });

    test('is empty for an empty query', () {
      final results = [_result('Berserk')];
      expect(AutocompleteRanking.ghostSuffix(results, ''), '');
    });

    test('is empty when nothing starts with the query', () {
      final results = [_result('Berserk')];
      expect(AutocompleteRanking.ghostSuffix(results, 'Attack'), '');
    });
  });

  group('AutocompleteRanking.matchForGhost', () {
    test('finds the result that produced the suffix', () {
      final results = [_result('Berserk'), _result('Attack on Titan')];
      final match =
          AutocompleteRanking.matchForGhost(results, 'Attack', ' on Titan');
      expect(match, isNotNull);
      expect(match!.result.title, 'Attack on Titan');
      expect(match.title, 'Attack on Titan');
    });

    test('returns null for a stale suffix', () {
      final results = [_result('Attack on Titan')];
      expect(
        AutocompleteRanking.matchForGhost(results, 'Attack', ' on Nothing'),
        isNull,
      );
    });

    test('returns null when there is no ghost', () {
      final results = [_result('Attack on Titan')];
      expect(AutocompleteRanking.matchForGhost(results, 'Attack', ''), isNull);
    });
  });
}
