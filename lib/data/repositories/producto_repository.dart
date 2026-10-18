import '../models/models.dart';

abstract class ProductoRepository {
  Future<List<ProductoResumen>> getAlertas();
  Future<List<ProductoResumen>> getTodos({int? categoriaId});
  Future<ProductoResumen?> getById(int id);
  Future<int> insertar(Producto p);
  Future<void> actualizar(Producto p);
  Future<void> eliminar(int id);
}