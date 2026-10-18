import '../models/producto.dart';
import '../models/producto_resumen.dart';

abstract class ProductoRepository {
  Future<List<ProductoResumen>> getAlertas();
  Future<List<ProductoResumen>> getTodos({int? categoriaId});
  Future<ProductoResumen?> getById(int id);
  Future<int> insertar(Producto p);
  Future<void> actualizar(Producto p);
  Future<void> eliminar(int id);
  Future<void> consumirStock(int productoId, int cantidad); // FEFO
}