import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/document.dart';
import '../services/database_service.dart';

class FullTextSearchScreen extends StatefulWidget {
  final String? initialQuery;
  const FullTextSearchScreen({super.key, this.initialQuery});

  @override
  State<FullTextSearchScreen> createState() => _FullTextSearchScreenState();
}

class _FullTextSearchScreenState extends State<FullTextSearchScreen> {
  final _controller = TextEditingController();
  List<Document> _results = [];
  bool _loading = false;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _controller.text = widget.initialQuery!;
      _search();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() { _loading = true; _searched = true; _results = []; });
    final list = await DatabaseService.searchDocuments(q);
    if (mounted) setState(() { _results = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Полнотекстовый поиск')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Введите текст для поиска...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _search, child: const Text('Найти')),
              ],
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_results.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _results.length,
                itemBuilder: (_, i) {
                  final d = _results[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: CircleAvatar(child: const Icon(Icons.picture_as_pdf)),
                      title: Text(d.titleRu ?? d.titleEn ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${(d.textLength / 1000).toStringAsFixed(0)}k символов'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => context.push('/pdf', extra: {
                        'path': d.pdfAssetPath,
                        'title': d.titleRu ?? d.titleEn ?? '',
                      }),
                    ),
                  );
                },
              ),
            )
          else if (_searched)
            const Expanded(child: Center(child: Text('Ничего не найдено')))
          else
            const Expanded(
              child: Center(child: Text('Введите запрос для поиска по тексту документов')),
            ),
        ],
      ),
    );
  }
}
