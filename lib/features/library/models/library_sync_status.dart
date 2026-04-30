class LibrarySyncStatus {
  final bool isSyncing;
  final int totalEntries;
  final int currentEntries;
  final String? error;
  final String? infoMessage;

  LibrarySyncStatus({
    this.isSyncing = false,
    this.totalEntries = 0,
    this.currentEntries = 0,
    this.error,
    this.infoMessage,
  });

  double get progress => totalEntries > 0 ? currentEntries / totalEntries : 0.0;

  LibrarySyncStatus copyWith({
    bool? isSyncing,
    int? totalEntries,
    int? currentEntries,
    String? error,
    bool clearError = false,
    String? infoMessage,
    bool clearInfo = false,
  }) {
    return LibrarySyncStatus(
      isSyncing: isSyncing ?? this.isSyncing,
      totalEntries: totalEntries ?? this.totalEntries,
      currentEntries: currentEntries ?? this.currentEntries,
      error: clearError ? null : (error ?? this.error),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
    );
  }

  @override
  String toString() => 'LibrarySyncStatus(isSyncing: $isSyncing, total: $totalEntries, current: $currentEntries, error: $error, info: $infoMessage)';
}
