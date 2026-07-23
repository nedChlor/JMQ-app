import 'dart:async';
import 'package:flutter/material.dart';
import '../models/dtc_code.dart';
import '../models/vehicle.dart';
import '../services/database_service.dart';

class DTCDetailScreen extends StatefulWidget {
  final String? code;
  const DTCDetailScreen({super.key, this.code});

  @override
  State<DTCDetailScreen> createState() => _DTCDetailScreenState();
}

class _DTCDetailScreenState extends State<DTCDetailScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  List<Vehicle> _vehicles = [];
  String? _selectedModel;

  DtcCode? _detailItem;
  List<DtcCode> _results = [];
  List<DtcCode> _suggestions = [];
  bool _searching = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    _controller.addListener(_onTextChanged);
    if (widget.code != null) {
      _controller.text = widget.code!;
      _doSearch();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _loadVehicles() async {
    final v = await DatabaseService.it.getVehicles();
    if (mounted) setState(() => _vehicles = v);
  }

  void _onTextChanged() {
    _debounce?.cancel();
    final q = _controller.text.trim();
    if (q.length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final partial = q.toUpperCase();
      final isCode = RegExp(r'^[PBCU0-9Xx]+$').hasMatch(partial);
      List<DtcCode> list;
      if (isCode) {
        list = await DatabaseService.it.findDtcByPartialCode(partial, model: _selectedModel);
      } else {
        list = await DatabaseService.it.searchDtcFts(partial, model: _selectedModel, limit: 8);
      }
      if (mounted) setState(() => _suggestions = list);
    });
  }

  Future<void> _doSearch() async {
    final q = _controller.text.trim();
    if (q.isEmpty) {
      setState(() { _results = []; _detailItem = null; _error = null; });
      return;
    }
    setState(() { _searching = true; _detailItem = null; _results = []; _suggestions = []; _error = null; });

    try {
      final list = await DatabaseService.it.searchDtc(q, model: _selectedModel);
      if (!mounted) return;
      if (list.length == 1) {
        setState(() { _detailItem = list.first; _searching = false; });
      } else if (list.isEmpty) {
        setState(() { _error = 'Код не найден'; _searching = false; });
      } else {
        setState(() { _results = list; _searching = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Ошибка: $e'; _searching = false; });
    }
  }

  void _onModelChanged(String? m) {
    setState(() => _selectedModel = m);
    final q = _controller.text.trim();
    if (q.isNotEmpty) _doSearch();
  }

  void _openDetail(DtcCode dtc) {
    setState(() { _detailItem = dtc; _suggestions = []; });
  }

  void _backToResults() {
    setState(() => _detailItem = null);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск по DTC'),
        leading: _detailItem != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _backToResults)
            : null,
      ),
      body: Column(
        children: [
          _buildSearchBar(t),
          _buildModelBar(t),
          Expanded(child: _buildBody(t)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      color: t.colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Введите код (P0765) или описание...',
                prefixIcon: const Icon(Icons.search, size: 28),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() { _results = []; _detailItem = null; _error = null; _suggestions = []; });
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: t.colorScheme.outline)),
                filled: true,
                fillColor: t.colorScheme.surfaceContainerHighest.withAlpha(80),
              ),
              onSubmitted: (_) {
                _debounce?.cancel();
                _doSearch();
              },
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _searching ? null : _doSearch,
            icon: _searching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.search),
            label: const Text('Найти', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildModelBar(ThemeData t) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.directions_car_outlined, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.public, size: 18),
            label: const Text('Все модели', style: TextStyle(fontWeight: FontWeight.w500)),
            backgroundColor: _selectedModel == null ? t.colorScheme.primaryContainer : null,
            side: _selectedModel == null ? BorderSide(color: t.colorScheme.primary) : null,
            onPressed: () => _onModelChanged(null),
          ),
          const SizedBox(width: 4),
          ..._vehicles.map((v) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ActionChip(
              label: Text(v.code, style: const TextStyle(fontWeight: FontWeight.w500)),
              backgroundColor: _selectedModel == v.code ? t.colorScheme.primaryContainer : null,
              side: _selectedModel == v.code ? BorderSide(color: t.colorScheme.primary) : null,
              onPressed: () => _onModelChanged(v.code),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData t) {
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 72, color: Colors.orange),
            const SizedBox(height: 16),
            Text(_error!, style: t.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Проверьте правильность кода или попробуйте поиск по тексту', style: t.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          ],
        ),
      );
    }
    if (_detailItem != null) {
      return _DtCDetailWidget(dtc: _detailItem!, model: _selectedModel);
    }
    if (_suggestions.isNotEmpty && _results.isEmpty) {
      return _buildSuggestions(t);
    }
    if (_results.isNotEmpty) {
      return _buildResults(t);
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.build_circle_outlined, size: 80, color: t.colorScheme.primary.withAlpha(100)),
          const SizedBox(height: 16),
          Text('Поиск DTC-кодов', style: t.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Введите код неисправности в поле выше', style: t.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 24),
          Text('Примеры: ${_codeExamples()}', style: t.textTheme.bodySmall?.copyWith(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  String _codeExamples() {
    if (_selectedModel == 'J7') return 'B100117, C121208, U010087';
    final examples = <String>['P0268', 'B1013', 'U0100', 'C1101'];
    return examples.join(', ');
  }

  Widget _buildSuggestions(ThemeData t) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 8, bottom: 4),
          child: Text('Подсказки', style: t.textTheme.labelMedium?.copyWith(color: Colors.grey)),
        ),
        ..._suggestions.map((d) => _ResultCard(dtc: d, model: _selectedModel, onTap: () => _openDetail(d))),
      ],
    );
  }

  Widget _buildResults(ThemeData t) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 8, bottom: 4),
          child: Text('${_results.length} ${_plural(_results.length, 'результат', 'результата', 'результатов')}',
              style: t.textTheme.labelMedium?.copyWith(color: Colors.grey)),
        ),
        ..._results.map((d) => _ResultCard(dtc: d, model: _selectedModel, onTap: () => _openDetail(d))),
      ],
    );
  }

  String _plural(int n, String one, String two, String five) {
    final m = n % 10; final h = n % 100;
    if (h >= 11 && h <= 19) return five;
    if (m == 1) return one;
    if (m >= 2 && m <= 4) return two;
    return five;
  }
}

