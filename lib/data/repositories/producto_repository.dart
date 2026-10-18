import '../models/models.dart';

abstract class ProductoRepository {
  Future<List<ProductoResumen>> getAlertas();
  Future<List<ProductoResumen>> getTodos({int? categoriaId});
  Future<ProductoResumen?> getById(int id);
  Future<int> insertar(Producto p);
  Future<void> actualizar(Producto p);
  Future<void> eliminar(int id);

  /// FEFO: descuenta primero del lote que caduca antes.
  /// Lanza AppException si no alcanza el stock.
  Future<void> consumirStock(int productoId, int cantidad);
}