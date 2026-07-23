import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/vehicle.dart';
import '../models/category.dart';
import '../models/document.dart';
import '../models/dtc_code.dart';
import 'database_interface.dart';

class DatabaseService implements DatabaseInterface {
  static DatabaseInterface? _override;
  static void setInstance(DatabaseInterface mock) => _override = mock;

  static DatabaseInterface get it => _override ?? _instance;
  static final DatabaseService _instance = DatabaseService._();
  DatabaseService._();

  static const _dbName = 'jmq_service_manual_v4.db';
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, _dbName);
    final exists = await databaseExists(dbPath);
    if (!exists) {
      final blob = await rootBundle.load('assets/db/$_dbName');
      final buffer = blob.buffer;
      await dir.create(recursive: true);
      await File(dbPath).writeAsBytes(buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes));
    }
    return openDatabase(dbPath, readOnly: true);
  }

  Future<List<Vehicle>> getVehicles() async {
    final db = await database;
    final rows = await db.query('vehicles', orderBy: 'code');
    return rows.map((r) => Vehicle.fromMap(r)).toList();
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'sort_order, id');
    return rows.map((r) => Category.fromMap(r)).toList();
  }

  Future<List<Document>> getDocuments({int? categoryId}) async {
    final db = await database;
    final where = categoryId != null ? 'category_id = ?' : null;
    final args = categoryId != null ? [categoryId] : null;
    final rows = await db.query('documents', where: where, whereArgs: args, orderBy: 'id');
    return rows.map((r) => Document.fromMap(r)).toList();
  }

  @override
  Future<int> getDtcCount() async {
    final db = await database;
    final r = await db.rawQuery('SELECT COUNT(*) as c FROM dtc_codes');
    return r.first['c'] as int;
  }

  @override
  Future<DtcCode?> findDtc(String code, {String? model}) async {
    final db = await database;
    var where = 'code = ?';
    var args = <String>[code.toUpperCase()];
    if (model != null) {
      where += ' AND vehicle_model = ?';
      args.add(model);
    }
    final rows = await db.query('dtc_codes', where: where, whereArgs: args, limit: 1);
    if (rows.isEmpty) return null;
    return DtcCode.fromMap(rows.first);
  }

  Future<List<DtcCode>> searchDtc(String query, {String? model, int limit = 50}) async {
    final db = await database;
    final isCode = RegExp(r'^(0x[0-9A-Fa-f]+|[PBCU]\d{2,})$').hasMatch(query.toUpperCase());

    if (isCode) {
      var where = 'code = ?';
      var args = <String>[query.toUpperCase()];
      if (model != null) { where += ' AND vehicle_model = ?'; args.add(model); }
      final exact = await db.query('dtc_codes', where: where, whereArgs: args, limit: limit);
      if (exact.isNotEmpty) return exact.map((r) => DtcCode.fromMap(r)).toList();
    }

    var where = 'code LIKE ? OR meaning_en LIKE ? OR meaning_ru LIKE ?';
    var args = <String>['%$query%', '%$query%', '%$query%'];
    if (model != null) { where += ' AND vehicle_model = ?'; args.add(model); }

    final rows = await db.query('dtc_codes', where: where, whereArgs: args,
        limit: limit, orderBy: 'length(code) ASC');
    return rows.map((r) => DtcCode.fromMap(r)).toList();
  }

  Future<List<DtcCode>> searchDtcFts(String query, {String? model, int limit = 50}) async {
    final db = await database;
    try {
      var sql = '''
        SELECT d.* FROM dtc_fts f
        JOIN dtc_codes d ON d.id = f.rowid
        WHERE dtc_fts MATCH ?
      ''';
      var args = [query.trim().replaceAll(' ', ' OR ')];
      if (model != null) {
        sql += ' AND d.vehicle_model = ?';
        args.add(model);
      }
      sql += ' ORDER BY rank LIMIT ?';
      args.add(limit.toString());
      final rows = await db.rawQuery(sql, args);
      return rows.map((r) => DtcCode.fromMap(r)).toList();
    } catch (e) {
      debugPrint('FTS5 search failed (not supported on this device): $e');
      return searchDtc(query, model: model, limit: limit);
    }
  }

  Future<List<DtcCode>> findDtcByPartialCode(String partial, {String? model, int limit = 20}) async {
    final db = await database;
    var where = 'code LIKE ?';
    var args = <String>['$partial%'];
    if (model != null) { where += ' AND vehicle_model = ?'; args.add(model); }
    final rows = await db.query('dtc_codes', where: where, whereArgs: args,
        limit: limit, orderBy: 'length(code) ASC');
    return rows.map((r) => DtcCode.fromMap(r)).toList();
  }

  Future<List<Document>> searchDocuments(String query) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT d.* FROM documents_fts f
      JOIN documents d ON d.id = f.rowid
      WHERE documents_fts MATCH ?
      ORDER BY rank
      LIMIT 20
    ''', [query]);
    return rows.map((r) => Document.fromMap(r)).toList();
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT 'vehicles' as k, COUNT(*) as v FROM vehicles
      UNION ALL SELECT 'categories', COUNT(*) FROM categories
      UNION ALL SELECT 'documents', COUNT(*) FROM documents
      UNION ALL SELECT 'dtc', COUNT(*) FROM dtc_codes
    ''');
    final m = <String, dynamic>{};
    for (var r in rows) { m[r['k'] as String] = r['v']; }
    return m;
  }

  @override
  Future<int> getDatabaseSize() async {
    final db = await database;
    final path = db.path;
    final file = File(path);
    if (await file.exists()) return await file.length();
    return 0;
  }

  @override
  Future<Map<int, int>> getDocumentCountPerCategory() async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT category_id, COUNT(*) as cnt FROM documents GROUP BY category_id');
    final map = <int, int>{};
    for (var r in rows) {
      map[r['category_id'] as int] = r['cnt'] as int;
    }
    return map;
  }

  Future<List<String>> getModelsForCode(String code) async {
    final db = await database;
    final rows = await db.query('dtc_codes',
        columns: ['vehicle_model'], where: 'code = ?', whereArgs: [code.toUpperCase()],
        groupBy: 'vehicle_model', orderBy: 'vehicle_model');
    return rows.map((r) => r['vehicle_model'] as String).toList();
  }

  @override
  Future<Set<int>> getDocIdsForModel(String model) async {
    final db = await database;
    final rows = await db.query('document_models',
        columns: ['document_id'], where: 'vehicle_model = ?', whereArgs: [model]);
    return rows.map((r) => r['document_id'] as int).toSet();
  }

  @override
  Future<Map<String, dynamic>?> getDocumentById(int id) async {
    final db = await database;
    final rows = await db.query('documents', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }
}
