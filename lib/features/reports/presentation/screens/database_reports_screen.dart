import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/env.dart';
import '../../../explorer/data/explorer_byte_format.dart';

class DatabaseReportsScreen extends StatefulWidget {
  const DatabaseReportsScreen({super.key});

  @override
  State<DatabaseReportsScreen> createState() => _DatabaseReportsScreenState();
}

enum _ReportRange { week, month, threeMonths }

class _ReportData {
  final int totalBytes;
  final int totalFiles;
  final Map<String, _CategoryStats> byCategory;
  final List<_FileRow> largestFiles;
  final String rangeName;

  const _ReportData({
    required this.totalBytes,
    required this.totalFiles,
    required this.byCategory,
    required this.largestFiles,
    required this.rangeName,
  });
}

class _CategoryStats {
  int fileCount = 0;
  int totalBytes = 0;
}

class _FileRow {
  final String name;
  final int sizeBytes;
  final String extension;

  const _FileRow({required this.name, required this.sizeBytes, required this.extension});
}

class _DatabaseReportsScreenState extends State<DatabaseReportsScreen> {
  _ReportRange _selectedRange = _ReportRange.week;
  _ReportData? _reportData;
  bool _loading = false;
  bool _generating = false;
  String? _error;

  String get _rangeName {
    switch (_selectedRange) {
      case _ReportRange.week: return 'Last 7 Days';
      case _ReportRange.month: return 'Last 30 Days';
      case _ReportRange.threeMonths: return 'Last 3 Months';
    }
  }

