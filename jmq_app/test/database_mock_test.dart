import 'package:flutter_test/flutter_test.dart';
import 'package:jmq_app/models/category.dart';
import 'package:jmq_app/models/document.dart';
import 'package:jmq_app/models/dtc_code.dart';
import 'package:jmq_app/models/vehicle.dart';
import 'package:jmq_app/services/database_interface.dart';
import 'package:jmq_app/services/database_service.dart';

class MockDatabase implements DatabaseInterface {
  @override
  Future<List<Vehicle>> getVehicles() async => [
    Vehicle(id: 1, code: 'J7'),
    Vehicle(id: 2, code: 'S3'),
  ];

  @override Future<List<Category>> getCategories() async => [];
  @override Future<List<Document>> getDocuments({int? categoryId}) async => [];
  @override Future<int> getDtcCount() async => 9505;
  @override Future<DtcCode?> findDtc(String code, {String? model}) async => null;
  @override Future<List<DtcCode>> searchDtc(String query, {String? model, int limit = 50}) async => [];
  @override Future<List<DtcCode>> searchDtcFts(String query, {String? model, int limit = 50}) async => [];
  @override Future<List<DtcCode>> findDtcByPartialCode(String partial, {String? model, int limit = 20}) async => [];
  @override Future<List<Document>> searchDocuments(String query) async => [];
  @override Future<Map<String, dynamic>> getStats() async => {'vehicles': 2, 'categories': 3, 'documents': 5, 'dtc': 9505};
  @override Future<int> getDatabaseSize() async => 8000000;
  @override Future<Map<int, int>> getDocumentCountPerCategory() async => {};
  @override Future<List<String>> getModelsForCode(String code) async => [];
  @override Future<Set<int>> getDocIdsForModel(String model) async => {1, 2, 3};
  @override Future<Set<int>> getCategoryIdsForModel(String model) async => {};
  @override Future<List<Map<String, dynamic>>> getDtcDocumentLinks(String code, {String? model}) async => [];
  @override Future<Map<String, dynamic>?> getDocumentById(int id) async => null;
}

void main() {
  setUp(() {
    DatabaseService.setInstance(MockDatabase());
  });

  test('Mock returns correct vehicles', () async {
    final vs = await DatabaseService.it.getVehicles();
    expect(vs.length, 2);
    expect(vs[0].code, 'J7');
  });

  test('Mock returns correct stats', () async {
    final stats = await DatabaseService.it.getStats();
    expect(stats['dtc'], 9505);
  });
}
