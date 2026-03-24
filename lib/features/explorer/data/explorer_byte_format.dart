class ExplorerByteFormat {
  ExplorerByteFormat._();

  static String humanReadable(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = bytes.toDouble();
    var index = 0;
    while (size >= 1024 && index < units.length - 1) {
      size /= 1024;
      index++;
    }
    final display = size >= 10 || index == 0 ? size.toStringAsFixed(0) : size.toStringAsFixed(1);
    return '$display ${units[index]}';
  }
}
