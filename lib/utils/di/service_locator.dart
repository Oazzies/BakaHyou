import 'package:get_it/get_it.dart';
import 'package:bakahyou/database/database.dart';
import 'package:bakahyou/features/series/services/series_search_service.dart';
import 'package:bakahyou/features/series/services/metadata_service.dart';
import 'package:bakahyou/features/library/services/library_service.dart';
import 'package:bakahyou/features/profile/services/profile_auth_service.dart';
import 'package:bakahyou/utils/services/logging_service.dart';

final getIt = GetIt.instance;

/// Configures all service dependencies using GetIt
void setupServiceLocator() {
  // Logging Service (singleton)
  getIt.registerSingleton<LoggingService>(LoggingService());

  // Database (singleton)
  getIt.registerSingleton<AppDatabase>(AppDatabase());

  // Authentication Service (singleton)
  getIt.registerSingleton<ProfileAuthService>(ProfileAuthService());

  // Metadata Service (singleton)
  getIt.registerSingleton<MetadataService>(MetadataService());

  // Series Services (lazy singletons - created on first use)
  getIt.registerLazySingleton<SeriesSearchService>(() => SeriesSearchService());

  // Library Service (singleton to maintain state)
  getIt.registerSingleton<LibraryService>(
    LibraryService(auth: getIt<ProfileAuthService>()),
  );
}

/// Resets all service instances (useful for testing)
void resetServiceLocator() {
  getIt.reset();
}
