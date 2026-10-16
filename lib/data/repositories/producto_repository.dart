import '../models/models.dart';

abstract class ProductoRepository {
  Future<List<ProductoResumen>> getAlertas();
  Future<List<ProductoResumen>> getTodos({int? categoriaId});
}