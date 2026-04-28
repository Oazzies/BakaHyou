class LibrarySyncStatus {
  final bool isSyncing;
  final int totalEntries;
  final int currentEntries;
  final String? error;

  LibrarySyncStatus({
    this.isSyncing = false,
    this.totalEntries = 0,
    this.currentEntries = 0,
    this.error,
  });

  double get progress => totalEntries > 0 ? currentEntries / totalEntries : 0.0;

  LibrarySyncStatus copyWith({
    bool? isSyncing,
    int? totalEntries,
    int? currentEntries,
    String? error,
  }) {
    return LibrarySyncStatus(
      isSyncing: isSyncing ?? this.isSyncing,
      totalEntries: totalEntries ?? this.totalEntries,
      currentEntries: currentEntries ?? this.currentEntries,
      error: error ?? this.error,
    );
  }

  @override
  String toString() => 'LibrarySyncStatus(isSyncing: $isSyncing, total: $totalEntries, current: $currentEntries, error: $error)';
}
