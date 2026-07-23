import '../models/category.dart';
import '../models/document.dart';
import '../models/dtc_code.dart';
import '../models/vehicle.dart';

abstract class DatabaseInterface {
  Future<List<Vehicle>> getVehicles();
  Future<List<Category>> getCategories();
  Future<List<Document>> getDocuments({int? categoryId});
  Future<int> getDtcCount();
  Future<DtcCode?> findDtc(String code, {String? model});
  Future<List<DtcCode>> searchDtc(String query, {String? model, int limit});
  Future<List<DtcCode>> searchDtcFts(String query, {String? model, int limit});
  Future<List<DtcCode>> findDtcByPartialCode(String partial, {String? model, int limit});
  Future<List<Document>> searchDocuments(String query);
  Future<Map<String, dynamic>> getStats();
  Future<int> getDatabaseSize();
  Future<Map<int, int>> getDocumentCountPerCategory();
  Future<List<String>> getModelsForCode(String code);
  Future<Set<int>> getDocIdsForModel(String model);
  Future<Set<int>> getCategoryIdsForModel(String model);
  Future<List<Map<String, dynamic>>> getDtcDocumentLinks(String code, {String? model});
  Future<Map<String, dynamic>?> getDocumentById(int id);
}
