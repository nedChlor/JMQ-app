import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/category.dart';
import '../models/document.dart';
import '../services/database_service.dart';

class DocumentListScreen extends StatefulWidget {
  final Category category;
  const DocumentListScreen({super.key, required this.category});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  List<Document>? _docs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final list = await DatabaseService.getDocuments(categoryId: widget.category.id);
    if (mounted) setState(() => _docs = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.nameRu)),
      body: _docs == null
          ? const Center(child: CircularProgressIndicator())
          : _docs!.isEmpty
              ? const Center(child: Text('Нет документов в этой категории'))
              : ListView.builder(
                  itemCount: _docs!.length,
                  itemBuilder: (_, i) {
                    final doc = _docs![i];
                    final sizeStr = doc.fileSize > 1024 * 1024
                        ? '${(doc.fileSize / 1024 / 1024).toStringAsFixed(1)} MB'
                        : '${(doc.fileSize / 1024).toStringAsFixed(0)} KB';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(child: const Icon(Icons.picture_as_pdf)),
                        title: Text(doc.titleRu ?? doc.titleEn ?? doc.originalFilename ?? ''),
                        subtitle: Text('PDF · ${(doc.textLength / 1000).toStringAsFixed(0)}k chars · $sizeStr'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/pdf', extra: {
                          'path': doc.pdfAssetPath,
                          'title': doc.titleRu ?? doc.titleEn ?? '',
                        }),
                      ),
                    );
                  },
                ),
    );
  }
}
