import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfAssetPath;
  final String title;

  const PdfViewerScreen({super.key, required this.pdfAssetPath, required this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _filePath;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final dir = await getTemporaryDirectory();
      final name = p.basename(widget.pdfAssetPath);
      final dest = p.join(dir.path, name);
      if (!await File(dest).exists()) {
        final data = await rootBundle.load(widget.pdfAssetPath);
        await File(dest).writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      }
      if (mounted) setState(() { _filePath = dest; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Ошибка загрузки PDF: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
              : PDFView(filePath: _filePath!),
    );
  }
}
