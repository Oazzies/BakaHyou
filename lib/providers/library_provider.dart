// Riverpod providers for library state management
// These are optional foundation code for future state management migration
// Note: Requires flutter_riverpod integration with ConsumerWidget screens
//
// To enable these providers:
// 1. Convert screens to ConsumerWidget/ConsumerStatefulWidget
// 2. Add ProviderScope wrapper in main()
// 3. Import and use providers in build methods with ref.watch()
// 4. Use Riverpod's StateNotifier pattern (currently commented below)

/*
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bakahyou/features/library/models/library_entry.dart';
import 'package:bakahyou/features/library/services/library_service.dart';
import 'package:bakahyou/features/profile/services/profile_auth_service.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/utils/exceptions/app_exceptions.dart';

// Service Providers
final libraryServiceProvider = Provider<LibraryService>(
  (ref) => getIt<LibraryService>(),
);

final profileAuthServiceProvider = Provider<ProfileAuthService>(
  (ref) => getIt<ProfileAuthService>(),
);

// Check if user is logged in
final isLoggedInProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(profileAuthServiceProvider);
  return authService.hasSession();
});

// Watch library entries stream
final libraryEntriesProvider =
    StreamProvider<List<LibraryEntry>>((ref) {
  final libraryService = ref.watch(libraryServiceProvider);
  return libraryService.watchEntriesFromDb();
});

// Watch a single library entry
final libraryEntryProvider =
    StreamProvider.family<LibraryEntry?, String>((ref, seriesId) {
  final libraryService = ref.watch(libraryServiceProvider);
  return libraryService.watchEntryFromDb(seriesId);
});

// Search query state
class SearchQueryNotifier extends StateNotifier<String> {
  SearchQueryNotifier() : super('');

  void updateQuery(String query) {
    state = query;
  }

  void clearQuery() {
    state = '';
  }
}

final searchQueryProvider = StateNotifierProvider<SearchQueryNotifier, String>(
  (ref) => SearchQueryNotifier(),
);

// Filter library entries by search query
final filteredLibraryEntriesProvider =
    Provider<AsyncValue<List<LibraryEntry>>>((ref) {
  final entriesAsync = ref.watch(libraryEntriesProvider);
  final query = ref.watch(searchQueryProvider);

  return entriesAsync.when(
    data: (entries) {
      if (query.isEmpty) {
        return AsyncValue.data(entries);
      }
      final filtered = entries
          .where((entry) =>
              entry.series.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) =>
        AsyncValue.error(error, stackTrace),
  );
});

// Perform sync operation
final syncLibraryProvider = FutureProvider<void>((ref) async {
  final libraryService = ref.watch(libraryServiceProvider);
  await libraryService.syncLibrary();
});

// Update library entry state
final updateEntryStateProvider =
    FutureProvider.family<void, (String, String)>((ref, params) async {
  final libraryService = ref.watch(libraryServiceProvider);
  final (seriesId, state) = params;
  
  try {
    await libraryService.updateLibraryEntryState(seriesId, state);
    // Invalidate entries to refresh
    ref.invalidate(libraryEntriesProvider);
  } catch (e) {
    rethrow;
  }
});

// Update library entry rating
final updateEntryRatingProvider =
    FutureProvider.family<void, (String, int)>((ref, params) async {
  final libraryService = ref.watch(libraryServiceProvider);
  final (seriesId, rating) = params;
  
  try {
    await libraryService.updateLibraryEntryRating(seriesId, rating);
    ref.invalidate(libraryEntriesProvider);
  } catch (e) {
    rethrow;
  }
});

// Delete library entry
final deleteEntryProvider = FutureProvider.family<void, String>((ref, seriesId) async {
  final libraryService = ref.watch(libraryServiceProvider);
  
  try {
    await libraryService.deleteEntry(seriesId);
    ref.invalidate(libraryEntriesProvider);
  } catch (e) {
    rethrow;
  }
});

// Create library entry
final createEntryProvider = FutureProvider.family<void, (String, String)>((ref, params) async {
  final libraryService = ref.watch(libraryServiceProvider);
  final (seriesId, state) = params;
  
  try {
    await libraryService.createLibraryEntry(seriesId, state);
    ref.invalidate(libraryEntriesProvider);
  } catch (e) {
    rethrow;
  }
});
*/
