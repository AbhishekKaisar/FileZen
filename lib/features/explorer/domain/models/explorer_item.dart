class ExplorerItem {
  const ExplorerItem({
    this.id,
    required this.name,
    required this.path,
    required this.isFolder,
    required this.sizeLabel,
    required this.updatedLabel,
    required this.blockName,
    required this.dayOfWeek,
  });

  /// Row id when backed by `files.id` (Supabase); mock uses stable strings.
  final String? id;
  final String name;
  final String path;
  final bool isFolder;
  final String sizeLabel;
  final String updatedLabel;
  final String blockName;
  final String dayOfWeek;

  ExplorerItem copyWith({
    String? id,
    String? name,
    String? path,
    bool? isFolder,
    String? sizeLabel,
    String? updatedLabel,
    String? blockName,
    String? dayOfWeek,
  }) {
    return ExplorerItem(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      isFolder: isFolder ?? this.isFolder,
      sizeLabel: sizeLabel ?? this.sizeLabel,
      updatedLabel: updatedLabel ?? this.updatedLabel,
      blockName: blockName ?? this.blockName,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    );
  }
}
