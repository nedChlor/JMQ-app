import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _stats;
  double? _dbSize;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final s = await DatabaseService.it.getStats();
    final d = await DatabaseService.it.getDatabaseSize();
    if (mounted) setState(() { _stats = s; _dbSize = d / 1024 / 1024; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JMQ Service Manual'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Поиск по документам...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) context.push('/search', extra: v);
              },
            ),
            const SizedBox(height: 20),
            if (_stats != null)
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  Chip(label: Text('Модели: ${_stats!['vehicles']}')),
                  Chip(label: Text('Категории: ${_stats!['categories']}')),
                  Chip(label: Text('Документы: ${_stats!['documents']}')),
                  Chip(label: Text('DTC: ${_stats!['dtc']}')),
                ],
              ),
            if (_dbSize != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Размер БД: ${_dbSize!.toStringAsFixed(1)} MB', style: Theme.of(context).textTheme.bodySmall),
              ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: CircleAvatar(child: const Icon(Icons.search)),
                title: const Text('Поиск по коду ошибки', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Расшифровка DTC-кода'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/dtc'),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: CircleAvatar(child: const Icon(Icons.folder_open)),
                title: const Text('Категории документации', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Навигация по документам'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/categories'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
