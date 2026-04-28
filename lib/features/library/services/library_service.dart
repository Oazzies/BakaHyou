import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bakahyou/database/database.dart' as db;
import 'package:bakahyou/features/library/models/library_entry.dart' as api;
import 'package:bakahyou/features/profile/services/profile_auth_service.dart';
import 'package:bakahyou/features/library/services/library_constants.dart';
import 'package:bakahyou/features/library/services/mappers/db_to_api_mapper.dart';
import 'package:bakahyou/features/library/models/library_sync_status.dart';
import 'package:bakahyou/utils/services/logging_service.dart';
import 'package:bakahyou/utils/exceptions/app_exceptions.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:flutter/foundation.dart';

class LibraryService {
  final _logger = LoggingService.logger;
  final ProfileAuthService _auth;
  final db.AppDatabase _db;
  bool _hasPerformedInitialSync = false;
  
  static const String _syncStateKey = '${AppConstants.prefixStorageKey}library_sync_last_state';
  static const String _syncTypeKey = '${AppConstants.prefixStorageKey}library_sync_last_type';
  static const String _syncPageKey = '${AppConstants.prefixStorageKey}library_sync_last_page';
  static const String _syncTotalFetchedKey = '${AppConstants.prefixStorageKey}library_sync_total_fetched';

  final ValueNotifier<LibrarySyncStatus> syncStatus = 
      ValueNotifier(LibrarySyncStatus());

  LibraryService({required ProfileAuthService auth})
    : _auth = auth,
      _db = db.AppDatabase();

  /// Watches a single library entry by series ID.
  Stream<api.LibraryEntry?> watchEntryFromDb(String seriesId) {
    return _db.libraryEntriesDao
        .watchEntryWithSeries(seriesId)
        .map(
          (dbEntry) => dbEntry != null
              ? DbToApiMapper.libraryEntryFromDb(dbEntry)
              : null,
        )
        .handleError((error, stackTrace) {
          _logger.severe('Error watching entry from db: $error\n$stackTrace');
          return null;
        }, test: (error) => true);
  }

  Stream<List<api.LibraryEntry>> watchEntriesFromDb() {
    return _db.libraryEntriesDao
        .watchAllEntriesWithSeries()
        .map(
          (dbEntries) =>
              dbEntries.map(DbToApiMapper.libraryEntryFromDb).toList(),
        )
        .handleError((error, stackTrace) {
          _logger.severe('Error watching entries from db: $error\n$stackTrace');
          return [];
        }, test: (error) => true);
  }

  Future<void>? _initialSyncTask;

  /// Performs initial sync only once on first app load.
  Future<void> performInitialSyncIfNeeded() async {
    if (_hasPerformedInitialSync) return;
    
    // If a sync is already in progress, wait for it
    if (_initialSyncTask != null) return _initialSyncTask;

    _initialSyncTask = _doInitialSync();
    return _initialSyncTask;
  }

  Future<void> _doInitialSync() async {
    try {
      await syncLibrary();
      _hasPerformedInitialSync = true;
    } on NetworkException catch (e) {
      _logger.warning('Initial sync failed due to network error: $e. Using local data.');
      _initialSyncTask = null; 
      rethrow;
    } catch (e, st) {
      _logger.severe('Failed to perform initial sync: $e\n$st');
      _initialSyncTask = null;
      rethrow;
    }
  }