  DateTime get _rangeStart {
    final now = DateTime.now().toUtc();
    switch (_selectedRange) {
      case _ReportRange.week: return now.subtract(const Duration(days: 7));
      case _ReportRange.month: return now.subtract(const Duration(days: 30));
      case _ReportRange.threeMonths: return now.subtract(const Duration(days: 90));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final useSupabase = Env.useSupabase;
    final workspaceId = Env.workspaceId;
    final dbSchema = Env.dbSchema;

    if (!useSupabase || workspaceId.isEmpty) {
      setState(() => _error = 'Reports require Supabase mode.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final client = Supabase.instance.client;
      final rows = await client
          .schema(dbSchema)
          .from('files')
          .select('name, size_bytes, extension, updated_at')
          .eq('workspace_id', workspaceId)
          .eq('is_deleted', false)
          .gte('updated_at', _rangeStart.toIso8601String())
          .order('size_bytes', ascending: false);

      int totalBytes = 0;
      int totalFiles = rows.length;
      final Map<String, _CategoryStats> byCategory = {};
      final List<_FileRow> largest = [];

      for (final row in rows) {
        final size = ((row['size_bytes'] as num?) ?? 0).toInt();
        final name = row['name']?.toString() ?? 'Unknown';
        final ext = (row['extension']?.toString() ?? '').toLowerCase();
        final category = _categorize(ext);

        totalBytes += size;
        byCategory.putIfAbsent(category, () => _CategoryStats());
        byCategory[category]!.fileCount++;
        byCategory[category]!.totalBytes += size;

        if (largest.length < 10) {
          largest.add(_FileRow(name: name, sizeBytes: size, extension: ext));
        }
      }

      if (!mounted) return;
      setState(() {
        _reportData = _ReportData(
          totalBytes: totalBytes,
          totalFiles: totalFiles,
          byCategory: byCategory,
          largestFiles: largest,
          rangeName: _rangeName,
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  static String _categorize(String ext) {
    if (const {'png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'heic', 'heif', 'svg'}.contains(ext)) return 'Images';
    if (const {'txt', 'md', 'log', 'csv', 'ini'}.contains(ext)) return 'Text';
    if (const {'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'}.contains(ext)) return 'Documents';
    if (const {'mp4', 'mov', 'avi', 'mkv', 'webm'}.contains(ext)) return 'Videos';
    if (const {'mp3', 'wav', 'flac', 'aac', 'ogg'}.contains(ext)) return 'Audio';
    if (const {'zip', 'rar', '7z', 'tar', 'gz'}.contains(ext)) return 'Archives';
    if (const {'json', 'xml', 'yaml', 'html', 'css', 'js', 'ts', 'dart', 'py'}.contains(ext)) return 'Code';
    return 'Other';
  }

  Future<void> _generatePdf() async {
    final data = _reportData;
    if (data == null) return;
    setState(() => _generating = true);

    try {
      final pdfBytes = await _buildPdf(data);
      if (!mounted) return;
      setState(() => _generating = false);

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _PdfPreviewScreen(pdfBytes: pdfBytes, title: 'FileZen Report - ${data.rangeName}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _generating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: const Color(0xFF7F2927)),
      );
    }
  }

  Future<Uint8List> _buildPdf(_ReportData data) async {
    final pdf = pw.Document();
    final sortedCategories = data.byCategory.entries.toList()
      ..sort((a, b) => b.value.totalBytes.compareTo(a.value.totalBytes));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('FileZen Storage Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Period: ${data.rangeName}', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
          pw.Text('Generated: ${DateTime.now().toLocal().toString().substring(0, 16)}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey500)),
          pw.SizedBox(height: 24),

          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _pdfStatBox('Total Files', '${data.totalFiles}'),
                _pdfStatBox('Total Storage', ExplorerByteFormat.humanReadable(data.totalBytes)),
                _pdfStatBox('File Types', '${data.byCategory.length}'),
              ],
            ),
          ),
          pw.SizedBox(height: 32),

          // File Type Distribution
          pw.Header(level: 1, child: pw.Text('Storage by File Type')),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _pdfCell('Category', bold: true),
                  _pdfCell('Files', bold: true),
                  _pdfCell('Size', bold: true),
                  _pdfCell('Share', bold: true),
                ],
              ),
              for (final entry in sortedCategories)
                pw.TableRow(children: [
                  _pdfCell(entry.key),
                  _pdfCell('${entry.value.fileCount}'),
                  _pdfCell(ExplorerByteFormat.humanReadable(entry.value.totalBytes)),
                  _pdfCell(data.totalBytes > 0
                      ? '${(entry.value.totalBytes / data.totalBytes * 100).toStringAsFixed(1)}%'
                      : '0%'),
                ]),
            ],
          ),
          pw.SizedBox(height: 32),

          // Largest Files
          pw.Header(level: 1, child: pw.Text('Top ${data.largestFiles.length} Largest Files')),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(4),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _pdfCell('#', bold: true),
                  _pdfCell('File Name', bold: true),
                  _pdfCell('Type', bold: true),
                  _pdfCell('Size', bold: true),
                ],
              ),
              for (int i = 0; i < data.largestFiles.length; i++)
                pw.TableRow(children: [
                  _pdfCell('${i + 1}'),
                  _pdfCell(data.largestFiles[i].name),
                  _pdfCell(data.largestFiles[i].extension.toUpperCase()),
                  _pdfCell(ExplorerByteFormat.humanReadable(data.largestFiles[i].sizeBytes)),
                ]),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfStatBox(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
      ],
    );
  }

  pw.Widget _pdfCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 11, fontWeight: bold ? pw.FontWeight.bold : null)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reports',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 46,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generate storage usage reports.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFFACABAA)),
                  ),
                  const SizedBox(height: 24),
                  _buildRangeChips(),
                  const SizedBox(height: 24),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRangeChips() {
    return Row(
      children: [
        _buildChip('7 Days', _ReportRange.week),
        const SizedBox(width: 8),
        _buildChip('1 Month', _ReportRange.month),
        const SizedBox(width: 8),
        _buildChip('3 Months', _ReportRange.threeMonths),
      ],
    );
  }

  Widget _buildChip(String label, _ReportRange range) {
    final selected = _selectedRange == range;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _selectedRange = range);
        _loadReport();
      },
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF003D8A) : const Color(0xFFACABAA),
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
      selectedColor: const Color(0xFFAEC6FF),
      backgroundColor: const Color(0xFF1F2020),
      side: BorderSide(color: const Color(0xFF484848).withValues(alpha: 0.25)),
      showCheckmark: false,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFAEC6FF)));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Color(0xFFFF9993), fontFamily: 'Inter')),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadReport, child: const Text('Retry', style: TextStyle(color: Color(0xFFAEC6FF)))),
          ],
        ),
      );
    }

    final data = _reportData;
    if (data == null || data.totalFiles == 0) {
      return const Center(
        child: Text('No files found in this period.', style: TextStyle(fontFamily: 'Inter', color: Color(0xFFACABAA))),
      );
    }

    final sortedCategories = data.byCategory.entries.toList()
      ..sort((a, b) => b.value.totalBytes.compareTo(a.value.totalBytes));

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Summary cards
        Row(
          children: [
            _buildMetricCard('Total Files', '${data.totalFiles}', Icons.folder_outlined),
            const SizedBox(width: 12),
            _buildMetricCard('Storage Used', ExplorerByteFormat.humanReadable(data.totalBytes), Icons.storage_outlined),
            const SizedBox(width: 12),
            _buildMetricCard('File Types', '${data.byCategory.length}', Icons.category_outlined),
          ],
        ),
        const SizedBox(height: 32),

        // Generate PDF button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _generating ? null : _generatePdf,
            icon: _generating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF003D8A)))
                : const Icon(Icons.picture_as_pdf),
            label: Text(_generating ? 'Generating...' : 'Generate PDF Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFAEC6FF),
              foregroundColor: const Color(0xFF003D8A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // File type distribution
        const Text('Storage by File Type', style: TextStyle(fontFamily: 'Manrope', fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF131313),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              for (int i = 0; i < sortedCategories.length; i++) ...[
                _buildCategoryRow(sortedCategories[i], data.totalBytes),
                if (i < sortedCategories.length - 1)
                  Divider(color: const Color(0xFF484848).withValues(alpha: 0.15), height: 1, indent: 16, endIndent: 16),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Largest files
        Text('Top ${data.largestFiles.length} Largest Files', style: const TextStyle(fontFamily: 'Manrope', fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF131313),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              for (int i = 0; i < data.largestFiles.length; i++) ...[
                _buildLargestFileTile(i + 1, data.largestFiles[i]),
                if (i < data.largestFiles.length - 1)
                  Divider(color: const Color(0xFF484848).withValues(alpha: 0.15), height: 1, indent: 16, endIndent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF131313),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFAEC6FF), size: 20),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontFamily: 'Manrope', fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFFACABAA))),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(MapEntry<String, _CategoryStats> entry, int totalBytes) {
    final percentage = totalBytes > 0 ? entry.value.totalBytes / totalBytes : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(entry.key, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14)),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 6,
                    backgroundColor: const Color(0xFF2E3E45),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFAEC6FF)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              ExplorerByteFormat.humanReadable(entry.value.totalBytes),
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFFAEC6FF)),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '${entry.value.fileCount}',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFFACABAA)),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargestFileTile(int rank, _FileRow file) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: const Color(0xFF2E3E45),
        child: Text('$rank', style: const TextStyle(color: Color(0xFFAEC6FF), fontSize: 12, fontWeight: FontWeight.w700)),
      ),
      title: Text(
        file.name,
        style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        ExplorerByteFormat.humanReadable(file.sizeBytes),
        style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFFAEC6FF)),
      ),
    );
  }
}

