import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/category.dart';
import '../models/document.dart';
import '../models/vehicle.dart';
import '../services/database_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Vehicle> _vehicles = [];
  String? _selectedModel;
  bool? _hasDocs;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    _checkModel(null);
  }

  void _loadVehicles() async {
    final v = await DatabaseService.getVehicles();
    if (mounted) setState(() => _vehicles = v);
  }

  void _checkModel(String? model) async {
    setState(() { _selectedModel = model; _hasDocs = null; });
    if (model == null) {
      if (mounted) setState(() => _hasDocs = true);
      return;
    }
    final ids = await DatabaseService.getDocIdsForModel(model);
    if (mounted) setState(() => _hasDocs = ids.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Категории'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedModel,
                hint: const Text('Модель'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Все модели')),
                  ..._vehicles.map((v) => DropdownMenuItem(value: v.code, child: Text(v.code))),
                ],
                onChanged: (v) => _checkModel(v),
              ),
            ),
          ),
        ],
      ),
      body: _hasDocs == null
          ? const Center(child: CircularProgressIndicator())
          : !_hasDocs!
              ? const Center(child: Text('Нет документов для этой модели'))
              : _CategoryList(),
    );
  }
}

class _CategoryList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Category>>(
      future: DatabaseService.getCategories(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final cats = snap.data!;
        final roots = cats.where((c) => c.isRoot).toList();
        return ListView.builder(
          itemCount: roots.length,
          itemBuilder: (_, i) {
            final parent = roots[i];
            final children = cats.where((c) => c.parentId == parent.id).toList();
            return _CategoryTile(parent: parent, children: children);
          },
        );
      },
    );
  }
}

class _CategoryTile extends StatefulWidget {
  final Category parent;
  final List<Category> children;
  const _CategoryTile({required this.parent, required this.children});

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  List<Document>? _docs;
  Map<int, int>? _docCounts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final docs = await DatabaseService.getDocuments(categoryId: widget.parent.id);
    final counts = await DatabaseService.getDocumentCountPerCategory();
    if (mounted) setState(() { _docs = docs; _docCounts = counts; });
  }

  int _totalDocs() {
    var total = _docCounts?[widget.parent.id] ?? 0;
    for (final c in widget.children) {
      total += _docCounts?[c.id] ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final docs = _docs ?? <Document>[];
    final children = widget.children;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(child: Text(widget.parent.nameRu[0])),
        title: Text(widget.parent.nameRu, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${children.length} подкатегорий · ${_totalDocs()} файлов'),
        children: [
          if (children.isNotEmpty)
            ...children.map((c) => ListTile(
              title: Text(c.nameRu),
              subtitle: Text(c.nameEn),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/documents/${c.id}', extra: c),
            )),
          if (docs.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (children.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 8),
                    child: Text('Документы:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ...docs.map((d) {
                  return ListTile(
                    leading: CircleAvatar(child: const Icon(Icons.picture_as_pdf, size: 18)),
                    title: Text(d.titleRu ?? d.titleEn ?? '', style: const TextStyle(fontSize: 13)),
                    dense: true,
                    trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
                    onTap: () => context.push('/pdf', extra: {'path': d.pdfAssetPath, 'title': d.titleRu ?? d.titleEn ?? ''}),
                  );
                }),
              ],
            ),
          if (children.isEmpty && docs.isEmpty)
             const Padding(padding: EdgeInsets.all(16), child: Text('Нет документов')),
        ],
      ),
    );
  }
}