class _ResultCard extends StatelessWidget {
  final DtcCode dtc;
  final String? model;
  final VoidCallback onTap;
  const _ResultCard({required this.dtc, required this.model, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(dtc.code, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        const SizedBox(width: 10),
                        Chip(label: Text(dtc.ecu, style: const TextStyle(fontSize: 11)), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _typeColor(dtc.dtcType).withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(dtc.dtcType, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _typeColor(dtc.dtcType))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dtc.meaningRu.isNotEmpty ? dtc.meaningRu : dtc.meaningEn,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (model == null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(dtc.vehicleModel, style: t.textTheme.bodySmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.w600)),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Color _typeColor(String t) {
    switch (t) { case 'P': return Colors.blue; case 'B': return Colors.orange; case 'C': return Colors.teal; case 'U': return Colors.purple; case 'H': return Colors.brown; default: return Colors.grey; }
  }
}

class _DtCDetailWidget extends StatefulWidget {
  final DtcCode dtc;
  final String? model;
  const _DtCDetailWidget({required this.dtc, required this.model});

  @override
  State<_DtCDetailWidget> createState() => _DtCDetailWidgetState();
}

class _DtCDetailWidgetState extends State<_DtCDetailWidget> {
  List<String>? _allModels;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  void _loadModels() async {
    final models = widget.model == null ? await DatabaseService.it.getModelsForCode(widget.dtc.code) : null;
    if (mounted) setState(() => _allModels = models);
  }

  Widget _buildModelLabel(ThemeData t) {
    if (widget.model != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_car, size: 16),
          const SizedBox(width: 6),
          Text(widget.model!, style: t.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
        ],
      );
    }
    if (_allModels == null) {
      return const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.directions_car, size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text('Модели: ${_allModels!.join(', ')}',
              style: t.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final dtc = widget.dtc;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: t.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(dtc.code, style: t.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 2)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Chip(label: Text(dtc.ecu, style: const TextStyle(fontWeight: FontWeight.w600)), avatar: const Icon(Icons.memory, size: 16)),
                        const SizedBox(height: 4),
                        Chip(label: Text(dtc.dtcType, style: const TextStyle(fontWeight: FontWeight.w600)), avatar: const Icon(Icons.tag, size: 16)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildModelLabel(t),
                ),
                if (dtc.meaningRu.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(width: 4, height: 20, decoration: BoxDecoration(color: t.colorScheme.primary, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 8),
                      Text('Описание', style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(dtc.meaningRu, style: t.textTheme.bodyLarge?.copyWith(height: 1.5)),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(width: 4, height: 20, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Text('EN', style: t.textTheme.titleSmall?.copyWith(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(dtc.meaningEn, style: t.textTheme.bodyMedium?.copyWith(height: 1.4, color: Colors.grey.shade700)),
              ],
            ),
          ),
        ),
        if (dtc.meaningRu.isEmpty)
          Card(
            color: Colors.orange.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.translate, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(child: Text('Русский перевод уточняется', style: TextStyle(color: Colors.orange))),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