class _PdfPreviewScreen extends StatefulWidget {
  const _PdfPreviewScreen({required this.pdfBytes, required this.title});

  final Uint8List pdfBytes;
  final String title;

  @override
  State<_PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<_PdfPreviewScreen> {
  List<Uint8List>? _pageImages;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rasterize();
  }

  Future<void> _rasterize() async {
    try {
      final pages = <Uint8List>[];
      await for (final page in Printing.raster(widget.pdfBytes, dpi: 200)) {
        final png = await page.toPng();
        pages.add(png);
      }
      if (!mounted) return;
      setState(() {
        _pageImages = pages;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0E),
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontFamily: 'Manrope')),
        iconTheme: const IconThemeData(color: Color(0xFFAEC6FF)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download / Print',
            onPressed: () => Printing.sharePdf(bytes: widget.pdfBytes, filename: 'filezen_report.pdf'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFAEC6FF)))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Color(0xFFAEC6FF), size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'PDF preview unavailable on this device.',
                          style: TextStyle(color: Colors.white, fontFamily: 'Manrope', fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap the download button above to share or print the report.',
                          style: TextStyle(color: Color(0xFFACABAA), fontFamily: 'Inter', fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Printing.sharePdf(bytes: widget.pdfBytes, filename: 'filezen_report.pdf'),
                          icon: const Icon(Icons.share),
                          label: const Text('Share PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFAEC6FF),
                            foregroundColor: const Color(0xFF003D8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Container(
                  color: Colors.white,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pageImages!.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(_pageImages![index], fit: BoxFit.fitWidth),
                      ),
                    ),
                  ),
                ),
    );
  }
}
