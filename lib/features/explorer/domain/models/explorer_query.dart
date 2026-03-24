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
  });

  final String search;
  final ExplorerKindFilter kind;
  final ExplorerSortBy sortBy;
}
