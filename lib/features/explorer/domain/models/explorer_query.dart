enum ExplorerKindFilter {
  all,
  folders,
  files,
}

enum ExplorerSortBy {
  nameAsc,
  nameDesc,
  updatedDesc,
}

class ExplorerQuery {
  const ExplorerQuery({
    this.search = '',
    this.kind = ExplorerKindFilter.all,
    this.sortBy = ExplorerSortBy.nameAsc,
    this.organizerBlockLabel,
    this.organizerDayOfWeek,
  });

  final String search;
  final ExplorerKindFilter kind;
  final ExplorerSortBy sortBy;

  /// When set, only files in this organizer block (`app.files.organizer_block_label`).
  final String? organizerBlockLabel;

  /// When set, only files on this weekday (`app.files.organizer_day_of_week`), e.g. `Friday`.
  final String? organizerDayOfWeek;
}