  /// Performs a full sync with the remote API.
  Future<void> syncLibrary({String? state}) async {
    if (syncStatus.value.isSyncing) return;
    
    syncStatus.value = LibrarySyncStatus(isSyncing: true);

    const maxRetries = 5; // Increased retries for better resilience
    var retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        final token = await _auth.getValidAccessToken();
        final prefs = await SharedPreferences.getInstance();
        
        // Load saved progress if resuming
        var totalFetched = prefs.getInt(_syncTotalFetchedKey) ?? 0;
        var requestCount = 0;
        
        final savedState = prefs.getString(_syncStateKey);
        final savedType = prefs.getString(_syncTypeKey);
        final savedPage = prefs.getInt(_syncPageKey);

        if (state != null) {
          final result = await _syncState(token, state, requestCount: requestCount);
          totalFetched = result.$1;
          requestCount = result.$2;
        } else {
          final states = AppConstants.libraryStates.toList();
          final types = [null, 'manga', 'manhwa', 'manhua', 'novel', 'oel'];
          
          var startIndex = 0;
          if (savedState != null) {
            startIndex = states.indexOf(savedState);
            if (startIndex == -1) startIndex = 0;
            _logger.info('Resuming sync from state: $savedState');
          }

          for (var i = startIndex; i < states.length; i++) {
            final s = states[i];
            
            var typeStartIndex = 0;
            if (s == savedState && savedType != null) {
              typeStartIndex = types.indexOf(savedType);
              if (typeStartIndex == -1) typeStartIndex = 0;
              _logger.info('Resuming sync for state $s from type: $savedType');
            }

            for (var j = typeStartIndex; j < types.length; j++) {
              final type = types[j];
              
              // Only do deep sync if we already hit the limit or we are resuming a deep sync
              if (type != null && (s != savedState || savedType == null)) {
                 // Skip types unless we are in fallback mode
                 // Wait, the logic in _syncState handles the fallback.
                 // So here we only call _syncState once with type=null
                 if (type != null) continue; 
              }

              final result = await _syncState(
                token, 
                s, 
                type: type,
                requestCount: requestCount,
                initialFetched: totalFetched,
                resumePage: (s == savedState && type == savedType) ? savedPage : null,
              );
              totalFetched = result.$1;
              requestCount = result.$2;
            }
          }
        }

        _logger.info('Library sync completed. Total entries fetched: $totalFetched');
        
        // Clear saved progress on success
        await _clearSyncProgress();
        
        syncStatus.value = syncStatus.value.copyWith(isSyncing: false);
        return; // Success
      } on AuthException catch (e) {
        syncStatus.value = syncStatus.value.copyWith(isSyncing: false, error: e.message);
        rethrow;
      } on NetworkException catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          _logger.severe('Failed to sync library after $maxRetries attempts: $e');
          syncStatus.value = syncStatus.value.copyWith(isSyncing: false, error: 'Connection failed. Will resume later.');
          rethrow;
        }
        
        final delaySeconds = (retryCount * 15).clamp(5, 60);
        syncStatus.value = syncStatus.value.copyWith(
          error: 'Connection lost. Retrying in ${delaySeconds}s... ($retryCount/$maxRetries)',
        );
        
        _logger.warning('Network error during sync. Retrying in ${delaySeconds}s... ($retryCount/$maxRetries)');
        await Future.delayed(Duration(seconds: delaySeconds));
      } catch (e, st) {
        _logger.severe('Failed to sync library: $e\n$st');
        syncStatus.value = syncStatus.value.copyWith(isSyncing: false, error: 'Sync failed');
        throw AppError(
          message: 'Failed to sync library',
          originalError: e,
          stackTrace: st,
        );
      }
    }
  }

  Future<void> _clearSyncProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_syncStateKey);
    await prefs.remove(_syncTypeKey);
    await prefs.remove(_syncPageKey);
    await prefs.remove(_syncTotalFetchedKey);
  }

  /// Helper to sync entries for a specific state and type.
  Future<(int, int)> _syncState(
    String token, 
    String state, {
    String? type,
    required int requestCount,
    int initialFetched = 0,
    int? resumePage,
  }) async {
    var page = resumePage ?? 1;
    var totalFetched = initialFetched;
    var currentRequestCount = requestCount;
    const maxPages = 100; // API limit

    final prefs = await SharedPreferences.getInstance();

    while (page <= maxPages) {
      // Check for batch pause
      if (currentRequestCount > 0 && currentRequestCount % AppConstants.requestsPerBatch == 0) {
        _logger.info('Batch limit reached ($currentRequestCount requests). Pausing for ${AppConstants.batchPauseSeconds}s...');
        await Future.delayed(Duration(seconds: AppConstants.batchPauseSeconds));
      }

      final result = await _fetchPage(token, page, state: state, type: type);
      currentRequestCount++;

      final entries = result.entries;
      _logger.info('Fetched ${entries.length} entries on page $page for state $state (type: ${type ?? 'all'})');
      
      await _saveEntries(entries);
      totalFetched += entries.length;

      // Persist progress
      await prefs.setString(_syncStateKey, state);
      if (type != null) {
        await prefs.setString(_syncTypeKey, type);
      } else {
        await prefs.remove(_syncTypeKey);
      }
      await prefs.setInt(_syncPageKey, page);
      await prefs.setInt(_syncTotalFetchedKey, totalFetched);

      // Update progress
      syncStatus.value = syncStatus.value.copyWith(
        currentEntries: totalFetched,
        error: null, // Clear error on successful page fetch
      );

      if (entries.length < LibraryConstants.pageLimit) {
        break;
      }
      page++;
    }
    
    // If we hit the 100-page limit and we were fetching 'all' types, 
    // we need to slice by type to get the remaining entries.
    if (page > maxPages && type == null) {
      _logger.warning('Reached max page limit (100) for state $state. Slicing by type to fetch remaining entries...');
      
      final types = ['manga', 'manhwa', 'manhua', 'novel', 'oel'];
      for (final t in types) {
        _logger.info('Deep syncing state: $state, type: $t');
        final result = await _syncState(
          token, 
          state, 
          type: t, 
          requestCount: currentRequestCount, 
          initialFetched: totalFetched,
        );
        totalFetched = result.$1;
        currentRequestCount = result.$2;
      }
    } else if (page > maxPages) {
      _logger.warning('Reached max page limit (100) for state $state, type $type. Some entries might still be missing.');
    }
    
    return (totalFetched, currentRequestCount);
  }

  Future<_FetchPageResult> _fetchPage(String token, int page, {String? state, String? type}) async {
    var url = '${LibraryConstants.baseUrl}?page=$page&limit=${LibraryConstants.pageLimit}';
    if (state != null) {
      url += '&state=$state';
    }
    if (type != null) {
      url += '&type=$type';
    }
    final uri = Uri.parse(url);

    try {
      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'User-Agent': LibraryConstants.userAgent,
            },
          )
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Library fetch timed out'),
          );

      _logger.fine('Library fetch page $page completed');

      if (response.statusCode == 429) {
        _logger.warning(
          'Rate limited fetching library page $page. Retrying after delay...',
        );
        await Future.delayed(
          Duration(seconds: AppConstants.rateLimitRetryDelaySeconds),
        );
        return _fetchPage(token, page, state: state);
      }

      if (response.statusCode == 401) {
        throw AuthException(
          message: 'Authentication failed. Please log in again.',
          code: 'AUTH_FAILED',
        );
      }

      if (response.statusCode != 200) {
        _logger.severe(
          'Failed to fetch library page. Status: ${response.statusCode}, Body: ${response.body}',
        );
        throw ApiException(
          message: 'Failed to fetch library page',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'FETCH_PAGE_FAILED',
        );
      }

      try {
        final body = jsonDecode(response.body);
        final data = (body['data'] as List<dynamic>? ?? const []);
        
        // Extract total entries from metadata if available
        int total = 0;
        if (body['meta'] != null && body['meta']['total'] != null) {
          total = (body['meta']['total'] as num).toInt();
        } else if (body['total'] != null) {
          total = (body['total'] as num).toInt();
        }

        final entries = data
            .map(
              (item) => api.LibraryEntry.fromJson(item as Map<String, dynamic>),
            )
            .toList();
            
        return _FetchPageResult(entries: entries, totalEntries: total);
      } catch (e, st) {
        _logger.severe('Failed to parse library page: $e\n$st');
        throw ParseException(
          message: 'Failed to parse library page',
          originalError: e,
          stackTrace: st,
        );
      }
    } on http.ClientException catch (e, st) {
      _logger.severe('HTTP client error fetching library page: $e\n$st');
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on SocketException catch (e, st) {
      _logger.severe('Network error fetching library page: $e\n$st');
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on TimeoutException catch (e, st) {
      _logger.severe('Request timeout fetching library page: $e\n$st');
      throw NetworkException(
        message: 'Request timed out. Please try again.',
        code: 'TIMEOUT',
        originalError: e,
        stackTrace: st,
      );
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on ParseException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      _logger.severe('Unexpected error fetching library page: $e\n$st');
      throw AppError(
        message: 'Unexpected error fetching library page',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _saveEntries(List<api.LibraryEntry> entries) async {
    if (entries.isEmpty) return;
    try {
      await _db.seriesDao.upsertSeries(entries.map((e) => e.series).toList());
      await _db.libraryEntriesDao.upsertLibraryEntries(entries);
    } catch (e, st) {
      _logger.severe('Failed to save entries to database: $e\n$st');
      throw DatabaseException(
        message: 'Failed to save entries',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<void> updateLibraryEntryState(String seriesId, String state) async {
    final token = await _auth.getValidAccessToken();

    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    try {
      final response = await http
          .put(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'User-Agent': LibraryConstants.userAgent,
            },
            body: jsonEncode({'state': state}),
          )
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () =>
                throw TimeoutException('Update state request timed out'),
          );

      _logger.fine('Library entry state update completed');

      if (response.statusCode == 401) {
        throw AuthException(
          message: 'Authentication failed. Please log in again.',
          code: 'AUTH_FAILED',
        );
      }

      if (response.statusCode != 200) {
        _logger.severe(
          'Failed to update entry state. Status: ${response.statusCode}, Body: ${response.body}',
        );
        throw ApiException(
          message: 'Failed to update entry state',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'UPDATE_STATE_FAILED',
        );
      }

      // Update the local database entry
      await _db.libraryEntriesDao.updateEntryState(seriesId, state);
    } on http.ClientException catch (e, st) {
      _logger.severe('HTTP client error updating entry state: $e\n$st');
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on SocketException catch (e, st) {
      _logger.severe('Network error updating entry state: $e\n$st');
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on TimeoutException catch (e, st) {
      _logger.severe('Request timeout updating entry state: $e\n$st');
      throw NetworkException(
        message: 'Request timed out. Please try again.',
        code: 'TIMEOUT',
        originalError: e,
        stackTrace: st,
      );
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      _logger.severe('Unexpected error updating entry state: $e\n$st');
      throw AppError(
        message: 'Failed to update entry state',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<void> updateLibraryEntryRating(String seriesId, int rating) async {
    final token = await _auth.getValidAccessToken();

    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    try {
      final response = await http
          .put(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'User-Agent': LibraryConstants.userAgent,
            },
            body: jsonEncode({'rating': rating}),
          )
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () =>
                throw TimeoutException('Update rating request timed out'),
          );
      
      _logger.fine('Library entry rating update completed');

      if (response.statusCode == 401) {
        throw AuthException(
          message: 'Authentication failed. Please log in again.',
          code: 'AUTH_FAILED',
        );
      }

      if (response.statusCode != 200) {
        _logger.severe(
          'Failed to update entry rating. Status: ${response.statusCode}, Body: ${response.body}',
        );
        throw ApiException(
          message: 'Failed to update entry rating',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'UPDATE_RATING_FAILED',
        );
      }

      await _db.libraryEntriesDao.updateEntryRating(seriesId, rating);
    } on http.ClientException catch (e, st) {
      _logger.severe('HTTP client error updating entry rating: $e\n$st');
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on SocketException catch (e, st) {
      _logger.severe('Network error updating entry rating: $e\n$st');
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on TimeoutException catch (e, st) {
      _logger.severe('Request timeout updating entry rating: $e\n$st');
      throw NetworkException(
        message: 'Request timed out. Please try again.',
        code: 'TIMEOUT',
        originalError: e,
        stackTrace: st,
      );
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      _logger.severe('Unexpected error updating entry rating: $e\n$st');
      throw AppError(
        message: 'Failed to update entry rating',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<void> createLibraryEntry(String seriesId, String state) async {
    final token = await _auth.getValidAccessToken();

    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'User-Agent': LibraryConstants.userAgent,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'state': state}),
          )
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () =>
                throw TimeoutException('Create entry request timed out'),
          );
      
      _logger.fine('Library entry creation completed');

      if (response.statusCode == 401) {
        throw AuthException(
          message: 'Authentication failed. Please log in again.',
          code: 'AUTH_FAILED',
        );
      }

      if (response.statusCode == 201) {
        await syncLibrary();
      } else {
        _logger.severe(
          'Failed to create library entry. Status: ${response.statusCode}, Body: ${response.body}',
        );
        throw ApiException(
          message: 'Failed to create library entry',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'CREATE_ENTRY_FAILED',
        );
      }
    } on http.ClientException catch (e, st) {
      _logger.severe('HTTP client error creating entry: $e\n$st');
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on SocketException catch (e, st) {
      _logger.severe('Network error creating entry: $e\n$st');
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on TimeoutException catch (e, st) {
      _logger.severe('Request timeout creating entry: $e\n$st');
      throw NetworkException(
        message: 'Request timed out. Please try again.',
        code: 'TIMEOUT',
        originalError: e,
        stackTrace: st,
      );
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      _logger.severe('Unexpected error creating entry: $e\n$st');
      throw AppError(
        message: 'Failed to create library entry',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<void> deleteEntry(String seriesId) async {
    final token = await _auth.getValidAccessToken();

    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    try {
      final response = await http
          .delete(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'User-Agent': LibraryConstants.userAgent,
            },
          )
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () =>
                throw TimeoutException('Delete entry request timed out'),
          );

      _logger.fine('Library entry deletion completed');

      if (response.statusCode == 401) {
        throw AuthException(
          message: 'Authentication failed. Please log in again.',
          code: 'AUTH_FAILED',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 404) {
        // Also delete from local DB
        await _db.libraryEntriesDao.deleteEntry(seriesId);
      } else {
        _logger.severe(
          'Failed to delete entry. Status: ${response.statusCode}, Body: ${response.body}',
        );
        throw ApiException(
          message: 'Failed to delete library entry',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'DELETE_ENTRY_FAILED',
        );
      }
    } on http.ClientException catch (e, st) {
      _logger.severe('HTTP client error deleting entry: $e\n$st');
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on SocketException catch (e, st) {
      _logger.severe('Network error deleting entry: $e\n$st');
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on TimeoutException catch (e, st) {
      _logger.severe('Request timeout deleting entry: $e\n$st');
      throw NetworkException(
        message: 'Request timed out. Please try again.',
        code: 'TIMEOUT',
        originalError: e,
        stackTrace: st,
      );
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      _logger.severe('Unexpected error deleting entry: $e\n$st');
      throw AppError(
        message: 'Failed to delete library entry',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<void> clearLibrary() async {
    try {
      await _db.libraryEntriesDao.deleteAllEntries();
      _hasPerformedInitialSync = false;
      _initialSyncTask = null;
    } catch (e, st) {
      _logger.severe('Failed to clear library: $e\n$st');
    }
  }
}

class _FetchPageResult {
  final List<api.LibraryEntry> entries;
  final int totalEntries;

  _FetchPageResult({required this.entries, required this.totalEntries});
}
