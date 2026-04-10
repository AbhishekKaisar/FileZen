class ExplorerItem {
  const ExplorerItem({
    this.id,
    required this.name,
    required this.path,
    required this.isFolder,
    this.isDeleted = false,
    required this.sizeLabel,
    required this.updatedLabel,
    required this.blockName,
    required this.dayOfWeek,
    this.storageBucket,
    this.storageObjectPath,
  });

  /// Row id when backed by `files.id` (Supabase); mock uses stable strings.
  final String? id;
  final String name;
  final String path;
  final bool isFolder;
  final bool isDeleted;
  final String sizeLabel;
  final String updatedLabel;
  final String blockName;
  final String dayOfWeek;
  final String? storageBucket;
  final String? storageObjectPath;

  ExplorerItem copyWith({
    String? id,
    String? name,
    String? path,
    bool? isFolder,
    bool? isDeleted,
    String? sizeLabel,
    String? updatedLabel,
    String? blockName,
    String? dayOfWeek,
    String? storageBucket,
    String? storageObjectPath,
  }) {
    return ExplorerItem(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      isFolder: isFolder ?? this.isFolder,
      isDeleted: isDeleted ?? this.isDeleted,
      sizeLabel: sizeLabel ?? this.sizeLabel,
      updatedLabel: updatedLabel ?? this.updatedLabel,
      blockName: blockName ?? this.blockName,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      storageBucket: storageBucket ?? this.storageBucket,
      storageObjectPath: storageObjectPath ?? this.storageObjectPath,
    );
  }
}
