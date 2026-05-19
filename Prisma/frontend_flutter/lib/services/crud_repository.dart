import 'api_service.dart';

class CrudRepository {
  final String endpoint;
  
  CrudRepository(this.endpoint);

  Future<List<dynamic>> getAll() async {
    final response = await ApiService.get(endpoint);
    return response is List ? response : [];
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    return await ApiService.post(endpoint, data);
  }

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> data) async {
    return await ApiService.put('$endpoint/$id', data);
  }

  Future<void> delete(String id) async {
    await ApiService.delete('$endpoint/$id');
  }
}
