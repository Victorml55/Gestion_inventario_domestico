import '../models/models.dart';

abstract class LoteRepository {
  Future<List<Lote>> getPorProducto(int productoId);
  Future<int> insertar(Lote l);
  Future<void> actualizar(Lote l);
  Future<void> eliminar(int id);
}